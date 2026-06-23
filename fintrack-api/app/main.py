from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.firebase_client import get_firestore_client
from app.routers import categories, transactions

app = FastAPI(title="FinTrack API")

# Local-dev only: lets the Flutter *web* build (served from its own
# localhost port, e.g. 5173) call this API (localhost:8000) - the browser
# enforces CORS, native/desktop targets don't need this at all.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://127.0.0.1:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(categories.router)
app.include_router(transactions.router)


@app.get("/health")
def health():
    get_firestore_client()
    return {"status": "ok"}
