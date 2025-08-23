# vr.py
import os
import json
import uuid
from datetime import datetime, timedelta
from fastapi import APIRouter, HTTPException, Request
from azure.storage.blob import (
    BlobServiceClient,
    generate_blob_sas,
    BlobSasPermissions,
)
from dotenv import load_dotenv

# Load env vars
load_dotenv()
CONN_STR = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
CONTAINER = os.getenv("AZURE_CONTAINER_NAME")

if not CONN_STR or not CONTAINER:
    raise RuntimeError("Azure storage configuration missing in .env file")

# --- Parse account name & key from connection string ---
def _parse_connection_string(conn_str: str):
    parts = dict(p.split("=", 1) for p in conn_str.split(";") if "=" in p)
    return parts.get("AccountName"), parts.get("AccountKey")

ACCOUNT_NAME, ACCOUNT_KEY = _parse_connection_string(CONN_STR)
if not ACCOUNT_NAME or not ACCOUNT_KEY:
    raise RuntimeError("Could not parse AccountName/AccountKey from connection string")

# Azure clients
blob_service_client = BlobServiceClient.from_connection_string(CONN_STR)
container_client = blob_service_client.get_container_client(CONTAINER)

# FastAPI router
router = APIRouter(prefix="/vr", tags=["VR"])

# --- Helpers ---
def generate_sas_url(blob_name: str, expiry_minutes: int = 30) -> str:
    """Generate a short-lived read-only SAS URL for a blob"""
    sas = generate_blob_sas(
        account_name=ACCOUNT_NAME,
        container_name=CONTAINER,
        blob_name=blob_name,
        account_key=ACCOUNT_KEY,
        permission=BlobSasPermissions(read=True),
        expiry=datetime.utcnow() + timedelta(minutes=expiry_minutes),
    )
    return f"https://{ACCOUNT_NAME}.blob.core.windows.net/{CONTAINER}/{blob_name}?{sas}"

def _detect_type_from_name(name: str) -> str:
    """Infer memory type from file extension"""
    lower = name.lower()
    if lower.endswith((".jpg", ".jpeg", ".png", ".gif", ".webp")):
        return "image"
    if lower.endswith((".mp4", ".mov", ".mkv", ".avi", ".webm")):
        return "video"
    if lower.endswith((".mp3", ".wav", ".ogg", ".m4a")):
        return "audio"
    return "document"

# --- Routes ---
@router.get("/room/sample")
async def get_sample_room():
    """
    Return all memories in the container (for sample Unity scene testing).
    """
    try:
        memories = []
        for blob in container_client.list_blobs():
            try:
                sas = generate_sas_url(blob.name)
            except Exception:
                continue
            memories.append({
                "id": str(uuid.uuid4()),
                "name": blob.name,
                "type": _detect_type_from_name(blob.name),
                "url": sas,
            })

        return {
            "room_id": "sample_room",
            "scene": "default_sample_scene",
            "memories": memories,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch sample room: {e}")

@router.post("/room/active/{profile_id}")
async def set_active_room(profile_id: str, request: Request):
    body = await request.json()
    memory_paths = body.get("memory_paths")
    if not memory_paths or not isinstance(memory_paths, list):
        raise HTTPException(status_code=400, detail="Provide 'memory_paths' as a list of blob paths")

    prefix = f"profiles/{profile_id}/"
    for p in memory_paths:
        if not p.startswith(prefix):
            raise HTTPException(status_code=400, detail=f"Invalid path: {p}. Must start with '{prefix}'")

    active = {
        "room_id": f"active_{profile_id}",
        "profile_id": profile_id,
        "created_at": datetime.utcnow().isoformat() + "Z",
        "memory_paths": memory_paths,
    }

    blob_name = f"profiles/{profile_id}/active_room.json"
    try:
        blob_client = container_client.get_blob_client(blob_name)
        blob_client.upload_blob(json.dumps(active), overwrite=True, content_type="application/json")
        return {"status": "ok", "message": "Active room saved", "room_blob": blob_name}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save active room: {e}")
    
@router.get("/room/active/{profile_id}")
async def get_active_room(profile_id: str):
    """
    Return active_room.json if present, else list all files under profile folder.
    """
    active_blob_name = f"profiles/{profile_id}/active_room.json"
    memories = []

    try:
        blob_client = container_client.get_blob_client(active_blob_name)
        try:
            data = blob_client.download_blob().readall()
            active = json.loads(data.decode("utf-8"))
            memory_paths = active.get("memory_paths", [])
        except Exception:
            memory_paths = []  # No active room set → fallback

        if memory_paths:
            for path in memory_paths:
                try:
                    sas = generate_sas_url(path)
                except Exception:
                    continue
                memories.append({
                    "id": str(uuid.uuid4()),
                    "name": path,
                    "type": _detect_type_from_name(path),
                    "url": sas,
                })
        else:
            prefix = f"profiles/{profile_id}/"
            for blob in container_client.list_blobs(name_starts_with=prefix):
                try:
                    sas = generate_sas_url(blob.name)
                except Exception:
                    continue
                memories.append({
                    "id": str(uuid.uuid4()),
                    "name": blob.name,
                    "type": _detect_type_from_name(blob.name),
                    "url": sas,
                })

        return {
            "room_id": f"active_{profile_id}",
            "profile_id": profile_id,
            "memories": memories,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to build active room: {e}")