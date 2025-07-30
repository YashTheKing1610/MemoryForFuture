import os
from dotenv import load_dotenv
import azure.cognitiveservices.speech as speechsdk

load_dotenv()

# Fetch environment variables once
AZURE_SPEECH_KEY = os.getenv("AZURE_SPEECH_KEY")
AZURE_REGION = os.getenv("AZURE_REGION")

def synthesize_speech(text: str, output_path: str) -> str | None:
    """Synthesizes speech from text to an output audio file.
    
    Returns the audio file path if successful, else None.
    """
    speech_config = speechsdk.SpeechConfig(subscription=AZURE_SPEECH_KEY, region=AZURE_REGION)
    # Optional: set voice name here
    speech_config.speech_synthesis_voice_name = "en-IN-PrabhatNeural"

    audio_config = speechsdk.audio.AudioOutputConfig(filename=output_path)

    synthesizer = speechsdk.SpeechSynthesizer(speech_config=speech_config, audio_config=audio_config)
    result = synthesizer.speak_text_async(text).get()

    if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
        return output_path
    else:
        print(f"Synthesis failed: {result.reason}")
        if result.reason == speechsdk.ResultReason.Canceled:
            cancellation = result.cancellation_details
            print(f"Cancellation reason: {cancellation.reason}")
            if cancellation.reason == speechsdk.CancellationReason.Error:
                print(f"Error details: {cancellation.error_details}")
        return None

def speak_text(text: str) -> None:
    """Synthesizes speech from text and plays on default speaker."""
    speech_config = speechsdk.SpeechConfig(subscription=AZURE_SPEECH_KEY, region=AZURE_REGION)
    speech_config.speech_synthesis_voice_name = "en-IN-PrabhatNeural"

    audio_config = speechsdk.audio.AudioOutputConfig(use_default_speaker=True)

    synthesizer = speechsdk.SpeechSynthesizer(speech_config=speech_config, audio_config=audio_config)
    result = synthesizer.speak_text_async(text).get()

    if result.reason == speechsdk.ResultReason.SynthesizingAudioCompleted:
        print("Speech synthesized ✅")
    elif result.reason == speechsdk.ResultReason.Canceled:
        cancellation = result.cancellation_details
        print(f"Speech synthesis canceled ❌: {cancellation.reason}")
        if cancellation.reason == speechsdk.CancellationReason.Error:
            print(f"Error details: {cancellation.error_details}")
