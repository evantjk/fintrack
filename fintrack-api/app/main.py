from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI

from app.firebase_client import get_firestore_client

app = FastAPI()


@app.get("/health")
def health():
    get_firestore_client()
    return {"status": "ok"}
