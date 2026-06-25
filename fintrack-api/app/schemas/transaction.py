from typing import Literal, Optional

from pydantic import BaseModel

# Matches Transaction.type in fintrack-mobile/lib/models/transaction.dart
TransactionType = Literal["income", "expense"]


class TransactionBase(BaseModel):
    title: str
    amount: float
    # Kept as a plain ISO-8601 string end to end, never parsed to datetime.
    # The Dart side stores date.toIso8601String() and sorts on it
    # lexicographically (see firestore_repository.dart); reformatting here
    # could silently break that ordering guarantee.
    date: str
    category_id: str
    type: TransactionType
    note: Optional[str] = None


class TransactionCreate(TransactionBase):
    pass


class TransactionUpdate(TransactionBase):
    pass


class TransactionOut(TransactionBase):
    id: str
