import os
import io
from dotenv import load_dotenv
from fastapi import APIRouter, File, UploadFile
from fastapi.responses import StreamingResponse
from azure.storage.blob import BlobServiceClient
import azure.cognitiveservices.speech as speechsdk
from openai import AzureOpenAI


load_dotenv()

router = APIRouter()

# Azure Blob Storage setup
blob_service_client = BlobServiceClient.from_connection_string(
    os.getenv("AZURE_STORAGE_CONNECTION_STRING")
)
container_client = blob_service_client.get_container_client(
    os.getenv("AZURE_CONTAINER_NAME")
)

# Azure Speech setup
speech_config = speechsdk.SpeechConfig(
    subscription=os.getenv("AZURE_SPEECH_KEY"),
    region=os.getenv("AZURE_SPEECH_REGION"),
)
speech_config.speech_recognition_language = "en-US"

# Azure OpenAI setup
openai_client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_KEY"),
    api_version=os.getenv("AZURE_OPENAI_VERSION"),
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
)
deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")

def fetch_memories():
    memory_context = ""
    for blob in container_client.list_blobs():
        if blob.name.endswith(('.txt', '.json')):
            stream = container_client.download_blob(blob.name).readall().decode('utf-8')
            memory_context += f"\n\n---\n{blob.name}:\n{stream}"
    return memory_context

def recognize_audio_file(file_path) -> str:
    audio_config = speechsdk.audio.AudioConfig(filename=file_path)
    recognizer = speechsdk.SpeechRecognizer(
        speech_config=speech_config, audio_config=audio_config
    )
    result = recognizer.recognize_once()
    if result.reason == speechsdk.ResultReason.RecognizedSpeech:
        return result.text
    return ""

def get_instruction_prompt():
    return (
        "You are a compassionate memory-based voice assistant. "
        "Keep responses short (max 3 sentences). "
        "Avoid repeating yourself. Never respond if the user is silent "
        "or repeating your previous response. "
        "If the question is emotional, be empathetic. "
        "Do not mention you're an AI. Just respond like the loved one."
    )

def get_response_from_openai(user_input, context):
    messages = [
        {"role": "system", "content": get_instruction_prompt() + "\n" + context},
        {"role": "user", "content": user_input},
    ]
    response = openai_client.chat.completions.create(
        model=deployment_name, messages=messages, temperature=0.7
    )
    return response.choices[0].message.content.strip()

def speak_text_to_bytes(text) -> bytes:
    speech_synthesizer = speechsdk.SpeechSynthesizer(
        speech_config=speech_config,
        audio_config=speechsdk.audio.AudioOutputConfig(use_default_speaker=False)
    )
    result = speech_synthesizer.speak_text_async(text).get()
    return result.audio_data

@router.post("/voice-chat-once/")
async def voice_chat_once(file: UploadFile = File(...)):
    temp_filename = "temp_audio.wav"
    with open(temp_filename, "wb") as f:
        f.write(await file.read())

    user_text = recognize_audio_file(temp_filename)
    if not user_text:
        return {"error": "Could not recognize speech"}

    context = fetch_memories()
    ai_reply = get_response_from_openai(user_text, context)
    audio_bytes = speak_text_to_bytes(ai_reply)

    return StreamingResponse(io.BytesIO(audio_bytes), media_type="audio/wav")


# (All initialization as before...)

@router.post("/voice-chat-once/")
async def voice_chat_once(file: UploadFile = File(...)):
    # (All logic as before...)
    temp_filename = "temp_audio.wav"
    with open(temp_filename, "wb") as f:
        f.write(await file.read())
    user_text = recognize_audio_file(temp_filename)
    if not user_text:
        return {"error": "Could not recognize speech"}
    context = fetch_memories()
    ai_reply = get_response_from_openai(user_text, context)
    audio_bytes = speak_text_to_bytes(ai_reply)
    return StreamingResponse(io.BytesIO(audio_bytes), media_type="audio/wav")

# (All helper functions stay the same...)
