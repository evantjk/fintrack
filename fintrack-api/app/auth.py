from typing import Optional

from fastapi import Header, HTTPException, status
from firebase_admin import auth as firebase_auth

from .firebase_client import ensure_initialized


async def get_current_uid(authorization: Optional[str] = Header(None)) -> str:
    """Verifies the Firebase ID token in the Authorization header and
    returns the signed-in user's uid.

    This is what scopes every Firestore read/write to users/{uid}/..., the
    same isolation firestore.rules currently provides client-side, except
    enforced server-side now that the API holds the Admin credentials.

    The header default is None (not a required Header(...)) so a missing
    header reaches this function and gets a 401, instead of FastAPI's
    automatic request-validation layer rejecting it first with a 422.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED,
            "Missing or malformed Authorization header",
        )

    token = authorization.removeprefix("Bearer ").strip()
    ensure_initialized()

    try:
        decoded = firebase_auth.verify_id_token(token)
    except Exception:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token")

    return decoded["uid"]
