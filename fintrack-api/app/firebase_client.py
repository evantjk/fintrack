import os
import firebase_admin
from firebase_admin import credentials, firestore

# Global variable to cache the Firestore client
_db = None

def get_firestore_client():
    """Lazily initialize the Firebase Admin app and return a Firestore client."""
    global _db
    
    # Return the cached client if it already exists
    if _db is not None:
        return _db

    # Initialize the app only if it hasn't been initialized yet
    if not firebase_admin._apps:
        # Safely fetch environment variables
        cert_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
        project_id = os.environ.get("FIREBASE_PROJECT_ID")

        if not cert_path or not project_id:
            raise ValueError("Missing GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_PROJECT_ID in environment variables.")

        cred = credentials.Certificate(cert_path)
        firebase_admin.initialize_app(cred, {
            "projectId": project_id,
        })

    # Create and cache the Firestore client
    _db = firestore.client()
    return _db