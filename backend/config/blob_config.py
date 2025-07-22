# backend/config/blob_config.py

import os
from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv
from uuid import uuid4

load_dotenv()

# Get environment variables
connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
container_name = os.getenv("AZURE_CONTAINER_NAME")

if not connection_string:
    raise ValueError("AZURE_STORAGE_CONNECTION_STRING is missing in .env")
if not container_name:
    raise ValueError("AZURE_STORAGE_CONTAINER_NAME is missing in .env")

# Initialize Blob clients
blob_service_client = BlobServiceClient.from_connection_string(connection_string)
container_client = blob_service_client.get_container_client(container_name)

# ✅ This is the function that was missing
def upload_file_to_blob(file, blob_path):
    try:
        # Read file contents
        file_contents = file.file.read()

        # Upload to blob
        blob_client = container_client.get_blob_client(blob_path)
        blob_client.upload_blob(file_contents, overwrite=True)

        return f"{container_name}/{blob_path}"
    except Exception as e:
        print("Blob upload failed:", str(e))
        return None
