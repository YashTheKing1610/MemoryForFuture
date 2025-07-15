from fastapi import FastAPI, UploadFile, Form, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from typing import Optional

import os
import uuid
import json
import io
import datetime

# Routers
from azure_openai import router as ai_router
from azure_voice import router as voice_router
from azure_voice_assistant import router as assistant_router

# Azure and local utils
from azure_utils import upload_file_to_blob
from utils.file_type import detect_file_type
from config.blob_config import blob_service_client, container_name
from utils.memory_reader import get_all_memory_metadata
from utils.profile_utils import (
    create_profile_in_storage,
    profile_exists,
    list_all_profiles,
    delete_profile_and_data
)

# Load .env
load_dotenv()

# Initialize app
app = FastAPI(title="MemoryForFuture API")

# Allow all origins (use stricter CORS in production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(ai_router, prefix="/ai", tags=["AI Chat"])
app.include_router(voice_router, prefix="/voice", tags=["Voice Clone"])
app.include_router(assistant_router, prefix="/assistant", tags=["Voice Assistant"])

@app.get("/")
def root():
    return {"message": "MemoryForFuture API is running ✅"}


@app.get("/test-storage-access")
def test_storage_access():
    try:
        containers = blob_service_client.list_containers()
        return {
            "message": "Azure Storage access successful ✅",
            "containers": [c.name for c in containers]
        }
    except Exception as e:
        return {"message": "Access failed ❌", "error": str(e)}


@app.post("/upload-memory/")
async def upload_memory(
    file: UploadFile,
    title: str = Form(...),
    profile_id: str = Form(...),
    description: str = Form(""),
    tags: Optional[str] = Form(""),
    emotion: Optional[str] = Form(""),
    collection: Optional[str] = Form(""),
    is_favorite: bool = Form(False)
):
    try:
        memory_id = f"mem_{uuid.uuid4().hex[:8]}"
        ext = file.filename.split(".")[-1].lower()
        file_type = detect_file_type(ext)
        file_name = f"{memory_id}.{ext}"

        file_content = await file.read()

        # Upload memory file
        blob_path = upload_file_to_blob(profile_id, file_type, file_content, file_name)

        # Metadata
        metadata = {
            "memory_id": memory_id,
            "profile_id": profile_id,
            "title": title,
            "description": description,
            "file_type": file_type,
            "file_path": blob_path.split(f"{container_name}/")[-1],
            "upload_date": datetime.datetime.utcnow().isoformat(),
            "tags": tags.split(",") if tags else [],
            "emotion": emotion,
            "collection": collection,
            "is_favorite": is_favorite
        }

        metadata_bytes = io.BytesIO(json.dumps(metadata, indent=2).encode("utf-8"))
        upload_file_to_blob(profile_id, "metadata", metadata_bytes, f"{memory_id}.json")

        return {
            "message": "Memory uploaded successfully ✅",
            "memory_id": memory_id,
            "file_path": blob_path
        }

    except Exception as e:
        return {
            "message": "Memory upload failed ❌",
            "error": str(e)
        }


@app.get("/get-memories/{profile_id}")
def get_memories(profile_id: str):
    try:
        container_client = blob_service_client.get_container_client(container_name)
        memories = get_all_memory_metadata(profile_id, container_client)
        return memories
    except Exception as e:
        return {"message": "Failed to fetch memories ❌", "error": str(e)}


# ✅ Create Profile with name + relation
@app.post("/create-profile/")
def create_profile(
    name: str = Form(...),
    relation: str = Form(...)
):
    # Generate profile_id from name + relation
    profile_id = f"{name.lower().strip()}_{relation.lower().strip()}".replace(" ", "_")

    if profile_exists(profile_id):
        raise HTTPException(status_code=400, detail=f"Profile '{name} ({relation})' already exists ⚠️")

    result = create_profile_in_storage(profile_id, name.strip(), relation.strip())
    return {**result, "profile_id": profile_id}


# ✅ Get all profiles from Azure Blob Storage
@app.get("/get-profiles/")
def get_profiles():
    return {"profiles": list_all_profiles()}


# ✅ Delete Profile and All Memories
@app.delete("/delete-profile/{profile_id}")
def delete_profile(profile_id: str):
    if not profile_exists(profile_id):
        raise HTTPException(status_code=404, detail="Profile not found")

    return delete_profile_and_data(profile_id)
