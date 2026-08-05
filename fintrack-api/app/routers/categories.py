from fastapi import APIRouter, Depends, HTTPException, status

from ..auth import get_current_uid
from ..schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from ..services import category_service

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(uid: str = Depends(get_current_uid)):
    return category_service.list_categories(uid)


@router.post("/seed", response_model=list[CategoryOut])
def seed_categories(uid: str = Depends(get_current_uid)):
    """Explicit, idempotent re-trigger of the same seeding GET /categories
    already does transparently - exists mainly so it's easy to call
    deliberately from Swagger while testing."""
    category_service.ensure_seeded(uid)
    return category_service.list_categories(uid)


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(data: CategoryCreate, uid: str = Depends(get_current_uid)):
    return category_service.create_category(uid, data)


@router.put("/{category_id}", response_model=CategoryOut)
def update_category(category_id: str, data: CategoryUpdate, uid: str = Depends(get_current_uid)):
    result = category_service.update_category(uid, category_id, data)
    if result is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    return result


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(category_id: str, uid: str = Depends(get_current_uid)):
    if not category_service.delete_category(uid, category_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
