import sys
import os
import logging
import json
import io
import uuid
import datetime
import threading
from pydantic import BaseModel
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
from dotenv import load_dotenv
from azure_voice_assistant_api import fetch_memories, get_response_from_openai, speak_text

import requests
import uvicorn

# Add project root and backend to Python path for imports
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.append(project_root)  # backend folder
sys.path.append(os.path.abspath(os.path.join(project_root, "..")))  # MemoryForFuture root

# Import voice assistant CLI loop (ensure this script runs independently from FastAPI)
from assistant_loop import start_voice_loop

# Load environment variables
load_dotenv()

# Initialize logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# API Keys and URLs
API_KEY = os.getenv("FISH_AUDIO_API_KEY")
BASE_URL = "https://api.fish.audio/v1"

# Initialize FastAPI instance
app = FastAPI(title="MemoryForFuture API")

# Add CORS middleware (customize for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import your routers (make sure the router variables are correctly exposed)
from routes.chat_with_ai import router as chat_ai_router
from azure_voice import router as voice_router
from routes.meshy import router as meshy_router
from routes.flux_aging import router as flux_router
from voice_assistant_api import router as voice_assistant_router
from routes.age_transform import router as age_transform_router


# Import utilities
from azure_utils import upload_file_to_blob
from utils.file_type import detect_file_type
from config.blob_config import blob_service_client, container_name
from utils.memory_reader import get_all_memory_metadata
from utils.profile_utils import (
    create_profile_in_storage,
    profile_exists,
    list_all_profiles,
    delete_profile_and_data,
    save_user_fact,
)

# Updated ProfileCreate model to accept user info fields
class ProfileCreate(BaseModel):
    name: str
    relation: str
    bio: Optional[str] = ""
    birthday: Optional[str] = None
    gender: Optional[str] = None
    favorite_color: Optional[str] = None
    hobby: Optional[str] = None
    # Add more fields if you want to collect more user facts


# Register routers
app.include_router(chat_ai_router, prefix="/ai", tags=["AI Chat"])
app.include_router(voice_router, prefix="/voice", tags=["Voice Clone"])
app.include_router(meshy_router, prefix="/meshy", tags=["Meshy AI"])
app.include_router(flux_router, prefix="/flux", tags=["Flux AI Aging"])
app.include_router(voice_assistant_router, prefix="/voice",tags=["Voice to Voice Chat"])
app.include_router(age_transform_router, tags=["GPT Image Aging"])

# Root endpoint
@app.get("/")
async def root():
    return {"message": "MemoryForFuture API is running ✅"}

# Test Azure Blob storage access
@app.get("/test-storage-access")
async def test_storage_access():
    try:
        containers = blob_service_client.list_containers()
        return {
            "message": "Azure Storage access successful ✅",
            "containers": [c.name for c in containers],
        }
    except Exception as e:
        logger.error(f"Storage access failed: {str(e)}")
        return {"message": "Access failed ❌", "error": str(e)}

# Upload memory endpoint
@app.post("/upload-memory/")
async def upload_memory(
    file: UploadFile = File(...),
    title: str = Form(...),
    profile_id: str = Form(...),
    description: str = Form(""),
    tags: Optional[str] = Form(""),
    emotion: Optional[str] = Form(""),
    collection: Optional[str] = Form(""),
    is_favorite: bool = Form(False),
):
    try:
        memory_id = f"mem_{uuid.uuid4().hex[:8]}"
        ext = file.filename.split(".")[-1].lower()
        file_type = detect_file_type(ext)
        file_name = f"{memory_id}.{ext}"
        file_content = await file.read()

        blob_path = upload_file_to_blob(profile_id, file_type, file_content, file_name)

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
            "is_favorite": is_favorite,
        }

        metadata_bytes = io.BytesIO(json.dumps(metadata, indent=2).encode("utf-8"))
        upload_file_to_blob(profile_id, "metadata", metadata_bytes, f"{memory_id}.json")

        return {
            "message": "Memory uploaded successfully ✅",
            "memory_id": memory_id,
            "file_path": blob_path,
        }
    except Exception as e:
        logger.error(f"Memory upload failed: {str(e)}")
        return {"message": "Memory upload failed ❌", "error": str(e)}

