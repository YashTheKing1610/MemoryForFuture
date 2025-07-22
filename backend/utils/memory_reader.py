### 📁 File: utils/memory_reader.py
import json
from azure.storage.blob import ContainerClient

def get_all_memory_metadata(profile_id: str, container_client: ContainerClient):
    metadata_path_prefix = f"profiles/{profile_id}/metadata/"
    memory_metadata = []

    blob_list = container_client.list_blobs(name_starts_with=metadata_path_prefix)
    for blob in blob_list:
        if blob.name.endswith(".json"):
            blob_client = container_client.get_blob_client(blob.name)
            content = blob_client.download_blob().readall()
            memory_metadata.append(json.loads(content))

    return memory_metadata


### 📁 File: routes/azure_openai.py (or routes/chat_with_ai.py)
from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel
from utils.memory_reader import get_all_memory_metadata
from config.blob_config import container_client

router = APIRouter(prefix="/ai")

class MemorySearchRequest(BaseModel):
    query: str
    profile_id: str

@router.post("/search-memory")
async def search_memory(request: MemorySearchRequest):
    profile_id = request.profile_id
    query = request.query.lower()

    try:
        memories = get_all_memory_metadata(profile_id, container_client)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading memory metadata: {str(e)}")

    matched = []
    for memory in memories:
        if query in memory.get("title", "").lower() or query in memory.get("description", "").lower():
            matched.append(memory)

    return {"matches": matched, "message": "Success" if matched else "No memories found"}


### 📁 File: routes/memory_upload.py (or your upload endpoint)
from fastapi import UploadFile, File, Form, APIRouter
from uuid import uuid4
from azure.storage.blob import ContentSettings
import json
from config.blob_config import container_client

router = APIRouter()

@router.post("/upload-memory/")
async def upload_memory(
    file: UploadFile = File(...),
    profile_id: str = Form(...),
    title: str = Form(...),
    description: str = Form(...),
    tags: str = Form(...),
    emotion: str = Form(...),
    collection: str = Form(...),
    is_favorite: bool = Form(...),
):
    memory_id = f"mem_{uuid4().hex[:8]}"
    file_ext = file.filename.split(".")[-1]
    blob_path = f"profiles/{profile_id}/images/{memory_id}.{file_ext}"

    blob_client = container_client.get_blob_client(blob_path)
    await blob_client.upload_blob(await file.read(), overwrite=True, content_settings=ContentSettings(content_type=file.content_type))

    metadata = {
        "memory_id": memory_id,
        "profile_id": profile_id,
        "title": title,
        "description": description,
        "tags": tags.split(","),
        "emotion": emotion,
        "collection": collection,
        "is_favorite": is_favorite,
        "file_type": file.content_type,
        "file_path": blob_path,
    }

    metadata_blob_path = f"profiles/{profile_id}/metadata/{memory_id}.json"
    metadata_blob_client = container_client.get_blob_client(metadata_blob_path)
    metadata_blob_client.upload_blob(json.dumps(metadata), overwrite=True, content_settings=ContentSettings(content_type="application/json"))

    return {"message": "Memory uploaded successfully", "memory_id": memory_id}


### 📁 File: main.py (ensure router is included)
from fastapi import FastAPI

def root():
    return {"message": "MemoryForFuture API is running"}

import json
from azure.storage.blob import ContainerClient
from typing import List


def get_latest_memory_summary(profile_id: str, container_client: ContainerClient) -> str:
    memories = get_all_memory_metadata(profile_id, container_client)
    if not memories:
        return "No past memories found."

    sorted_memories = sorted(memories, key=lambda m: m.get("timestamp") or m.get("uploaded_at", ""), reverse=True)
    latest = sorted_memories[0]
    return f"{latest['title']}: {latest['description']}"
