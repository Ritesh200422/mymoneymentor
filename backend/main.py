from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from quiz_route import quiz_router
from finance_chat_service import get_finance_reply
from pydantic import BaseModel

app = FastAPI(title="MyMoneyMentor Backend")

# ✅ CORS setup – allow Flutter web / mobile dev
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*",  # for dev: allow all. For production, replace with specific origins.
        # e.g. "http://localhost:52791", "http://127.0.0.1:52791"
    ],
    allow_credentials=True,
    allow_methods=["*"],   # allow GET, POST, OPTIONS, etc.
    allow_headers=["*"],   # allow all headers
)

# ✅ Include existing quiz routes
app.include_router(quiz_router, prefix="/api")


# ✅ Root health check
@app.get("/")
def root():
    return {"message": "FastAPI backend for MyMoneyMentor is running!"}


# ================================
# ✅ Finance Chatbot API (LangChain + Gemini)
# ================================

class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    reply: str


@app.post("/api/chat", response_model=ChatResponse)
async def finance_chat(req: ChatRequest):
    """
    Main endpoint used by Flutter finance chatbot
    """
    reply = await get_finance_reply(req.message)
    return ChatResponse(reply=reply)
