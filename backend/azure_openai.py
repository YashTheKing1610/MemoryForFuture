from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
import os
import openai
import json
from main import container_client
from utils.memory_reader import get_latest_memory_summary, get_all_memory_metadata

load_dotenv()

# Azure OpenAI configuration
openai.api_type = "azure"
openai.api_base = os.getenv("AZURE_OPENAI_ENDPOINT")
openai.api_key = os.getenv("AZURE_OPENAI_KEY")
openai.api_version = os.getenv("AZURE_OPENAI_VERSION")
deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")

# FastAPI Router
router = APIRouter()


# ---------- Model Definitions ----------
class ChatRequest(BaseModel):
    question: str
    profile_id: str

class MemorySearchRequest(BaseModel):
    query: str
    profile_id: str


# ---------- Route: /ask ----------
@router.post("/ask")
async def ask_gpt(request: ChatRequest):
    try:
        memory_summary = get_latest_memory_summary(request.profile_id, container_client)

        system_prompt = (
            "You are an emotional AI who helps users reflect on their memories.\n\n"
            f"The user's past memories include:\n{memory_summary}\n\n"
            "Respond kindly and helpfully using these memories."
        )

        response = openai.ChatCompletion.create(
            engine=deployment_name,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": request.question}
            ]
        )

        return {"response": response['choices'][0]['message']['content']}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ---------- Route: /search-memory ----------
@router.post("/search-memory")
async def search_memories(req: MemorySearchRequest):
    try:
        all_metadata = get_all_memory_metadata(req.profile_id, container_client)

        if not all_metadata:
            return {"matches": [], "message": "No memories found"}

        # Format memory list for GPT
        memory_list = "\n".join(
            [f"{i+1}. {m['title']} | {m['description']} | {m.get('emotion', '')} | {m.get('tags', [])}" for i, m in enumerate(all_metadata)]
        )

        prompt = (
            f"You are a memory search assistant. A user has stored the following memories:\n\n"
            f"{memory_list}\n\n"
            f"Now, based on the user query: '{req.query}', return only the memory_ids (max 3) that match best as a JSON array."
        )

        response = openai.ChatCompletion.create(
            engine=deployment_name,
            messages=[
                {"role": "system", "content": "You are an intelligent memory search engine."},
                {"role": "user", "content": prompt}
            ]
        )

        gpt_output = response['choices'][0]['message']['content']

        # Try parsing GPT output
        try:
            memory_ids = json.loads(gpt_output)
        except:
            return {"matches": [], "message": "Couldn't extract valid memory IDs from AI response."}

        # Filter matching memories
        matches = [m for m in all_metadata if m['memory_id'] in memory_ids]
        return {"matches": matches}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
