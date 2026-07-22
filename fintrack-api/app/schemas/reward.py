from typing import Literal, Optional

from pydantic import BaseModel

ThemeId = Literal["original", "gundam", "helloKitty", "luxury"]
CheckInStatus = Literal["success", "already_checked_in"]


class RewardProfileOut(BaseModel):
    total_xp: int
    spent_xp: int
    check_in_count: int
    last_earned_xp: int
    last_check_in_date: Optional[str] = None
    owned_themes: list[ThemeId]
    active_theme: ThemeId


class ThemeRequest(BaseModel):
    theme: ThemeId


class CheckInOut(BaseModel):
    status: CheckInStatus
    profile: RewardProfileOut
