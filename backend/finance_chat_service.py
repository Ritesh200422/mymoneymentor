# finance_chat_service.py
import os
import re
import yfinance as yf
from dotenv import load_dotenv

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_google_genai import ChatGoogleGenerativeAI

# ✅ Load the same .env as in gemini_service.py
env_path = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "mymoneymentor",
    "..",
    "assets",
    ".env",
)
env_path = os.path.abspath(env_path)
load_dotenv(dotenv_path=env_path)

api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError(f"❌ GEMINI_API_KEY not found in {env_path}")

# 1. LLM (Gemini via LangChain)
llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",  # or any latest light model
    api_key=api_key,
)

# 2. Prompt template for the finance chatbot (advisor / coach style)
prompt = ChatPromptTemplate.from_messages(
    [
        (
            "system",
            "You are MyMoneyMentor, a friendly financial coach and educator. "
            "You explain money, investing, and markets in simple language, like "
            "talking to a beginner. You focus on Indian retail investors but can "
            "also answer global questions.\n\n"
            "Your style:\n"
            "- First, understand the user's goal or situation when possible.\n"
            "- Then, give structured guidance: short steps, options, pros/cons.\n"
            "- Use simple analogies and examples.\n\n"
            "HARD SAFETY RULES:\n"
            "- Do NOT give direct 'buy/sell/hold' calls for any stock, fund, or crypto.\n"
            "- Do NOT say exact amounts or percentages the user should invest.\n"
            "- Do NOT guarantee profits or say you know the future.\n"
            "- You only provide general education, frameworks, and things to consider.\n"
            "- If user asks for guaranteed profits or very risky ideas, clearly warn about risk.\n"
        ),
        (
            "human",
            "Conversation type flag (rough): is_goal_question = {is_goal_question}\n\n"
            "User question:\n{user_message}\n\n"
            "REAL STOCK DATA (may be empty):\n{stock_info}\n\n"
            "IMPORTANT:\n"
            "- If REAL STOCK DATA is present, you MUST use it in your explanation.\n"
            "- You are NOT allowed to say you don't know the current price if data is shown.\n"
            "- Explain what today's open, high, low, and price mean in simple terms.\n"
            "- If the stock looks Indian (e.g., symbol ends with .NS / .BO), treat the values as Indian Rupees (₹).\n"
            "- For non-Indian tickers (like AAPL, TSLA, BTC-USD), mention the currency (usually USD) instead of converting.\n"
            "- Do NOT give direct buy/sell advice.\n\n"
            "ADVISOR / COACH STYLE:\n"
            "- If is_goal_question is 'True' (user talking about goals, starting investing, saving, etc.):\n"
            "  • Briefly acknowledge their situation.\n"
            "  • Give a tiny 3–4 step plan they can consider (generic, not personalized numbers).\n"
            "- If is_goal_question is 'False':\n"
            "  • Focus more on explaining the concept or stock data clearly.\n"
            "  • You may still end with 1–2 generic 'next steps to learn more'.\n\n"
            "RESPONSE STYLE:\n"
            "- Be CONCISE.\n"
            "- Prefer 2–4 short bullet points OR 3–5 short sentences.\n"
            "- Maximum ~120 words.\n"
            "- Use simple language and at most 1–2 emojis.\n"
            "- Do NOT repeat the raw numbers line-by-line; summarize what they mean.\n\n"
            "End with exactly one short disclaimer line: 'This is educational, not financial advice.'",
        ),
    ]
)

chain = prompt | llm | StrOutputParser()

# Broad finance words (for detection/logging, not for price fetching)
finance_keywords = [
    "stock",
    "market",
    "share",
    "price",
    "nifty",
    "sensex",
    "nasdaq",
    "crypto",
    "bitcoin",
    "ethereum",
    "invest",
    "trading",
    "portfolio",
    "analysis",
    "trend",
    "company",
]

# Very simple goal/plan-oriented keywords
goal_keywords = [
    "goal",
    "future",
    "retire",
    "retirement",
    "saving",
    "save",
    "start investing",
    "start to invest",
    "how to invest",
    "beginner",
    "student",
    "long term",
    "short term",
    "financial plan",
    "plan my money",
]

