from datetime import date
from typing import Any

from ..firebase_client import get_firestore_client
from ..schemas.reward import CheckInOut, RewardProfileOut, ThemeId

BASE_DAILY_REWARD_XP = 10
MAX_DAILY_REWARD_XP = 15

THEME_COSTS: dict[ThemeId, int] = {
    "original": 0,
    "gundam": 30,
    "luxury": 60,
    "helloKitty": 90,
}

DEFAULT_PROFILE: dict[str, Any] = {
    "total_xp": 0,
    "spent_xp": 0,
    "check_in_count": 0,
    "last_earned_xp": 0,
    "last_check_in_date": None,
    "owned_themes": ["original"],
    "active_theme": "original",
}


def _profile_ref(uid: str):
    return (
        get_firestore_client()
        .collection("users")
        .document(uid)
        .collection("rewards")
        .document("profile")
    )


def _reward_for_check_in_number(check_in_number: int) -> int:
    if check_in_number <= 0:
        return BASE_DAILY_REWARD_XP
    bonus = (check_in_number - 1) // 5
    return max(BASE_DAILY_REWARD_XP, min(BASE_DAILY_REWARD_XP + bonus, MAX_DAILY_REWARD_XP))


def _normalise(raw: dict[str, Any] | None) -> dict[str, Any]:
    profile = dict(DEFAULT_PROFILE)
    if raw:
        profile.update(raw)
    profile["total_xp"] = int(profile.get("total_xp") or 0)
    profile["spent_xp"] = int(profile.get("spent_xp") or 0)
    profile["check_in_count"] = int(profile.get("check_in_count") or 0)
    profile["last_earned_xp"] = int(profile.get("last_earned_xp") or 0)
    owned = profile.get("owned_themes") or ["original"]
    if "original" not in owned:
        owned = ["original", *owned]
    profile["owned_themes"] = owned
    if profile.get("active_theme") not in THEME_COSTS:
        profile["active_theme"] = "original"
    return profile


def _save(uid: str, profile: dict[str, Any]) -> RewardProfileOut:
    _profile_ref(uid).set(profile, merge=True)
    return RewardProfileOut(**profile)


def get_profile(uid: str) -> RewardProfileOut:
    ref = _profile_ref(uid)
    snap = ref.get()
    profile = _normalise(snap.to_dict() if snap.exists else None)
    if not snap.exists:
        ref.set(profile)
    return RewardProfileOut(**profile)


def check_in(uid: str) -> CheckInOut:
    ref = _profile_ref(uid)
    snap = ref.get()
    profile = _normalise(snap.to_dict() if snap.exists else None)
    today = date.today().isoformat()

    if profile["last_check_in_date"] == today:
        return CheckInOut(status="already_checked_in", profile=RewardProfileOut(**profile))

    earned = _reward_for_check_in_number(profile["check_in_count"] + 1)
    profile["total_xp"] += earned
    profile["last_earned_xp"] = earned
    profile["check_in_count"] += 1
    profile["last_check_in_date"] = today

    saved = _save(uid, profile)
    return CheckInOut(status="success", profile=saved)


def unlock_theme(uid: str, theme: ThemeId) -> RewardProfileOut | None:
    profile = get_profile(uid).model_dump()
    if theme in profile["owned_themes"]:
        profile["active_theme"] = theme
        return _save(uid, profile)

    cost = THEME_COSTS[theme]
    available = profile["total_xp"] - profile["spent_xp"]
    if available < cost:
        return None

    profile["spent_xp"] += cost
    profile["owned_themes"].append(theme)
    profile["active_theme"] = theme
    return _save(uid, profile)


def apply_theme(uid: str, theme: ThemeId) -> RewardProfileOut | None:
    profile = get_profile(uid).model_dump()
    if theme not in profile["owned_themes"]:
        return None
    profile["active_theme"] = theme
    return _save(uid, profile)
