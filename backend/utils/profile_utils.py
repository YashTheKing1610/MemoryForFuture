import io
import json
from azure.core.exceptions import ResourceExistsError
from azure.storage.blob import BlobServiceClient
from config.blob_config import blob_service_client, container_name


# ✅ Create a new profile in Azure Blob
def create_profile_in_storage(profile_id: str, name: str, relation: str):
    try:
        container_client = blob_service_client.get_container_client(container_name)

        # Create folders with .init file
        folder_types = ["images", "videos", "audios", "documents", "metadata"]
        for folder in folder_types:
            blob_path = f"{profile_id}/{folder}/.init"
            blob_client = container_client.get_blob_client(blob_path)
            blob_client.upload_blob(b"", overwrite=True)

        # Create profile metadata in 'profiles/<profile_id>/profile.json'
        profile_data = {
            "id": profile_id,
            "name": name,
            "relation": relation
        }
        profile_json = json.dumps(profile_data, indent=2).encode("utf-8")
        profile_blob = container_client.get_blob_client(f"profiles/{profile_id}/profile.json")
        profile_blob.upload_blob(io.BytesIO(profile_json), overwrite=True)

        return {"message": f"Profile '{name}' created successfully ✅"}

    except ResourceExistsError:
        return {"message": f"Profile '{profile_id}' already exists ⚠️"}

    except Exception as e:
        return {"error": str(e)}


# ✅ Check if profile exists
def profile_exists(profile_id: str) -> bool:
    container_client = blob_service_client.get_container_client(container_name)
    blob_path = f"profiles/{profile_id}/profile.json"
    blob_client = container_client.get_blob_client(blob_path)
    return blob_client.exists()


# ✅ List all saved profiles from profiles folder
def list_all_profiles():
    try:
        container_client = blob_service_client.get_container_client(container_name)
        blobs = container_client.list_blobs(name_starts_with="profiles/")
        profiles = {}

        for blob in blobs:
            parts = blob.name.split("/")
            if len(parts) == 3 and parts[-1] == "profile.json":
                profile_id = parts[1]
                blob_client = container_client.get_blob_client(blob.name)
                content = blob_client.download_blob().readall()
                data = json.loads(content)
                profiles[profile_id] = data

        return list(profiles.values())

    except Exception as e:
        return {"error": str(e)}


# ✅ Delete entire profile and its memories
def delete_profile_and_data(profile_id: str):
    try:
        container_client = blob_service_client.get_container_client(container_name)
        blobs = container_client.list_blobs(name_starts_with=f"{profile_id}/")

        for blob in blobs:
            container_client.delete_blob(blob.name)

        # Delete profile metadata as well
        profile_blob_path = f"profiles/{profile_id}/profile.json"
        if container_client.get_blob_client(profile_blob_path).exists():
            container_client.delete_blob(profile_blob_path)

        return {"message": f"Profile '{profile_id}' and all data deleted ✅"}

    except Exception as e:
        return {"error": f"Failed to delete profile: {str(e)}"}
