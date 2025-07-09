import json
from azure.storage.blob import BlobServiceClient
from io import BytesIO

def get_voice_model_config(profile_id, container_client):
    try:
        blob_client = container_client.get_blob_client(f"{profile_id}/voice_model_info.json")
        data = blob_client.download_blob().readall()
        return json.loads(data)
    except:
        return None

def save_voice_model_config(profile_id, config: dict, container_client):
    blob_client = container_client.get_blob_client(f"{profile_id}/voice_model_info.json")
    blob_client.upload_blob(
        json.dumps(config),
        overwrite=True,
        content_settings={"content_type": "application/json"}
    )
