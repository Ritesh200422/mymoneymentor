import google.generativeai as genai
import os
from dotenv import load_dotenv
import json
import re

# ✅ Load .env from Flutter root assets folder
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "mymoneymentor","..", "assets", ".env")
env_path = os.path.abspath(env_path)
load_dotenv(dotenv_path=env_path)

# ✅ Configure Gemini API key
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError(f"❌ GEMINI_API_KEY not found in {env_path}")

genai.configure(api_key=api_key)

def clean_json_output(text: str):
    """
    Safely extract and parse JSON array from Gemini's response.
    """
    try:
        json_match = re.search(r"\[.*\]", text, re.DOTALL)
        if json_match:
            return json.loads(json_match.group(0))
    except json.JSONDecodeError as e:
        print("⚠️ JSON parsing error:", e)
    except Exception as e:
        print("⚠️ Unexpected parsing error:", e)
    return []

def generate_quiz_from_content(content: str, num_questions: int = 5):
    """
    Generate a multiple-choice quiz from lesson content using Gemini.
    """
    prompt = f"""
    You are a quiz generator for a financial education app.

    Based on the following LESSON CONTENT, create {num_questions} multiple-choice questions in JSON array format only.

    Each question must strictly follow this format:
    [
      {{
        "question": "Why is saving important?",
        "options": ["For emergencies", "For fun", "For nothing", "To spend later"],
        "correctIndex": 0
      }}
    ]

    The questions should be clear, simple, and relevant to the topic.

    LESSON CONTENT:
    {content}
    """

    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(prompt)
        text = response.text.strip()

        quiz_data = clean_json_output(text)

        # ✅ fallback if invalid/missing quiz
        if not quiz_data or not isinstance(quiz_data, list):
            quiz_data = [{
                "question": "What did you learn from this lesson?",
                "options": ["Financial basics", "Nothing", "Unclear", "Saving"],
                "correctIndex": 0
            }]

        return quiz_data

    except Exception as e:
        print("❌ Gemini API Error:", e)
        return [{
            "question": "Quiz generation failed.",
            "options": ["Try again later"],
            "correctIndex": 0
        }]
