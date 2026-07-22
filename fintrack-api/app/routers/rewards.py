from fastapi import APIRouter, Depends, HTTPException, status

from ..auth import get_current_uid
from ..schemas.reward import CheckInOut, RewardProfileOut, ThemeRequest
from ..services import reward_service

router = APIRouter(prefix="/rewards", tags=["rewards"])


@router.get("", response_model=RewardProfileOut)
def get_rewards(uid: str = Depends(get_current_uid)):
    return reward_service.get_profile(uid)


@router.post("/check-in", response_model=CheckInOut)
def check_in(uid: str = Depends(get_current_uid)):
    return reward_service.check_in(uid)


@router.post("/unlock-theme", response_model=RewardProfileOut)
def unlock_theme(data: ThemeRequest, uid: str = Depends(get_current_uid)):
    result = reward_service.unlock_theme(uid, data.theme)
    if result is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Not enough XP")
    return result


@router.post("/apply-theme", response_model=RewardProfileOut)
def apply_theme(data: ThemeRequest, uid: str = Depends(get_current_uid)):
    result = reward_service.apply_theme(uid, data.theme)
    if result is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Theme is not unlocked")
    return result
