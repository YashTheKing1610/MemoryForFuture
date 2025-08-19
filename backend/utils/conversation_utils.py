# backend/utils/conversation_utils.py

import json
from typing import List, Dict
from azure.storage.blob import ContainerClient

# ----------------- Conversation History (Azure Blob) -----------------

def _get_conversation_blob_name(profile_id: str) -> str:
    """
    Returns the blob path where conversation history is stored for a profile.
    """
    return f"profiles/{profile_id}/conversations/history.json"


def get_conversation_history(profile_id: str, container_client: ContainerClient) -> List[Dict]:
    """
    Loads the full conversation history for a given profile_id from Azure Blob Storage.
    Returns a list of dicts like: [{"role": "user"/"assistant", "content": "..."}]
    """
    blob_name = _get_conversation_blob_name(profile_id)
    blob_client = container_client.get_blob_client(blob_name)

    try:
        if not blob_client.exists():
            return []
        data = blob_client.download_blob().readall()
        return json.loads(data.decode("utf-8"))
    except Exception:
        return []


def save_conversation_turn(profile_id: str, user_message: Dict, bot_message: Dict, container_client: ContainerClient):
    """
    Saves a user + assistant turn to the conversation history in Azure Blob Storage.
    """
    history = get_conversation_history(profile_id, container_client)
    history.append(user_message)
    history.append(bot_message)

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
