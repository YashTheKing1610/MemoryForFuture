import os
from azure.storage.blob import BlobServiceClient
from dotenv import load_dotenv

load_dotenv()

connection_string = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
container_name = os.getenv("AZURE_CONTAINER_NAME")

blob_service_client = BlobServiceClient.from_connection_string(connection_string)
container_client = blob_service_client.get_container_client(container_name)

def upload_file_to_blob(profile_id, folder, file_data, file_name):
    blob_path = f"profiles/{profile_id}/{folder}/{file_name}"
    blob_client = container_client.get_blob_client(blob_path)
    blob_client.upload_blob(file_data, overwrite=True)
    return blob_path
