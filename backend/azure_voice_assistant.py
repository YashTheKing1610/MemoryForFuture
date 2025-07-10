from fastapi import APIRouter, UploadFile
from fastapi.responses import StreamingResponse
from dotenv import load_dotenv
import openai
import os
import io

load_dotenv()

router = APIRouter(prefix="/voice-assistant", tags=["AI Voice Assistant"])

AZURE_OPENAI_KEY = os.getenv("AZURE_OPENAI_API_KEY")
AZURE_OPENAI_ENDPOINT = os.getenv("AZURE_OPENAI_ENDPOINT")
AZURE_DEPLOYMENT_NAME = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")
AZURE_TTS_KEY = os.getenv("AZURE_TTS_KEY")
AZURE_TTS_REGION = os.getenv("AZURE_TTS_REGION")

openai.api_key = AZURE_OPENAI_KEY
openai.api_base = AZURE_OPENAI_ENDPOINT
openai.api_version = "2024-05-01-preview"
openai.api_type = "azure"

@router.post("/chat-voice")
async def chat_with_voice(input: dict):
    try:
        message = input.get("message")
        if not message:
            return {"error": "No message received"}

        # Get AI response from Azure OpenAI
        completion = openai.ChatCompletion.create(
            engine=AZURE_DEPLOYMENT_NAME,
            messages=[{"role": "system", "content": "You are a helpful voice assistant."},
                      {"role": "user", "content": message}]
        )
        ai_response = completion["choices"][0]["message"]["content"]

        # Convert to speech (TTS)
        from azure.cognitiveservices.speech import SpeechConfig, SpeechSynthesizer  # removed AudioOutputConfig
        

        speech_config = SpeechConfig(subscription=AZURE_TTS_KEY, region=AZURE_TTS_REGION)
        speech_synthesizer = SpeechSynthesizer(speech_config=speech_config, audio_config=None)

        result = speech_synthesizer.speak_text_async(ai_response).get()
        stream = io.BytesIO(result.audio_data)

        return StreamingResponse(stream, media_type="audio/wav", headers={"X-Text-Response": ai_response})

    except Exception as e:
        return {"error": str(e)}
