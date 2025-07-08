from fastapi import FastAPI, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv
from azure_utils import upload_file_to_blob
from utils.file_type import detect_file_type

import os
import uuid
import json
import io
import datetime

# Load environment variables
load_dotenv()

# Azure connection setup
connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
container_name = os.getenv("AZURE_CONTAINER_NAME")
blob_service_client = BlobServiceClient.from_connection_string(connection_string)
container_client = blob_service_client.get_container_client(container_name)

# FastAPI app setup
app = FastAPI()

# CORS settings (allow from all origins for now)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Import OpenAI router
from azure_openai import router as ai_router
app.include_router(ai_router)

# ✅ Optional test route to verify if API is working
@app.get("/")
def root():
    return {"message": "MemoryForFuture API is running"}

# ✅ ✅ TEST AZURE STORAGE ACCESS
@app.get("/test-storage-access")
def test_storage_access():
    try:
        containers = blob_service_client.list_containers()
        container_names = [c.name for c in containers]
        return {
            "message": "Access to Azure Storage is successful",
            "containers": container_names
        }
    except Exception as e:
        return {
            "message": "Access failed",
            "error": str(e)
        }

# ✅ MEMORY UPLOAD API
@app.post("/upload-memory/")
async def upload_memory(
    file: UploadFile,
    title: str = Form(...),
    description: str = Form(""),
    profile_id: str = Form(...),
    tags: str = Form(""),
    emotion: str = Form(""),
    collection: str = Form(""),
    is_favorite: bool = Form(False)
):
    try:
        memory_id = f"mem_{uuid.uuid4().hex[:8]}"
        ext = file.filename.split(".")[-1]
        file_type = detect_file_type(ext)
        file_name = f"{memory_id}.{ext}"

        # Read and upload file
        file_content = await file.read()
        file_blob_path = upload_file_to_blob(profile_id, file_type, file_content, file_name)

        # Prepare metadata
        metadata = {
            "memory_id": memory_id,
            "profile_id": profile_id,
            "title": title,
            "description": description,
            "file_type": file_type,
            "file_path": file_blob_path.split(f"{container_name}/")[-1],
            "upload_date": str(datetime.datetime.now()),
            "tags": tags.split(",") if tags else [],
            "emotion": emotion,
            "collection": collection,
            "is_favorite": is_favorite
        }

        # Upload metadata as JSON
        json_bytes = io.BytesIO(json.dumps(metadata).encode("utf-8"))
        upload_file_to_blob(profile_id, "metadata", json_bytes, f"{memory_id}.json")

        return {"message": "Memory uploaded successfully", "memory_id": memory_id}
    
    except Exception as e:
        return {"message": "Upload failed", "error": str(e)}
