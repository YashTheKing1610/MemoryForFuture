# E:\MemoryForFuture\backend\azure_voice_assistant_api.py

import os, time, json
from dotenv import load_dotenv
from azure.storage.blob import BlobServiceClient
from azure.cognitiveservices.speech import (
    SpeechConfig, SpeechRecognizer, SpeechSynthesizer, AudioConfig, ResultReason
)
from openai import AzureOpenAI

# Import shared utilities (same as chatbot)
from utils.memory_reader import get_all_memory_metadata
from utils.profile_utils import (
    get_profile_info,
    get_user_facts,
)
from utils.conversation_utils import (
    get_conversation_history,
    save_conversation_turn
)

# ----------------- Setup -----------------
load_dotenv()

blob_service_client = BlobServiceClient.from_connection_string(
    os.getenv("AZURE_STORAGE_CONNECTION_STRING")
)
container_client = blob_service_client.get_container_client(
    os.getenv("AZURE_CONTAINER_NAME")
)

speech_config = SpeechConfig(
    subscription=os.getenv("AZURE_SPEECH_KEY"),
    region=os.getenv("AZURE_SPEECH_REGION")
)
speech_config.speech_recognition_language = "en-US"
speech_synthesizer = SpeechSynthesizer(speech_config=speech_config)

openai_client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_KEY"),
    api_version=os.getenv("AZURE_OPENAI_VERSION"),
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT")
)
deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")

EXIT_COMMANDS = {"bye", "goodbye", "exit", "quit", "stop", "cancel"}


# ----------------- Helpers -----------------
def build_system_prompt(profile_id: str, last_bot_question: str = "") -> str:
    """Build persona-aware system prompt just like chatbot"""
    profile_data = get_profile_info(profile_id) or {}
    name = profile_data.get("name", "Unknown Person")
    relation = profile_data.get("relation", "")
    personality = profile_data.get("personality", "Kind, caring, realistic")
    style = profile_data.get("style", "Casual, friendly, sometimes emotional")
    sig_phrases = profile_data.get("signature_phrases", "")
    birthday = profile_data.get("birthday", "")
    favorites = profile_data.get("favorites", "")
    opinions = profile_data.get("opinions", "")

    # Memories
    persona_memories = get_all_memory_metadata(profile_id, container_client)
    memory_summary = "\n".join(
        [f"• {m['title']}: {m['description']}" for m in persona_memories]
    ) if persona_memories else "[no memories uploaded yet]"

    # Known user facts
    user_facts = get_user_facts(profile_id)
    user_facts_text = (
        "\n".join([f"{k}: {v}" for k, v in user_facts.items()]) if user_facts else "[no known facts yet]"
    )

    return f"""
You are {name}, the {relation} of the person you're chatting with.
You are NOT an AI, NOT an assistant – you are {name}.
You remember past conversations, uploaded memories, and saved facts.

IMPORTANT:
- Keep answers voice-friendly (max 2-3 sentences).
- Stay in character. Always reply as {name}.
- Use uploaded memories, user facts, and conversation history to make replies personal.
- If the user’s latest message seems to answer your last question ("{last_bot_question}"), acknowledge naturally and continue.
- If unrelated, respond warmly and with curiosity.
- If you don’t know, say warmly: “Maybe you’ll have to remind me.”

Persona facts:
- Personality: {personality}
- Speaking style: {style}
- Signature phrases: {sig_phrases}
- Birthday: {birthday}
- Favorites: {favorites}
- Opinions: {opinions}

Known user facts:
{user_facts_text}

Your memories:
{memory_summary}

Conversation flow will follow naturally, as if spoken.
""".strip()


def recognize_speech():
    audio_config = AudioConfig(use_default_microphone=True)
    recognizer = SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)
    print("Listening... Speak now.")
    result = recognizer.recognize_once_async().get()
    if result.reason == ResultReason.RecognizedSpeech:
        return result.text.strip()
    return None


def speak_text(text):
    print(f"Assistant: {text}")
    speech_synthesizer.speak_text_async(text).get()


def get_response_from_openai(profile_id: str, user_input: str):
    # Load history
    history = get_conversation_history(profile_id, container_client)
    chat_history = history[-10:] if history else []
    last_bot_question = ""
    for msg in reversed(chat_history):
        if msg["role"] == "assistant":
            last_bot_question = msg["content"]
            break

    # System prompt
    system_prompt = build_system_prompt(profile_id, last_bot_question)

    # Messages
    messages = [{"role": "system", "content": system_prompt}]
    messages.extend(chat_history)   # maintain continuity
    messages.append({"role": "user", "content": user_input})

    # Call Azure OpenAI
    response = openai_client.chat.completions.create(
        model=deployment_name,
        messages=messages,
        temperature=0.7,
    )
    reply = response.choices[0].message.content.strip()

    # Save conversation turn
    save_conversation_turn(
        profile_id,
        {"role": "user", "content": user_input},
        {"role": "assistant", "content": reply},
        container_client
    )
    return reply


# ----------------- Main Loop -----------------
def main(profile_id=None):
    if profile_id is None:
        profile_id = input("Enter profile ID: ").strip()  # dynamic input or pass from CLI
    
    print(f"MemoryForFuture Voice Assistant Started for profile: {profile_id}")
    speak_text("Hello, how are you feeling today?")

    last_user_input = None
    while True:
        user_input = recognize_speech()
        if not user_input or user_input == last_user_input:
            continue
        last_user_input = user_input

        normalized_input = user_input.lower().strip()
        if any(cmd in normalized_input for cmd in EXIT_COMMANDS):
            speak_text("Goodbye for now.")
            return

        print(f"You: {user_input}")
        response = get_response_from_openai(profile_id, user_input)
        speak_text(response)
        time.sleep(1.5)


def fetch_memories():
    print(" Loading memories from Azure Blob...")
    memory_context = ""
    for blob in container_client.list_blobs():
        if blob.name.endswith(('.txt', '.json')):
            stream = container_client.download_blob(blob.name).readall().decode('utf-8')
            memory_context += f"\n\n---\n{blob.name}:\n{stream}"
    return memory_context


def speak_text(text):
    print(f" Speaking: {text}")
    speech_synthesizer.speak_text_async(text).get()
    
def get_instruction_prompt():
    return (
        "You are a compassionate memory-based voice assistant. "
        "Keep responses short (max 3 sentences). "
        "Avoid repeating yourself. Never respond if the user is silent or repeating your previous response. "
        "If the question is emotional, be empathetic. "
        "Do not mention you're an AI. Just respond like the loved one."
    )


def get_response_from_openai(user_input, context):
    try:
        messages = [
            {"role": "system", "content": get_instruction_prompt() + "\n" + context},
            {"role": "user", "content": user_input},
        ]
        response = openai_client.chat.completions.create(
            model=deployment_name,
            messages=messages,
            temperature=0.7,
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"[ERROR]: {e}")
        return "Something went wrong."

if __name__ == "__main__":
    main("user_123")  # You can pass the profile_id of the person
