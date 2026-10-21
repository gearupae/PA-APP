from fastapi import APIRouter

from app.auth import UserLogin, UserRegister, login_user, register_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register")
async def register(body: UserRegister):
    return register_user(body)


@router.post("/login")
async def login(body: UserLogin):
    return login_user(body)
