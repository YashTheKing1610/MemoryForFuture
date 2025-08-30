from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import datetime
import json
import os

from azure.storage.blob import (
    BlobServiceClient,
    generate_blob_sas,
    BlobSasPermissions,
    ContentSettings,
)

router = APIRouter()

# Load environment variables for Azure Storage
AZURE_CONNECTION_STRING = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
CONTAINER_NAME = os.getenv("AZURE_CONTAINER_NAME")

blob_service_client = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING)
container_client = blob_service_client.get_container_client(CONTAINER_NAME)


class MemorySelection(BaseModel):
    profile_id: str
    selected_memory_ids: List[str]


def get_account_key():
    parts = AZURE_CONNECTION_STRING.split(";")
    for part in parts:
        if part.lower().startswith("accountkey="):
            return part.split("=", 1)[1]
    raise RuntimeError("Could not find account key in connection string")


account_name = blob_service_client.account_name
account_key = get_account_key()


def generate_sas_url(blob_name: str, expiry_hours: int = 105) -> str:
    sas_token = generate_blob_sas(
        account_name=account_name,
        container_name=CONTAINER_NAME,
        blob_name=blob_name,
        account_key=account_key,
        permission=BlobSasPermissions(read=True),
        expiry=datetime.datetime.utcnow() + datetime.timedelta(hours=expiry_hours),
    )
    return f"https://{account_name}.blob.core.windows.net/{CONTAINER_NAME}/{blob_name}?{sas_token}"


@router.post("/create-vr-room/")
async def create_vr_room(selection: MemorySelection):
    print(f"[INFO] Received memory IDs: {selection.selected_memory_ids}")
    if not selection.profile_id or not selection.selected_memory_ids:
        raise HTTPException(status_code=400, detail="profile_id and selected_memory_ids are required")

    possible_locations = {
        "image": ("images", [".jpg", ".jpeg", ".png", ".webp"]),
        "video": ("videos", [".mp4", ".mov", ".webm"]),
        "audio": ("voice_samples", [".mp3", ".wav", ".m4a"]),
        "text": ("documents", [".txt", ".json", ".pdf"]),
    }

    memories = []
    missing_ids = []

    for mem_id in selection.selected_memory_ids:
        found = False
        print(f"[INFO] Checking memory ID: {mem_id}")
        for mem_type, (folder, exts) in possible_locations.items():
            for ext in exts:
                blob_name = f"profiles/{selection.profile_id}/{folder}/{mem_id}{ext}"
                blob_client = container_client.get_blob_client(blob_name)
                try:
                    blob_exists = blob_client.exists()
                except Exception as e:
                    print(f"[ERROR] Exception checking blob {blob_name}: {e}")
                    blob_exists = False

                print(f"[DEBUG] Path: {blob_name} | Exists: {blob_exists}")

                if blob_exists:
                    try:
                        url = generate_sas_url(blob_name)
                        memories.append({
                            "id": mem_id,
                            "type": mem_type,
                            "url": url,
                            "title": f"{mem_id}{ext}",
                            "position": None,
                            "rotation": None,
                            "scale": None,
                        })
                        print(f"[SUCCESS] Added memory: {mem_id} @ {blob_name}")
                    except Exception as err:
                        print(f"[ERROR] Failed to generate SAS for {blob_name}: {err}")
                        continue
                    found = True
                    break
            if found:
                break
        if not found:
            missing_ids.append(mem_id)
            print(f"[WARNING] No blob found for memory ID: {mem_id}")

    if not memories:
        print(f"[ERROR] No matching blobs found for any of the selected IDs: {selection.selected_memory_ids}")
        raise HTTPException(status_code=404, detail="No matching memories found")

    if missing_ids:
        print(f"[INFO] These memory IDs did not have matching blobs: {missing_ids}")

    # Here is the change: overwrite single fixed active_room.json for all profiles at 'yash_me' folder
    active_room = {
        "room_id": f"room_{datetime.datetime.utcnow().strftime('%Y%m%d%H%M%S')}",
        "profile_id": selection.profile_id,
        "memories": memories,
    }

    active_room_json = json.dumps(active_room, indent=2)

    # Fixed blob path for shared JSON file
    fixed_blob_path = "profiles/yash_me/active_room.json"
    blob_client = container_client.get_blob_client(fixed_blob_path)

    try:
        blob_client.upload_blob(
            active_room_json,
            overwrite=True,
            content_settings=ContentSettings(content_type="application/json"),
        )
        print(f"[SUCCESS] Active room JSON uploaded to {fixed_blob_path}")
    except Exception as e:
        print(f"[ERROR] Failed to upload active_room.json to blob storage: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to upload active_room.json: {str(e)}")

    response = {
        "ok": True,
        "profile_id": selection.profile_id,
        "memories_count": len(memories),
        "missing_memory_ids": missing_ids,
        "active_room": active_room,
        # Return SAS URL for the fixed shared file only
        "active_room_url": generate_sas_url(fixed_blob_path),
    }
    print(f"[INFO] VR room creation response: {response}")
    return response
