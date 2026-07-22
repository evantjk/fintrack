from fastapi import APIRouter, Depends, HTTPException, status

from ..auth import get_current_uid
from ..schemas.transaction import TransactionCreate, TransactionOut, TransactionUpdate
from ..services import transaction_service

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("", response_model=list[TransactionOut])
def list_transactions(uid: str = Depends(get_current_uid)):
    return transaction_service.list_transactions(uid)


@router.post("", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def create_transaction(data: TransactionCreate, uid: str = Depends(get_current_uid)):
    return transaction_service.create_transaction(uid, data)


@router.put("/{transaction_id}", response_model=TransactionOut)
def update_transaction(transaction_id: str, data: TransactionUpdate, uid: str = Depends(get_current_uid)):
    result = transaction_service.update_transaction(uid, transaction_id, data)
    if result is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transaction not found")
    return result


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(transaction_id: str, uid: str = Depends(get_current_uid)):
    if not transaction_service.delete_transaction(uid, transaction_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transaction not found")
