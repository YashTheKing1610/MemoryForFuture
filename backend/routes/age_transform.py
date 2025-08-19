import os
import io
import base64
import uuid
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import JSONResponse

# Comment out OpenAI and dotenv imports for local/mock/dev run
# from openai import OpenAI
# from dotenv import load_dotenv
from PIL import Image

# Optionally: load_dotenv()  # Only needed if using dotenv

router = APIRouter(prefix="/age-transform", tags=["image"])

# For local file saves
SAVE_DIR = os.path.join("static", "aging_results")
os.makedirs(SAVE_DIR, exist_ok=True)


def _build_prompt(direction: str, years: Optional[int], strength: float) -> str:
    """Build a safe, identity-preserving age transformation prompt."""
    if direction not in {"older", "younger"}:
        raise ValueError("direction must be 'older' or 'younger'")
    years = years if (years and 0 < years <= 70) else (20 if direction == "younger" else 25)
    strength = max(0.0, min(1.0, strength))
    base_constraints = (
        "Preserve the person's identity, facial proportions, and skin tone. "
        "Do not change pose, expression, hairstyle length, or background. "
        "Avoid artifacts; keep lighting, shadows, and color grading natural. "
        "No makeup or beautification unless already present. "
    )
    if direction == "older":
        specifics = (
            f"Make the subject look approximately {years} years older with realistic, subtle signs of aging "
            "(fine lines, slight skin texture changes, possible graying hair) while keeping them recognizable. "
        )
    else:
        specifics = (
            f"Make the subject look approximately {years} years younger with natural features of youth "
            "(smoother skin, reduced wrinkles, slightly fuller cheeks) while keeping them recognizable. "
        )
    if strength < 0.33:
        intensity = "Apply a very subtle effect."
    elif strength < 0.66:
        intensity = "Apply a moderate effect."
    else:
        intensity = "Apply a strong but still realistic effect."
    return f"{specifics} {intensity} {base_constraints} Keep clothing and background unchanged."


@router.post("/", response_class=JSONResponse)
async def age_transform(
    file: UploadFile = File(..., description="User portrait image (png/jpg/jpeg)"),
    direction: str = Form(..., description="older|younger"),
    years: Optional[int] = Form(None, description="Years to age/de-age (e.g., 10, 20, 30)"),
    strength: float = Form(0.5, description="0.0–1.0 intensity control (default 0.5)"),
    profile_id: Optional[str] = Form(None, description="Optional: tie output to a profile"),
    collection: Optional[str] = Form("aging", description="Optional: logical collection/bucket"),
) -> JSONResponse:
    """
    MOCK DEV VERSION: Accepts an image and information, returns a static/dummy link for now,
    so that FastAPI can run without an OpenAI key.
    """
    # Validate file type
    if file.content_type.lower() not in {"image/png", "image/jpg", "image/jpeg"}:
        raise HTTPException(status_code=415, detail="Unsupported file type. Use PNG or JPG/JPEG.")
    try:
        prompt = _build_prompt(direction.strip().lower(), years, strength)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    # Read and validate image (test if PIL can open it)
    input_bytes = await file.read()
    try:
        img = Image.open(io.BytesIO(input_bytes))
        img.verify()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image file.")

    # Instead of OpenAI, just "save" the original image and return dummy info
    uid = uuid.uuid4().hex[:12]
    ts = datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    filename = f"{direction}-{years or 'auto'}y-{uid}-{ts}.png"
    saved_path = os.path.join(SAVE_DIR, filename)
    with open(saved_path, "wb") as f:
        f.write(input_bytes)
    public_url = f"/static/aging_results/{filename}"

    # Return mock success for the UI/frontend
    return JSONResponse(
        {
            "status": "ok",
            "direction": direction,
            "years": years,
            "strength": strength,
            "model": "mock-gpt-image",
            "prompt_used": prompt,
            "url": public_url,
            "profile_id": profile_id,
            "collection": collection,
            "note": "This is a mock/dummy response; no actual age transformation performed.",
        },
        status_code=200,
    )
