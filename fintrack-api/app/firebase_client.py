import os
import firebase_admin
from firebase_admin import credentials, firestore

# Global variable to cache the Firestore client
_db = None


def ensure_initialized():
    """Initialize the Firebase Admin app once, if it hasn't been already.

    Both the Firestore client and the auth-token verifier (app/auth.py) need
    the Admin app initialized before they can be used, so this is the single
    entry point both paths call through.
    """
    if firebase_admin._apps:
        return

    cert_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    project_id = os.environ.get("FIREBASE_PROJECT_ID")

    if not cert_path or not project_id:
        raise ValueError(
            "Missing GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_PROJECT_ID "
            "in environment variables."
        )

    cred = credentials.Certificate(cert_path)
    firebase_admin.initialize_app(cred, {"projectId": project_id})


def get_firestore_client():
    """Lazily initialize the Firebase Admin app and return a Firestore client."""
    global _db

    if _db is not None:
        return _db

    ensure_initialized()
    _db = firestore.client()
    return _db