# Get memories endpoint
@app.get("/get-memories/{profile_id}")
async def get_memories(profile_id: str):
    try:
        container_client = blob_service_client.get_container_client(container_name)
        prefix = f"profiles/{profile_id}/metadata/"
        blobs = container_client.list_blobs(name_starts_with=prefix)

        memories = []
        for blob in blobs:
            if blob.name.endswith(".json"):
                blob_client = container_client.get_blob_client(blob.name)
                content = blob_client.download_blob().readall()
                try:
                    memory = json.loads(content)
                    if "file_path" in memory:
                        memory["content_url"] = f"https://{blob_service_client.account_name}.blob.core.windows.net/{container_name}/{memory['file_path']}"
                    memories.append(memory)
                except json.JSONDecodeError as err:
                    logger.warning(f"Skipping malformed JSON: {blob.name} ❌ Error: {err}")

        return memories
    except Exception as e:
        logger.error(f"Failed to fetch memories for profile {profile_id}: {str(e)}")
        return {"message": "Failed to fetch memories ❌", "error": str(e)}

# Create profile endpoint (updated to save user facts)
@app.post("/create-profile/")
async def create_profile_endpoint(profile: ProfileCreate):
    profile_id = f"{profile.name.lower().strip()}_{profile.relation.lower().strip()}".replace(" ", "_")

    if profile_exists(profile_id):
        raise HTTPException(status_code=400, detail=f"Profile '{profile.name} ({profile.relation})' already exists ⚠️")

    # Create profile with persona and user facts
    result = create_profile_in_storage(
        profile_id,
        profile.name.strip(),
        profile.relation.strip(),
        personality="Kind and helpful",
        style="Casual and friendly",
        signature_phrases="",
        user_birthday=profile.birthday or "",
        user_favorite_color=profile.favorite_color or "",
        user_hobby=profile.hobby or "",
    )

    # Save additional user facts like bio and gender
    if profile.bio:
        save_user_fact(profile_id, "bio", profile.bio)
    if profile.gender:
        save_user_fact(profile_id, "gender", profile.gender)

    return {**result, "profile_id": profile_id}

# Get all profiles endpoint
@app.get("/get-profiles/")
async def get_profiles():
    return {"profiles": list_all_profiles()}

# Delete profile endpoint
@app.delete("/delete-profile/{profile_id}")
async def delete_profile(profile_id: str):
    if not profile_exists(profile_id):
        raise HTTPException(status_code=404, detail="Profile not found")

    return delete_profile_and_data(profile_id)

# Voice clone endpoint
@app.post("/clone-voice/")
async def clone_voice(
    audio: UploadFile = File(...),
    language: str = Form("en"),
):
    try:
        url = f"{BASE_URL}/voice/clone"
        files = {"audio": (audio.filename, await audio.read())}
        headers = {"Authorization": f"Bearer {API_KEY}"}
        data = {"language": language}
        response = requests.post(url, headers=headers, files=files, data=data)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"Voice clone failed: {str(e)}")
        return {"error": str(e)}

# TTS with clone voice endpoint
@app.post("/tts-with-clone/")
async def tts_with_clone(
    voice_id: str = Form(...),
    text: str = Form(...),
    language: str = Form("en"),
):
    try:
        url = f"{BASE_URL}/tts"
        headers = {"Authorization": f"Bearer {API_KEY}"}
        data = {"voice_id": voice_id, "text": text, "language": language}
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        return response.content
    except Exception as e:
        logger.error(f"TTS with clone failed: {str(e)}")
        return {"error": str(e)}

# Voice assistant loop starter
def run_voice_assistant():
    start_voice_loop("yash_1610")  # Pass current profile id dynamically if needed

@app.post("/talk")
async def talk_to_ai(user_id: str = Form(...)):
    response = run_voice_assistant(user_id)
    return {"message": response}

if __name__ == "__main__":
    threading.Thread(target=run_voice_assistant, daemon=True).start()
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
