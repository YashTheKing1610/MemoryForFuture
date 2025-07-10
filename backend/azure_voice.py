from fastapi import APIRouter, UploadFile, Form, File, HTTPException
from azure.storage.blob import BlobServiceClient, ContentSettings
from dotenv import load_dotenv
from utils.voice_model_manager import get_voice_model_config, save_voice_model_config
from utils.memory_reader import get_latest_memory_summary
import os
import uuid
import openai
import azure.cognitiveservices.speech as speechsdk

# Load environment variables
load_dotenv()

router = APIRouter()

# Azure Blob Storage Setup
connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
container_name = os.getenv("AZURE_CONTAINER_NAME")
container_client = BlobServiceClient.from_connection_string(connection_string).get_container_client(container_name)

# Azure OpenAI Setup
openai.api_type = "azure"
openai.api_key = os.getenv("AZURE_OPENAI_KEY")
openai.api_base = os.getenv("AZURE_OPENAI_ENDPOINT")
openai.api_version = os.getenv("AZURE_OPENAI_VERSION")
deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")


@router.post("/upload-voice")
async def upload_voice(profile_id: str = Form(...), file: UploadFile = File(...)):
    try:
        blob_path = f"{profile_id}/voice_samples/{uuid.uuid4().hex}_{file.filename}"
        content = await file.read()

        container_client.upload_blob(
            name=blob_path,
            data=content,
            overwrite=True,
            content_settings=ContentSettings(content_type=file.content_type)
        )

        return {"message": "Voice file uploaded", "blob_path": blob_path}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/train-voice-model")
async def train_voice_model(profile_id: str = Form(...), voice_id: str = Form(...), language: str = Form("en-IN")):
    try:
        config = {
            "profile_id": profile_id,
            "voice_id": voice_id,
            "language": language
        }
        save_voice_model_config(profile_id, config, container_client)
        return {"message": "Voice model config saved."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/voice-chat")
async def voice_chat(profile_id: str = Form(...), question: str = Form(...)):
    try:
        memory_summary = get_latest_memory_summary(profile_id, container_client)
        voice_config = get_voice_model_config(profile_id, container_client)

        if not voice_config:
            raise HTTPException(status_code=400, detail="No voice model found.")

        prompt = (
            f"You are a voice clone of a loved one, helping reflect on memories.\n"
            f"Memories:\n{memory_summary}\n\n"
            f"Speak with warmth and kindness as the person."
        )

        response = openai.chat.completions.create(
            model=deployment_name,
            messages=[
                {"role": "system", "content": prompt},
                {"role": "user", "content": question}
            ]
        )

        reply = response.choices[0].message.content
        audio_path = f"/tmp/{uuid.uuid4().hex}.mp3"
        generate_audio_from_text(reply, voice_config, audio_path)

        return {"response_text": reply, "audio_path": audio_path}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def generate_audio_from_text(text: str, voice_config: dict, output_path: str):
    speech_config = speechsdk.SpeechConfig(
        subscription=os.getenv("AZURE_SPEECH_KEY"),
        region=os.getenv("AZURE_SPEECH_REGION")
    )
    speech_config.speech_synthesis_voice_name = voice_config["voice_id"]

    audio_config = speechsdk.audio.AudioOutputConfig(filename=output_path)
    synthesizer = speechsdk.SpeechSynthesizer(speech_config, audio_config)
    synthesizer.speak_text_async(text).get()