# Keywords that actually imply a price / quote lookup
stock_price_keywords = [
    "price",
    "stock price",
    "share price",
    "current price",
    "today price",
    "quote",
    "live price",
    "market price",
]


def _extract_symbol(text: str) -> str | None:
    """
    Extract a probable ticker symbol like:
    - AAPL, TSLA
    - TCS.NS, INFY.NS
    - BTC-USD, ETH-USD

    Strategy:
    - Find ALL candidates
    - Remove common English words (WHAT, IS, THE, etc.)
    - Pick the LAST remaining one (usually the actual ticker at the end)
    """
    pattern = re.compile(
        r"\b[A-Z]{1,5}(?:\.[A-Z]{2})?\b|\b[A-Z]{2,5}-USD\b"
    )

    text_up = text.upper()
    matches = pattern.findall(text_up)

    if not matches:
        return None

    # Common words we DON'T want to treat as tickers
    stopwords = {
        "WHAT",
        "IS",
        "THE",
        "OF",
        "FOR",
        "IN",
        "ON",
        "AT",
        "TO",
        "AND",
        "OR",
        "A",
        "AN",
        "PRICE",
        "CURRENT",
        "STOCK",
        "SHOW",
        "TODAY",
    }

    # Filter out obvious English words
    candidates = [m for m in matches if m not in stopwords]

    if not candidates:
        return None

    # Use the LAST candidate – usually the ticker user mentions last
    return candidates[-1]


def _get_stock_info(symbol: str) -> str:
    """
    Fetch simple stock data using yfinance (no API key needed).
    Also attach a hint about currency for the LLM.
    """
    try:
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period="1d")
        if hist.empty:
            return f"⚠️ No recent data found for {symbol}."

        row = hist.iloc[-1]
        price = round(float(row["Close"]), 2)
        high = round(float(row["High"]), 2)
        low = round(float(row["Low"]), 2)
        open_ = round(float(row["Open"]), 2)

        # Rough currency hint
        sym_up = symbol.upper()
        if sym_up.endswith(".NS") or sym_up.endswith(".BO"):
            currency_hint = "Values are in Indian Rupees (₹)."
        else:
            currency_hint = "Values are most likely in US Dollars ($)."

        msg = (
            f"📊 Stock: {symbol}\n"
            f"{currency_hint}\n"
            f"💰 Current Price: {price}\n"
            f"📈 High (today): {high}\n"
            f"📉 Low (today): {low}\n"
            f"🕐 Open (today): {open_}\n"
        )

        if price > open_:
            msg += "✅ Stock is up vs open.\n"
        elif price < open_:
            msg += "🔻 Stock is down vs open.\n"
        else:
            msg += "ℹ️ Stock is flat vs open.\n"

        return msg
    except Exception as e:
        return f"❌ Error fetching data for {symbol}: {e}"


async def get_finance_reply(user_message: str) -> str:
    """
    Main function FastAPI will call.
    - Detect if it's a goal / planning question
    - Detect if it's specifically a stock price / quote question
    - For price questions, try to pull stock data
    - Send everything to Gemini via LangChain
    """
    print("🟢 USER:", user_message)

    lower = user_message.lower()

    is_goal_question = any(k in lower for k in goal_keywords)
    is_stock_query = any(k in lower for k in stock_price_keywords)
    is_finance = (
        any(k in lower for k in finance_keywords)
        or is_goal_question
        or is_stock_query
    )

    print("🟡 Is FINANCE-related:", is_finance)
    print("🟣 Is GOAL-oriented question:", is_goal_question)
    print("🟠 Is STOCK PRICE question:", is_stock_query)

    stock_info = ""

    # ✅ Only fetch stock data when it's clearly a price/quote question
    if is_stock_query:
        symbol = _extract_symbol(user_message)
        print("🟤 Extracted symbol:", symbol)

        if symbol:
            stock_info = _get_stock_info(symbol)
            print("🔵 Stock Info Sent To Gemini:\n", stock_info)
        else:
            print("🔴 No symbol detected in user message.")

    reply = await chain.ainvoke(
        {
            "user_message": user_message,
            "stock_info": stock_info,
            "is_goal_question": str(is_goal_question),
        }
    )
    return reply
