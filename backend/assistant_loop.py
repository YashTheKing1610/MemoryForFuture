from backend.utils.speech.azure_stt import recognize_speech
from backend.utils.speech.azure_tts import speak_text
from backend.azure_openai import get_ai_response

def start_voice_loop(profile_id: str = "yash_me"):
    print(f"🎤 Starting AI Voice Assistant for Profile: {profile_id}")
    while True:
        user_input = recognize_speech()  # STT
        if not user_input:
            print("Speech not recognized. Try again...")
            continue

        print(f"👤 You: {user_input}")

        ai_response = get_ai_response(user_input, profile_id=profile_id)  # GPT
        print(f"🤖 AI: {ai_response}")

        speak_text(ai_response)  # TTS
