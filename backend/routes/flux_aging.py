# routes/flux_aging.py

from fastapi import APIRouter, File, UploadFile, Form
import requests
import os
from dotenv import load_dotenv
import base64
from PIL import Image
import io
from datetime import datetime

load_dotenv()

router = APIRouter()

TOGETHER_API_KEY = os.getenv("TOGETHER_API_KEY")
TOGETHER_API_URL = "https://api.together.xyz/v1/images/generations"
SAVE_DIR = os.path.join("static", "flux_results")

os.makedirs(SAVE_DIR, exist_ok=True)  # Ensure save folder exists


def resize_image(file_bytes, max_size=(512, 512)):
    """Resize the image to avoid 'Request Entity Too Large' errors."""
    image = Image.open(io.BytesIO(file_bytes))
    image.thumbnail(max_size)
    output_buffer = io.BytesIO()
    image.save(output_buffer, format=image.format or "PNG")
    return output_buffer.getvalue()


def save_image_to_static(image_bytes, prefix="flux_result"):
    """Save image bytes to static/flux_results and return file path."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"{prefix}_{timestamp}.png"
    filepath = os.path.join(SAVE_DIR, filename)
    with open(filepath, "wb") as f:
        f.write(image_bytes)
    return filepath


@router.post("/age-transform/")
async def age_transform(
    file: UploadFile = File(...),
    prompt: str = Form(...),
    age: int = Form(...)
):
    """
    Transform a face to a different age using Flux AI and return direct URL.
    """
    headers = {
        "Authorization": f"Bearer {TOGETHER_API_KEY}",
        "Content-Type": "application/json"
    }

    img_bytes = await file.read()
    resized_bytes = resize_image(img_bytes)
    img_b64 = base64.b64encode(resized_bytes).decode("utf-8")

    payload = {
        "model": "black-forest-labs/FLUX.1-schnell-Free",
        "prompt": f"{prompt}, make the person look {age} years old",
        "image": img_b64,
        "width": 512,
        "height": 512
    }

    response = requests.post(TOGETHER_API_URL, headers=headers, json=payload)

    if response.status_code != 200:
        return {
            "error": "Transformation failed (HTTP error)",
            "details": response.json()
        }

    data = response.json()

    if "error" in data:
        return {
            "error": "Transformation failed (API error)",
            "details": data
        }

    # ✅ Always return direct URL if available
    if "data" in data and data["data"]:
        result = data["data"][0]

        if "url" in result and result["url"]:
            return {
                "status": "completed",
                "image_url": result["url"]
            }

        elif "b64_json" in result and result["b64_json"]:
            # Save locally too
            image_bytes = base64.b64decode(result["b64_json"])
            saved_path = save_image_to_static(image_bytes)
            return {
                "status": "completed",
                "saved_path": saved_path,
                "image_base64": result["b64_json"]
            }

    return {
        "error": "No image returned from Flux AI",
        "details": data
    }
