# backend/config/blob_config.py

from azure.storage.blob import BlobServiceClient
import os
from dotenv import load_dotenv

load_dotenv()

connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
container_name = os.getenv("AZURE_CONTAINER_NAME")

blob_service_client = BlobServiceClient.from_connection_string(connection_string)
container_client = blob_service_client.get_container_client(container_name)
