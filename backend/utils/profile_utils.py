import io
import json
from azure.core.exceptions import ResourceExistsError
from azure.storage.blob import BlobServiceClient
from config.blob_config import blob_service_client, container_name, container_client

def get_profile_info(profile_id: str):
    """
    Fetch profile metadata (persona data) from Azure Blob Storage.
    Returns dictionary or None.
    """
    blob_name = f"profiles/{profile_id}/profile.json"
    blob_client = container_client.get_blob_client(blob_name)
    try:
        data = blob_client.download_blob().readall()
        return json.loads(data)
    except Exception as e:
        print(f"[get_profile_info] Error: {e}")
        return None

# ✅ Create a new profile (persona + user facts)
def create_profile_in_storage(profile_id: str, 
                               name: str, 
                               relation: str,
                               personality: str = "Kind and helpful",
                               style: str = "Casual and friendly",
                               signature_phrases: str = "",
                               user_birthday: str = "",
                               user_favorite_color: str = "",
                               user_hobby: str = ""):
    """
    Creates Azure Blob Storage structure for a profile and saves:
    - profile.json (AI persona details)
    - user_facts.json (real user details)
    """
    try:
        cont_client = blob_service_client.get_container_client(container_name)

        # --- Create base folders ---
        folder_types = ["images", "videos", "audios", "documents", "metadata"]
        for folder in folder_types:
            blob_path = f"{profile_id}/{folder}/.init"
            cont_client.get_blob_client(blob_path).upload_blob(b"", overwrite=True)

        # --- Save persona profile.json ---
        profile_data = {
            "id": profile_id,
            "name": name,
            "relation": relation,
            "personality": personality,
            "style": style,
            "signature_phrases": signature_phrases
        }
        profile_blob = cont_client.get_blob_client(f"profiles/{profile_id}/profile.json")
        profile_blob.upload_blob(io.BytesIO(json.dumps(profile_data, indent=2).encode("utf-8")), overwrite=True)

        # --- Save user_facts.json ---
        user_facts = {}
        if user_birthday:
            user_facts["birthday"] = user_birthday
        if user_favorite_color:
            user_facts["favorite_color"] = user_favorite_color
        if user_hobby:
            user_facts["hobby"] = user_hobby

        user_facts_blob = cont_client.get_blob_client(f"profiles/{profile_id}/user_facts.json")
        user_facts_blob.upload_blob(io.BytesIO(json.dumps(user_facts, indent=2).encode("utf-8")), overwrite=True)

        return {"message": f"Profile '{name}' created successfully ✅"}

    except ResourceExistsError:
        return {"message": f"Profile '{profile_id}' already exists ⚠️"}
    except Exception as e:
        return {"error": str(e)}

# ✅ Check if profile exists
def profile_exists(profile_id: str) -> bool:
    cont_client = blob_service_client.get_container_client(container_name)
    blob_path = f"profiles/{profile_id}/profile.json"
    blob_client = cont_client.get_blob_client(blob_path)
    return blob_client.exists()

# ✅ List all profiles
def list_all_profiles():
    try:
        cont_client = blob_service_client.get_container_client(container_name)
        blobs = cont_client.list_blobs(name_starts_with="profiles/")
        profiles = {}

        for blob in blobs:
            parts = blob.name.split("/")
            if len(parts) == 3 and parts[-1] == "profile.json":
                profile_id = parts[1]
                blob_client = cont_client.get_blob_client(blob.name)
                content = blob_client.download_blob().readall()
                data = json.loads(content)
                profiles[profile_id] = data

        return list(profiles.values())

    except Exception as e:
        return {"error": str(e)}

# ✅ Delete profile and all its data (persona + user facts + files)
def delete_profile_and_data(profile_id: str):
    try:
        cont_client = blob_service_client.get_container_client(container_name)

        # Delete subfolders under profile_id
        blobs = cont_client.list_blobs(name_starts_with=f"{profile_id}/")
        for blob in blobs:
            cont_client.delete_blob(blob.name)

        # Delete persona & user facts
        for meta in [
            f"profiles/{profile_id}/profile.json",
            f"profiles/{profile_id}/user_facts.json"
        ]:
            if cont_client.get_blob_client(meta).exists():
                cont_client.delete_blob(meta)

        return {"message": f"Profile '{profile_id}' and all data deleted ✅"}

    except Exception as e:
        return {"error": f"Failed to delete profile: {str(e)}"}

# ✅ Get user facts dict
def get_user_facts(profile_id: str):
    """
    Reads user_facts.json for given profile.
    Returns dict of known facts, or {}.
    """
    blob_name = f"profiles/{profile_id}/user_facts.json"
    blob_client = container_client.get_blob_client(blob_name)
    try:
        if blob_client.exists():
            data = blob_client.download_blob().readall()
            return json.loads(data)
    except Exception as e:
        print(f"[get_user_facts] Error: {e}")
    return {}

# ✅ Update/add a user fact
def save_user_fact(profile_id: str, key: str, value: str):
    """
    Save or update a fact about the real user in user_facts.json.
    """
    blob_name = f"profiles/{profile_id}/user_facts.json"
    blob_client = container_client.get_blob_client(blob_name)
    facts = get_user_facts(profile_id)
    facts[key] = value

    try:
        facts_json = json.dumps(facts, indent=2).encode("utf-8")
        blob_client.upload_blob(io.BytesIO(facts_json), overwrite=True)
        print(f"[save_user_fact] Saved fact '{key}': '{value}' for {profile_id}")
    except Exception as e:
        print(f"[save_user_fact] Error: {e}")
