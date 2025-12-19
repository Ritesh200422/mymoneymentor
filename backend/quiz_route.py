from fastapi import APIRouter, HTTPException
from datetime import datetime
from db import db
from gemini_service import generate_quiz_from_content

quiz_router = APIRouter()

@quiz_router.get("/generate_quiz/{user_id}/{category}/{lesson_id}")
def generate_quiz(user_id: str, category: str, lesson_id: str):
    """
    Generate or retrieve a quiz for a specific lesson.
    Supports both 'traditional' and 'nontraditional' lesson categories.
    """

    try:
        # Validate category
        category = category.lower().strip()
        if category not in ["traditional", "nontraditional"]:
            raise HTTPException(status_code=400, detail="Invalid category. Use 'traditional' or 'nontraditional'.")

        # ✅ Step 1: Check if quiz already exists
        quiz_ref = (
            db.collection("users")
            .document(user_id)
            .collection("quizzes")
            .document(f"{category}_{lesson_id}")  # Unique key per category
            .get()
        )
        if quiz_ref.exists:
            return {
                "status": "exists",
                "message": f"Quiz already generated for {category} lesson.",
                "quiz": quiz_ref.to_dict(),
            }

        # ✅ Step 2: Fetch lesson content from Firestore
        lesson_ref = (
            db.collection("learning")
            .document("s3dJjQIcaI4XDN2b80LD")
            .collection(category)
            .document(lesson_id)
            .get()
        )

        if not lesson_ref.exists:
            raise HTTPException(status_code=404, detail=f"{category.capitalize()} lesson not found")

        lesson_data = lesson_ref.to_dict()
        topics = lesson_data.get("topics", [])

        if not topics:
            raise HTTPException(status_code=400, detail="Lesson has no topics to generate quiz from")

        # ✅ Step 3: Combine all topic titles and content
        content_parts = []
        for topic in topics:
            # topic is a dict with subtopics like Introduction, Benefits, etc.
            if isinstance(topic, dict):
                for key, value in topic.items():
                    if value:
                        content_parts.append(f"{key}: {value}")

        full_content = "\n".join(content_parts).strip()

        if not full_content:
            raise HTTPException(status_code=400, detail="No valid content found for quiz generation")

        # ✅ Step 4: Generate quiz using Gemini
        quiz_data = generate_quiz_from_content(full_content)
        if not quiz_data:
            raise HTTPException(status_code=500, detail="Quiz generation failed")

        # ✅ Step 5: Prepare quiz record
        quiz_record = {
            "lessonId": lesson_id,
            "category": category,
            "generatedAt": datetime.utcnow().isoformat(),
            "quiz": quiz_data,
            "topicTitle": lesson_data.get("title", "Untitled Lesson"),
            "completed": False,
        }

        # ✅ Step 6: Store under user collection (unique per category)
        db.collection("users").document(user_id).collection("quizzes").document(
            f"{category}_{lesson_id}"
        ).set(quiz_record)

        return {"status": "success", "quiz": quiz_record}

    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
