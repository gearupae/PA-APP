from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import (
    TokenResponse,
    UserLogin,
    UserRegister,
    login_user,
    register_user,
)
from app.db.session import get_db

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse)
async def register(
    body: UserRegister,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    return await register_user(body, db)


@router.post("/login", response_model=TokenResponse)
async def login(
    body: UserLogin,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    return await login_user(body, db)
