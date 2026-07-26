from typing import Optional

from ..firebase_client import get_firestore_client
from ..schemas.category import CategoryCreate, CategoryOut, CategoryUpdate

# Copied verbatim from fintrack-mobile/lib/services/default_categories.dart
# so both clients seed identical starter categories for a new user.
DEFAULT_CATEGORIES = [
    {"name": "Salary", "icon": "💼", "color_value": 0xFF2E7D32, "type": "income"},
    {"name": "Freelance", "icon": "💻", "color_value": 0xFF1565C0, "type": "income"},
    {"name": "Investment", "icon": "📈", "color_value": 0xFF6A1B9A, "type": "income"},
    {"name": "Gift", "icon": "🎁", "color_value": 0xFFFF8F00, "type": "income"},
    {"name": "Food", "icon": "🍔", "color_value": 0xFF43A047, "type": "expense"},
    {"name": "Transport", "icon": "🚗", "color_value": 0xFFFDD835, "type": "expense"},
    {"name": "Shopping", "icon": "🛍️", "color_value": 0xFFEC407A, "type": "expense"},
    {"name": "Bills", "icon": "📄", "color_value": 0xFF5D4037, "type": "expense"},
    {"name": "Health", "icon": "💊", "color_value": 0xFF00ACC1, "type": "expense"},
    {"name": "Entertainment", "icon": "🎬", "color_value": 0xFFFF5722, "type": "expense"},
    {"name": "Education", "icon": "📚", "color_value": 0xFF283593, "type": "expense"},
    {"name": "Other", "icon": "📦", "color_value": 0xFF7E57C2, "type": "expense"},
]


def _collection(uid: str):
    return get_firestore_client().collection("users").document(uid).collection("categories")


def ensure_seeded(uid: str) -> None:
    """No-op if the user already has at least one category; otherwise writes
    the 12 defaults in a single batch. Mirrors FirestoreRepository.ensureSeeded()."""
    coll = _collection(uid)
    if list(coll.limit(1).stream()):
        return
    batch = get_firestore_client().batch()
    for cat in DEFAULT_CATEGORIES:
        batch.set(coll.document(), cat)
    batch.commit()


def list_categories(uid: str) -> list[CategoryOut]:
    ensure_seeded(uid)
    categories = [CategoryOut(id=doc.id, **doc.to_dict()) for doc in _collection(uid).stream()]
    # Same ordering as compareCategories() in finance_repository.dart: type
    # descending, then name ascending, plain string comparison (not a
    # hardcoded income-first list, in case a "both" type shows up). Two
    # stable sorts achieve a primary-desc/secondary-asc compound sort.
    categories.sort(key=lambda c: c.name)
    categories.sort(key=lambda c: c.type, reverse=True)
    return categories


def create_category(uid: str, data: CategoryCreate) -> CategoryOut:
    doc_ref = _collection(uid).document()
    doc_ref.set(data.model_dump())
    return CategoryOut(id=doc_ref.id, **data.model_dump())


def update_category(uid: str, category_id: str, data: CategoryUpdate) -> Optional[CategoryOut]:
    doc_ref = _collection(uid).document(category_id)
    if not doc_ref.get().exists:
        return None
    doc_ref.update(data.model_dump())
    return CategoryOut(id=category_id, **data.model_dump())


def delete_category(uid: str, category_id: str) -> bool:
    doc_ref = _collection(uid).document(category_id)
    if not doc_ref.get().exists:
        return False
    doc_ref.delete()
    return True
