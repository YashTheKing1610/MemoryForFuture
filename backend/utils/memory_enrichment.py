import os
from openai import AzureOpenAI
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Azure OpenAI client
client = AzureOpenAI(
    api_key=os.getenv("AZURE_OPENAI_KEY"),
    api_version=os.getenv("AZURE_OPENAI_VERSION"),
    azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
)

deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT")

def enrich_memory_metadata(title: str, description: str) -> dict:
    """
    Uses AI to generate tags, emotion, and summary from title + description.
    """
    try:
        prompt = (
            f"Title: {title}\nDescription: {description}\n\n"
            "Based on this, respond in the following JSON format:\n"
            "{\n"
            "  \"tags\": [list of relevant tags as strings],\n"
            "  \"emotion\": \"primary emotion\",\n"
            "  \"summary\": \"1-2 sentence summary of this memory\"\n"
            "}"
        )

        response = client.chat.completions.create(
            model=deployment_name,
            messages=[
                {"role": "system", "content": "You are a helpful memory analysis assistant."},
                {"role": "user", "content": prompt}
            ]
        )

        json_output = response.choices[0].message.content

        import json
        enriched = json.loads(json_output)
        return enriched

    except Exception as e:
        print("❌ Memory enrichment failed:", str(e))
        return {"tags": [], "emotion": "Unknown", "summary": ""}

def enrich_metadata(memory):
    # 🧠 Dummy enrichment logic (can later use AI)
    keywords = []

    if "birthday" in memory["title"].lower() or "birthday" in memory["description"].lower():
        keywords.extend(["celebration", "cake", "friends", "party"])
        memory["emotion"] = memory["emotion"] or "joy"
        memory["collection"] = memory["collection"] or "Celebrations"

    if "report" in memory["title"].lower() or "report" in memory["description"].lower():
        keywords.extend(["documentation", "weekly", "project"])
        memory["emotion"] = memory["emotion"] or "professional"
        memory["collection"] = memory["collection"] or "Work"

    memory["tags"].extend(keywords)
    memory["tags"] = list(set(memory["tags"]))  # remove duplicates
    return memory
