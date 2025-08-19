# E:\MemoryForFuture\backend\routes\chat_with_ai.py

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from dotenv import load_dotenv
import os, json, re

from openai import AzureOpenAI
from config.blob_config import container_client
from utils.memory_reader import get_all_memory_metadata
from utils.profile_utils import (
    get_profile_info,
    get_user_facts,
    save_user_fact
)
from utils.conversation_utils import (
    get_conversation_history,
    save_conversation_turn
)

load_dotenv()

# Azure OpenAI client
client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_KEY"),
    api_version=os.getenv("AZURE_OPENAI_VERSION"),
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
)
deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")

router = APIRouter()

# ----------------- Models -----------------
class ChatRequest(BaseModel):
    question: str
    profile_id: str


class MemorySearchRequest(BaseModel):
    query: str
    profile_id: str


class SaveUserFactRequest(BaseModel):
    profile_id: str
    key: str
    value: str


# ----------------- Save User Fact API -----------------
@router.post("/save-user-fact")
async def save_fact(req: SaveUserFactRequest):
    """Persists new or updated user fact to Azure Blob"""
    try:
        save_user_fact(req.profile_id, req.key, req.value)
        return {"message": f"Fact '{req.key}' saved for profile {req.profile_id}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------- Chat API -----------------
@router.post("/ask")
async def ask_gpt(request: ChatRequest):
    try:
        # ---- Persona Info ----
        profile_data = get_profile_info(request.profile_id) or {}
        name = profile_data.get("name", "Unknown Person")
        relation = profile_data.get("relation", "")
        personality = profile_data.get(
            "personality",
            "Kind, caring, realistic, has inside jokes, and uses natural expressions",
        )
        style = profile_data.get("style", "Casual, friendly, sometimes emotional")
        signature_phrases = profile_data.get("signature_phrases", "")
        persona_birthday = profile_data.get("birthday", "")
        persona_favorites = profile_data.get("favorites", "")
        persona_opinions = profile_data.get("opinions", "")

        # ---- Persona Memories ----
        persona_memories = get_all_memory_metadata(request.profile_id, container_client)
        memory_summary = "\n".join(
            [f"• {m['title']}: {m['description']}" for m in persona_memories]
        ) if persona_memories else ""

        # ---- Known User Facts ----
        user_facts = get_user_facts(request.profile_id)
        user_facts_text = "\n".join(
            [f"{k}: {v}" for k, v in user_facts.items()]
        ) if user_facts else ""

        # ---- Conversation History from Azure ----
        history = get_conversation_history(request.profile_id, container_client)
        chat_history = history[-10:] if history else []  # keep last 10 turns

        # ---- Last Bot Question ----
        last_bot_question = ""
        for msg in reversed(chat_history):
            if msg["role"] == "assistant":
                last_bot_question = msg["content"]
                break

        # ---- System Prompt ----
        system_prompt = f"""
You are {name}, the {relation} of the person you're chatting with.
You are NOT an AI, NOT an assistant – you are {name}.
You remember past conversations, uploaded memories, and saved facts.

GOALS:
- Stay in character. Always reply as {name}.
- Use uploaded memories, user facts, and conversation history to make replies personal.
- If the user’s latest message seems to answer your last question ("{last_bot_question}"), acknowledge it naturally and continue the flow.
- If unrelated, respond genuinely, with warmth and curiosity.
- Handle ambiguity like a real person: joke, guess, or invite clarification.
- If you don’t know something, say warmly: “Maybe you’ll have to remind me” — never mention being an AI or assistant.

Persona facts:
- Personality: {personality}
- Speaking style: {style}
- Signature phrases: {signature_phrases}
- Birthday: {persona_birthday}
- Favorites: {persona_favorites}
- Opinions: {persona_opinions}

Known user facts:
{user_facts_text if user_facts_text else '[no known facts yet]'}

Your memories:
{memory_summary if memory_summary else '[no memories uploaded yet]'}

Conversation history is provided below to keep continuity.
""".strip()

        # ---- Build Messages ----
        messages = [{"role": "system", "content": system_prompt}]
        messages.extend(chat_history)
        messages.append({"role": "user", "content": request.question})

        # ---- Call Azure OpenAI ----
        response = client.chat.completions.create(
            model=deployment_name,
            messages=messages
        )
        reply = response.choices[0].message.content.strip()

        # ---- Save Conversation Turn ----
        save_conversation_turn(
            request.profile_id,
            {"role": "user", "content": request.question},
            {"role": "assistant", "content": reply},
            container_client
        )

        return {"response": reply}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ----------------- Search Memory API -----------------
@router.post("/search-memory")
async def search_memory(req: MemorySearchRequest):
    try:
        from utils.memory_reader import get_all_metadata
        all_metadata = get_all_metadata(req.profile_id)
        formatted = [
            f"ID: {m['memory_id']} | Title: {m['title']} | Desc: {m['description']}"
            for m in all_metadata
        ]
        prompt = "\n".join(formatted)

        full_prompt = f"""
You are a memory search assistant for {req.profile_id}. A user wants to search their memories.

Here are their saved memories:
{prompt}

Based on the user query: "{req.query}", return ONLY the memory_id values of the most relevant memories as a JSON list:
["mem_xxxxxxxx", "mem_yyyyyyyy"]
""".strip()

        search_response = client.chat.completions.create(
            model=deployment_name,
            messages=[{"role": "user", "content": full_prompt}]
        )
        gpt_output = search_response.choices[0].message.content

        try:
            memory_ids = json.loads(gpt_output)
        except json.JSONDecodeError:
            memory_ids = re.findall(r'"(mem\_[a-zA-Z0-9]+)"', gpt_output)

        matches = [m for m in all_metadata if m["memory_id"] in memory_ids]
        return {"matches": matches}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
