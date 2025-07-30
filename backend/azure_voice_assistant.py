import azure.cognitiveservices.speech as speechsdk
import azure.cognitiveservices.speech.audio as speechsdk_audio
import requests
import json
import tempfile
import os
import time
import threading
from queue import Queue, Empty
import logging
from dotenv import load_dotenv

try:
    import simpleaudio as sa  # Audio playback
except ImportError:
    print("Please install simpleaudio via: pip install simpleaudio")
    exit(1)

logging.basicConfig(level=logging.INFO)

load_dotenv()

AZURE_SPEECH_KEY = os.getenv("AZURE_SPEECH_KEY")
AZURE_SPEECH_REGION = os.getenv("AZURE_SPEECH_REGION")
AZURE_OPENAI_KEY = os.getenv("AZURE_OPENAI_KEY")
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT")
AZURE_OPENAI_DEPLOYMENT = os.getenv("AZURE_OPENAI_DEPLOYMENT")
AZURE_OPENAI_VERSION = os.getenv("AZURE_OPENAI_VERSION")

speech_config = speechsdk.SpeechConfig(subscription=AZURE_SPEECH_KEY, region=AZURE_SPEECH_REGION)
speech_config.speech_recognition_language = "en-IN"
speech_config.speech_synthesis_voice_name = "en-IN-PrabhatNeural"

STOP_PHRASES = ["we can stop now", "stop", "exit", "quit"]
NEGATIVE_PHRASES = ["no", "nope", "nothing", "that's all", "nah"]

recognized_queue = Queue()
PROFILE_ID = "yash_me"  # Change as needed or make dynamic


def fetch_memories(profile_id: str) -> str:
    """Fetch and summarize user memories from backend."""
    try:
        api_url = f"http://127.0.0.1:8000/get-memories/{profile_id}"
        response = requests.get(api_url, timeout=3)
        response.raise_for_status()
        memories = response.json()
        summary = "\n".join(
            f"- {m.get('title', 'No Title')}: {m.get('description', '')}" for m in memories
        )
        logging.info(f"Fetched {len(memories)} memories for user '{profile_id}'.")
        return summary or "[No memories available]"
    except Exception as e:
        logging.error(f"Failed to fetch memories: {e}")
        return "[No memories found]"


def recognize_continuous():
    """Run continuous speech recognition and push recognized texts to queue."""
    while True:
        try:
            audio_config = speechsdk_audio.AudioConfig(use_default_microphone=True)
            recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)

            def on_recognized(evt):
                text = evt.result.text.strip()
                if text:
                    logging.info(f"Recognized: '{text}'")
                    recognized_queue.put(text)

            def on_session_stopped(evt):
                logging.warning("Recognition session stopped, restarting...")
                try:
                    recognizer.start_continuous_recognition()
                except Exception as e:
                    logging.error(f"Failed to restart recognition: {e}")

            def on_canceled(evt):
                logging.warning(f"Recognition canceled: {evt}")
                if evt.reason == speechsdk.CancellationReason.Error:
                    logging.warning("Recognition error, attempting restart...")
                    try:
                        recognizer.start_continuous_recognition()
                    except Exception as e:
                        logging.error(f"Failed to restart after cancellation: {e}")

            recognizer.recognized.connect(on_recognized)
            recognizer.session_stopped.connect(on_session_stopped)
            recognizer.canceled.connect(on_canceled)

            recognizer.start_continuous_recognition()
            logging.info("Speech recognition started. Speak now.")
            while True:
                time.sleep(0.1)

        except Exception as e:
            logging.error(f"Recognizer thread error: {e}")
            time.sleep(1)


def get_ai_response(user_input: str, profile_id: str) -> str:
    """Send user input and user memories to Azure OpenAI, get AI reply."""
    memories_text = fetch_memories(profile_id)
    system_prompt = (
        "You are a helpful assistant for the user. "
        "Use the following memories to personalize responses:\n"
        f"{memories_text}\n"
        "After your answer, always ask if the user has any further questions."
    )
    url = AZURE_OPENAI_ENDPOINT.rstrip("/") + f"/openai/deployments/{AZURE_OPENAI_DEPLOYMENT}/chat/completions?api-version={AZURE_OPENAI_VERSION}"
    headers = {
        "Content-Type": "application/json",
        "api-key": AZURE_OPENAI_KEY
    }
    data = {
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_input}
        ],
        "temperature": 0.7,
        "max_tokens": 500,
        "top_p": 0.9,
        "frequency_penalty": 0,
        "presence_penalty": 0
    }
    try:
        response = requests.post(url, headers=headers, data=json.dumps(data), timeout=30)
        response.raise_for_status()
        ai_reply = response.json()["choices"][0]["message"]["content"].strip()
        logging.info(f"AI reply: {ai_reply}")
        return ai_reply
    except Exception as e:
        logging.error(f"OpenAI API call failed: {e}")
        return "Sorry, I encountered an error while responding."


def play_audio(path: str):
    """Play WAV audio file synchronously using simpleaudio."""
    wave_obj = sa.WaveObject.from_wave_file(path)
    play_obj = wave_obj.play()
    play_obj.wait_done()


def speak_text(text: str):
    """Generate speech audio from text, play it, and clean up."""
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = tmp.name

    audio_config = speechsdk_audio.AudioConfig(filename=wav_path)
    synthesizer = speechsdk.SpeechSynthesizer(speech_config=speech_config, audio_config=audio_config)

    result = synthesizer.speak_text_async(text).get()

    if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
        waited = 0
        max_wait = 3
        while (not os.path.exists(wav_path) or os.path.getsize(wav_path) < 1000) and waited < max_wait:
            time.sleep(0.1)
            waited += 0.1

        if not os.path.exists(wav_path) or os.path.getsize(wav_path) < 1000:
            logging.error(f"Audio file {wav_path} not ready or too small.")
            return

        try:
            play_audio(wav_path)
        except Exception as e:
            logging.error(f"Playback error: {e}")
        finally:
            for _ in range(5):
                try:
                    os.remove(wav_path)
                    break
                except PermissionError:
                    time.sleep(0.5)
    else:
        logging.error(f"Speech synthesis failed: {result.reason}")


def main_conversation_loop(profile_id: str):
    logging.info(f"Starting conversation loop for profile '{profile_id}'")
    waiting_for_followup = False

    while True:
        try:
            user_text = recognized_queue.get(timeout=1)
        except Empty:
            continue

        normalized_text = user_text.strip().lower()
        if not normalized_text:
            continue

        logging.info(f"User said: {normalized_text}")

        if waiting_for_followup:
            if any(neg in normalized_text for neg in NEGATIVE_PHRASES):
                speak_text("Alright! It was great talking with you. Have a nice day.")
                break
            else:
                waiting_for_followup = False  # User wants to continue

        if any(stop in normalized_text for stop in STOP_PHRASES):
            speak_text("Okay, ending our chat now. Goodbye!")
            break

        # Generate AI response including memories
        ai_reply = get_ai_response(user_text, profile_id)

        # Speak AI reply
        speak_text(ai_reply)

        # Ask if user has other questions
        speak_text("Is there anything else you want to ask?")
        waiting_for_followup = True


if __name__ == "__main__":
    # Start recognition in a background thread
    threading.Thread(target=recognize_continuous, daemon=True).start()

    # Run the conversational loop in main thread
    main_conversation_loop(PROFILE_ID)
