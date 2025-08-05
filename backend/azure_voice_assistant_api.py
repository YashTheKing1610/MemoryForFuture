import os
import json
import time
import threading
from dotenv import load_dotenv
from azure.storage.blob import BlobServiceClient
from azure.cognitiveservices.speech import (
    SpeechConfig, SpeechRecognizer, SpeechSynthesizer, AudioConfig, ResultReason
)
from openai import AzureOpenAI

# Load environment variables
load_dotenv()

# Azure Blob Storage setup
blob_service_client = BlobServiceClient.from_connection_string(os.getenv("AZURE_STORAGE_CONNECTION_STRING"))
container_client = blob_service_client.get_container_client(os.getenv("AZURE_CONTAINER_NAME"))

# Azure Speech setup
speech_config = SpeechConfig(
    subscription=os.getenv("AZURE_SPEECH_KEY"),
    region=os.getenv("AZURE_SPEECH_REGION")
)
speech_config.speech_recognition_language = "en-US"
speech_synthesizer = SpeechSynthesizer(speech_config=speech_config)

# Azure OpenAI setup
openai_client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_KEY"),
    api_version=os.getenv("AZURE_OPENAI_VERSION"),
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)
deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")

# === Load Memories from Blob ===
def fetch_memories():
    print("🔁 Loading memories from Azure Blob...")
    memory_context = ""
    for blob in container_client.list_blobs():
        if blob.name.endswith(('.txt', '.json')):
            stream = container_client.download_blob(blob.name).readall().decode('utf-8')
            memory_context += f"\n\n---\n{blob.name}:\n{stream}"
    return memory_context

# === Custom System Instructions ===
def get_instruction_prompt():
    return (
        "You are a compassionate memory-based voice assistant. "
        "Keep responses short (max 3 sentences). "
        "Avoid repeating yourself. Never respond if the user is silent or repeating your previous response. "
        "If the question is emotional, be empathetic. "
        "Do not mention you're an AI. Just respond like the loved one."
    )

# === Recognize Speech ===
def recognize_speech():
    audio_config = AudioConfig(use_default_microphone=True)
    recognizer = SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)
    print("🎤 Listening... Speak now.")
    result = recognizer.recognize_once_async().get()
    if result.reason == ResultReason.RecognizedSpeech:
        return result.text
    elif result.reason == ResultReason.NoMatch:
        print("🤷 Speech not recognized.")
    return None

# === Speak Text ===
def speak_text(text):
    print("🗣️ Speaking...")
    speech_synthesizer.speak_text_async(text).get()

# === Get OpenAI Response ===
def get_response_from_openai(user_input, context):
    try:
        messages = [
            {"role": "system", "content": get_instruction_prompt() + "\n" + context},
            {"role": "user", "content": user_input}
        ]
        response = openai_client.chat.completions.create(
            model=deployment_name,
            messages=messages,
            temperature=0.7
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"[ERROR]: {e}")
        return "Something went wrong."

# === Main Loop ===
def main():
    context = fetch_memories()
    last_user_input = None

    while True:
        user_input = recognize_speech()

        # Avoid duplicate or empty input
        if not user_input or user_input == last_user_input:
            continue
        last_user_input = user_input

        print(f"👤 You: {user_input}")
        response = get_response_from_openai(user_input, context)
        print(f"🤖 Assistant: {response}\n")
        speak_text(response)

        # Prevent assistant from hearing itself
        time.sleep(2.5)  # Small delay after speaking

# === Entry Point ===
if __name__ == "__main__":
    print("🚀 MemoryForFuture Voice Assistant Started...")
    main()
