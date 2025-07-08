import json

# ✅ Get latest memory summaries (3 most recent)
def get_latest_memory_summary(profile_id, container_client, max_files=3):
    try:
        prefix = f"{profile_id}/metadata/"
        blob_list = container_client.list_blobs(name_starts_with=prefix)

        json_blobs = sorted(
            [blob.name for blob in blob_list if blob.name.endswith(".json")],
            reverse=True
        )[:max_files]

        summaries = []
        for blob_name in json_blobs:
            blob_client = container_client.get_blob_client(blob_name)
            content = blob_client.download_blob().readall()
            data = json.loads(content)

            summaries.append(
                f"- {data.get('title', 'Untitled')} ({data.get('emotion', 'Neutral')}): {data.get('description', '')}"
            )

        return "\n".join(summaries) if summaries else "No memories found."

    except Exception as e:
        return f"(Error fetching memories: {str(e)})"


# ✅ Get all metadata memory objects for search
def get_all_memory_metadata(profile_id, container_client):
    try:
        prefix = f"{profile_id}/metadata/"
        blob_list = container_client.list_blobs(name_starts_with=prefix)

        metadata = []
        for blob in blob_list:
            if blob.name.endswith(".json"):
                blob_client = container_client.get_blob_client(blob.name)
                content = blob_client.download_blob().readall()
                data = json.loads(content)
                metadata.append(data)

        return metadata

    except Exception as e:
        print(f"Error reading memory metadata: {str(e)}")
        return []
