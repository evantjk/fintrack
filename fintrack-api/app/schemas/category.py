from typing import Literal

from pydantic import BaseModel

# Matches Category.type in fintrack-mobile/lib/models/category.dart
CategoryType = Literal["income", "expense", "both"]


class CategoryBase(BaseModel):
    name: str
    icon: str
    color_value: int
    type: CategoryType


class CategoryCreate(CategoryBase):
    pass


class CategoryUpdate(CategoryBase):
    pass


class CategoryOut(CategoryBase):
    id: str
