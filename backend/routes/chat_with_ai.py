from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
import os
import json

from openai import AzureOpenAI
from config.blob_config import container_client
from utils.memory_reader import get_all_memory_metadata

# Load environment variables
load_dotenv()

# Initialize Azure OpenAI client
client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_KEY"),
    api_version=os.getenv("AZURE_OPENAI_VERSION"),
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
)

deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")

router = APIRouter()

# ---------------------- ✅ Request Models ---------------------- #
class ChatRequest(BaseModel):
    question: str
    profile_id: str

class MemorySearchRequest(BaseModel):
    query: str
    profile_id: str

# ---------------------- ✅ /ai/ask ---------------------- #
@router.post("/ai/ask")
async def ask_gpt(request: ChatRequest):
    try:
        # Get all metadata for the profile
        all_memories = get_all_memory_metadata(request.profile_id, container_client)
        memory_summary = "\n".join([
            f"• {m['title']}: {m['description']}" for m in all_memories
        ]) if all_memories else "No past memories found."

        system_prompt = (
            "You are a helpful and emotionally intelligent AI who understands human memories.\n\n"
            f"The user's memory summaries are:\n{memory_summary}\n\n"
            "Now help the user based on these memories."
        )

        response = client.chat.completions.create(
            model=deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.question}
            ]
        )

        return {"response": response.choices[0].message.content}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ---------------------- ✅ /ai/search-memory ---------------------- #

@router.post("/search-memory")
async def search_memory(req: MemorySearchRequest):
    query = req.query
    profile_id = req.profile_id

    # Step 1: Get all metadata for that profile
    all_metadata = get_all_metadata(profile_id)
    print("=== All Metadata ===")
    print(json.dumps(all_metadata, indent=2))

    # Step 2: Build a prompt from metadata
    formatted = [
        f"ID: {m['memory_id']} | Title: {m['title']} | Desc: {m['description']}"
        for m in all_metadata
    ]
    prompt = "\n".join(formatted)

    full_prompt = f"""You are a memory search assistant. A user wants to search their memories.

Here are their saved memories:
{prompt}

Based on the user query: "{query}", return only the memory_id values of the most relevant memories in this format:

["mem_xxxxxxxx", "mem_yyyyyyyy"]
"""

    # Step 3: Ask GPT
    gpt_output = get_chat_completion(full_prompt)
    print("=== GPT Output ===")
    print(gpt_output)

    # Step 4: Try to extract memory IDs from GPT response
    try:
        memory_ids = json.loads(gpt_output)
    except json.JSONDecodeError:
        print("Fallback to regex...")
        memory_ids = re.findall(r'"(mem_[a-zA-Z0-9]+)"', gpt_output)

    # Step 5: Filter matching metadata
    matches = [m for m in all_metadata if m["memory_id"] in memory_ids]
    return {"matches": matches}