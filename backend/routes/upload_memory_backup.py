from fastapi import APIRouter, UploadFile, Form, HTTPException
from fastapi.responses import JSONResponse
from config.blob_config import upload_file_to_blob
from utils.memory_enrichment import enrich_metadata
from uuid import uuid4
from datetime import datetime
import os
import json

router = APIRouter()

@router.post("/upload-memory/")
async def upload_memory(
    file: UploadFile,
    title: str = Form(...),
    profile_id: str = Form(...),
    description: str = Form(...),
    tags: str = Form("[]"),
    emotion: str = Form(""),
    collection: str = Form(""),
    is_favorite: bool = Form(False)
):
    try:
        file_ext = os.path.splitext(file.filename)[1]
        memory_id = f"mem_{uuid4().hex[:8]}"
        file_type = "images" if file_ext.lower() in [".jpg", ".jpeg", ".png"] else "videos" if file_ext.lower() in [".mp4", ".mov"] else "audios" if file_ext.lower() in [".mp3", ".wav"] else "documents"
        blob_path = f"profiles/{profile_id}/{file_type}/{memory_id}{file_ext}"

        upload_file_to_blob(file, blob_path)

        enriched_data = enrich_metadata({
            "memory_id": memory_id,
            "profile_id": profile_id,
            "title": title,
            "description": description,
            "tags": json.loads(tags),
            "emotion": emotion,
            "collection": collection,
            "is_favorite": is_favorite,
            "file_type": file_type,
            "file_path": blob_path,
            "upload_date": datetime.utcnow().isoformat()
        })

        profile_dir = f"database/profiles/{profile_id}/"
        os.makedirs(profile_dir, exist_ok=True)
        metadata_file = os.path.join(profile_dir, "metadata.json")

        metadata = []
        if os.path.exists(metadata_file):
            with open(metadata_file, "r") as f:
                metadata = json.load(f)

        metadata.append(enriched_data)
        with open(metadata_file, "w") as f:
            json.dump(metadata, f, indent=2)

        return JSONResponse(content={"message": "Memory uploaded and enriched successfully."}, status_code=200)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
