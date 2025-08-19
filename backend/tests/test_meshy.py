
'''It returns status, progress, and output file URLs (glb, obj, textures, etc.) :contentReference[oaicite:5]{index=5}.

---

### 💡 What To Do in `test_meshy.py`

Since you tested with file upload (multipart) — but Meshy only supports JSON payload with a public URL or base64 — you should:

1. Upload your image to a publicly accessible storage (e.g., Azure Blob, AWS S3, imgur, etc.).
2. Or load it locally and convert it into a Base64 data URI.

---

### ✅ Sample Revised `test_meshy.py` Using Base64 Data URI

```python'''
import os, base64, requests

url = "https://api.meshy.ai/openapi/v1/image-to-3d"
headers = {
    "Authorization": f"Bearer {os.getenv('MESHY_API_KEY')}",
    "Content-Type": "application/json"
}

# Read image and encode as base64 Data URI
with open(r"C:\Users\Admin\Downloads\WhatsApp Image 2025-08-05 at 11.50.36 AM.jpeg", "rb") as f:
    data = base64.b64encode(f.read()).decode("utf-8")
    uri = f"data:image/jpeg;base64,{data}"

payload = {
    "image_url": uri,
    "enable_pbr": True,
    "should_remesh": True,
    "should_texture": True
}

resp = requests.post(url, headers=headers, json=payload)
print(resp.status_code, resp.text)

import requests

API_KEY = "Bearer msy_Gevy6fYLtMeSN6CNivMJcsQ2MvXwyU4TTHaU"
IMAGE_PATH = r"C:\Users\Admin\Downloads\WhatsApp Image 2025-08-05 at 11.50.36 AM.jpeg"

url = "https://api.meshy.ai/v1/image-to-3d/upload"

headers = {
    "Authorization": API_KEY,
}

files = {
    'image': open(IMAGE_PATH, 'rb'),
}

response = requests.post(url, headers=headers, files=files)

print(response.status_code)
print(response.text)
