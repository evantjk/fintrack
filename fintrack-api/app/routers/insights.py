from fastapi import APIRouter, Depends

from ..auth import get_current_uid
from ..schemas.insights import InsightsResponse
from ..services import category_service, insights_service, transaction_service

router = APIRouter(prefix="/insights", tags=["insights"])


@router.get("", response_model=InsightsResponse)
def get_insights(uid: str = Depends(get_current_uid)):
    transactions = transaction_service.list_transactions(uid)
    categories = category_service.list_categories(uid)
    return insights_service.build_insights(transactions, categories)
