# backend/utils/conversation_utils.py

import json
from typing import List, Dict
from azure.storage.blob import ContainerClient

MAX_TURNS = 200  # max total messages (user + assistant) to keep in history


def _get_conversation_blob_name(profile_id: str) -> str:
    """
    Returns the blob path where conversation history is stored for a profile.
    """
    return f"profiles/{profile_id}/conversations/history.json"


def get_conversation_history(profile_id: str, container_client: ContainerClient) -> List[Dict]:
    """
    Loads the full conversation history for a given profile_id from Azure Blob Storage.
    Returns a list of dicts like: [{"role": "user"/"assistant", "content": "...", "source": "..."}]
    If the JSON is corrupted, returns an empty list safely.
    """
    blob_name = _get_conversation_blob_name(profile_id)
    blob_client = container_client.get_blob_client(blob_name)

    try:
        if not blob_client.exists():
            return []
        data = blob_client.download_blob().readall()
        try:
            return json.loads(data.decode("utf-8"))
        except json.JSONDecodeError:
            # Corrupt file, return empty history
            return []
    except Exception:
        # Any other error, return empty
        return []


def save_conversation_turn(
    profile_id: str,
    user_message: Dict,
    bot_message: Dict,
    container_client: ContainerClient,
    source: str = "chatbot"
):
    """
    Saves a user + assistant turn to the conversation history in Azure Blob Storage.
    Adds `source` field to messages to indicate origin ("chatbot" or "voice_assistant").
    Keeps only last MAX_TURNS messages to limit size.
    """
    history = get_conversation_history(profile_id, container_client)

    # Add source tagging
    user_message = user_message.copy()
    user_message["source"] = source
    bot_message = bot_message.copy()
    bot_message["source"] = source

    history.append(user_message)
    history.append(bot_message)

    # Limit history size
    if len(history) > MAX_TURNS:
        history = history[-MAX_TURNS:]

    blob_name = _get_conversation_blob_name(profile_id)
    blob_client = container_client.get_blob_client(blob_name)

    blob_client.upload_blob(
        json.dumps(history, ensure_ascii=False, indent=2),
        overwrite=True
    )


def clear_conversation_history(profile_id: str, container_client: ContainerClient):
    """
    Clears all conversation history for a profile_id from Azure Blob Storage.
    """
    blob_name = _get_conversation_blob_name(profile_id)
    blob_client = container_client.get_blob_client(blob_name)

    if blob_client.exists():
        blob_client.delete_blob()
