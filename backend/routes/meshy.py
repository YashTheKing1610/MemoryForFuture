from fastapi import APIRouter, File, UploadFile, HTTPException
import httpx
from dotenv import load_dotenv
import os

load_dotenv()

router = APIRouter()

MESHY_API_KEY = os.getenv("MESHY_API_KEY")
MESHY_API_URL = "https://api.meshy.ai/v1/"

if not MESHY_API_KEY:
    raise RuntimeError("MESHY_API_KEY is not set in environment variables.")

@router.post("/generate-3d/")
async def generate_3d_model(file: UploadFile = File(...)):
    """Start Meshy image-to-3D conversion and return the task ID immediately."""
    try:
        contents = await file.read()
        files = {
            "image_file": (file.filename, contents, file.content_type)
        }
        headers = {"Authorization": f"Bearer {MESHY_API_KEY}"}

        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(MESHY_API_URL + "image-to-3d", headers=headers, files=files)

        if response.status_code != 200:
            raise HTTPException(status_code=response.status_code, detail=response.json())

        data = response.json()
        task_id = data.get("task_id")
        if not task_id:
            raise HTTPException(status_code=500, detail="No task_id returned by Meshy API")

        return {
            "message": "3D model generation started",
            "task_id": task_id
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/generate-3d/status/{task_id}")
async def check_generation_status(task_id: str):
    """Check Meshy 3D generation task status."""
    try:
        headers = {"Authorization": f"Bearer {MESHY_API_KEY}"}
        async with httpx.AsyncClient(timeout=30) as client:
            poll = await client.get(MESHY_API_URL + f"tasks/{task_id}", headers=headers)

        if poll.status_code != 200:
            raise HTTPException(status_code=poll.status_code, detail=poll.json())

        data = poll.json()
        status = data.get("status")

        if status == "completed":
            return {
                "status": "completed",
                "model_url": data["result"].get("glb_url"),
                "preview": data["result"].get("thumbnail_url"),
                "task_id": task_id
            }
        elif status == "failed":
            return {"status": "failed", "error": "Meshy generation failed"}
        else:
            return {"status": status}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
