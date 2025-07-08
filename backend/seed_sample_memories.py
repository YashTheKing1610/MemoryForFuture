from azure.storage.blob import BlobServiceClient, ContentSettings
import os
import json
from dotenv import load_dotenv
import datetime

# ✅ Load environment variables from .env file
load_dotenv()

# ✅ Get values from .env
connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
container_name = os.getenv("AZURE_CONTAINER_NAME")
profile_id = "usman001"  # You can change this or use user input

# ✅ Connect to Azure Blob container
blob_service_client = BlobServiceClient.from_connection_string(connection_string)
container_client = blob_service_client.get_container_client(container_name)

# ✅ Define sample memory metadata
sample_memories = [
    {
        "memory_id": "mem_123456",
        "profile_id": profile_id,
        "title": "Diwali Celebration",
        "description": "Lighting diyas with Dad and enjoying sweets.",
        "file_type": "image",
        "file_path": f"{profile_id}/images/diwali1.jpg",
        "upload_date": str(datetime.datetime.now()),
        "tags": ["Diwali", "Dad", "Festival"],
        "emotion": "Happy",
        "collection": "Festivals",
        "is_favorite": True
    },
    {
        "memory_id": "mem_789012",
        "profile_id": profile_id,
        "title": "Beach Trip with Sister",
        "description": "Playing in the sand and swimming.",
        "file_type": "video",
        "file_path": f"{profile_id}/videos/beach_trip.mp4",
        "upload_date": str(datetime.datetime.now()),
        "tags": ["Beach", "Sister", "Vacation"],
        "emotion": "Joyful",
        "collection": "Family",
        "is_favorite": False
    },
    {
        "memory_id": "mem_456789",
        "profile_id": profile_id,
        "title": "Grandma's Last Eid",
        "description": "Our last Eid together. She gave me a special gift.",
        "file_type": "image",
        "file_path": f"{profile_id}/images/eid_grandma.jpg",
        "upload_date": str(datetime.datetime.now()),
        "tags": ["Eid", "Grandma", "Gift"],
        "emotion": "Emotional",
        "collection": "Family",
        "is_favorite": True
    }
]

# ✅ Upload metadata as .json blobs
for memory in sample_memories:
    blob_name = f"{profile_id}/metadata/{memory['memory_id']}.json"
    blob_client = container_client.get_blob_client(blob_name)

    blob_client.upload_blob(
        json.dumps(memory),
        overwrite=True,
        content_settings=ContentSettings(content_type="application/json")
    )

    print(f"✅ Uploaded: {blob_name}")
