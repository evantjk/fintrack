from typing import Optional

from firebase_admin import firestore as admin_firestore

from ..firebase_client import get_firestore_client
from ..schemas.transaction import TransactionCreate, TransactionOut, TransactionUpdate


def _collection(uid: str):
    return get_firestore_client().collection("users").document(uid).collection("transactions")


def list_transactions(uid: str) -> list[TransactionOut]:
    # Single-field order_by needs no composite index, and matches
    # orderBy('date', descending: true) in firestore_repository.dart exactly
    # - ISO-8601 strings sort correctly as plain text.
    query = _collection(uid).order_by("date", direction=admin_firestore.Query.DESCENDING)
    return [TransactionOut(id=doc.id, **doc.to_dict()) for doc in query.stream()]


def create_transaction(uid: str, data: TransactionCreate) -> TransactionOut:
    doc_ref = _collection(uid).document()
    doc_ref.set(data.model_dump())
    return TransactionOut(id=doc_ref.id, **data.model_dump())


def update_transaction(uid: str, transaction_id: str, data: TransactionUpdate) -> Optional[TransactionOut]:
    doc_ref = _collection(uid).document(transaction_id)
    if not doc_ref.get().exists:
        return None
    doc_ref.update(data.model_dump())
    return TransactionOut(id=transaction_id, **data.model_dump())


def delete_transaction(uid: str, transaction_id: str) -> bool:
    doc_ref = _collection(uid).document(transaction_id)
    if not doc_ref.get().exists:
        return False
    doc_ref.delete()
    return True
