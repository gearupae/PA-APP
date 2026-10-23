from datetime import datetime, timedelta, timezone
from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db.models import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer(auto_error=False)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    email: str = ""
    name: str = ""


class UserRegister(BaseModel):
    email: str
    password: str
    name: str = ""


class UserLogin(BaseModel):
    email: str
    password: str


def create_access_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    return jwt.encode(
        {"sub": subject, "exp": expire},
        settings.secret_key,
        algorithm=settings.jwt_algorithm,
    )


def _norm(email: str) -> str:
    email = email.strip().lower()
    if "@" not in email or "." not in email.split("@")[-1]:
        raise HTTPException(status_code=400, detail="Invalid email address")
    return email


async def register_user(body: UserRegister, db: AsyncSession) -> TokenResponse:
    email = _norm(body.email)
    if len(body.password) < 6:
        raise HTTPException(
            status_code=400, detail="Password must be at least 6 characters"
        )
    existing = await db.scalar(select(User).where(User.email == email))
    if existing is not None:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = User(
        email=email,
        name=body.name.strip(),
        hashed_password=pwd_context.hash(body.password),
    )
    db.add(user)
    await db.commit()
    return TokenResponse(
        access_token=create_access_token(email), email=email, name=user.name
    )


async def login_user(body: UserLogin, db: AsyncSession) -> TokenResponse:
    email = _norm(body.email)
    user = await db.scalar(select(User).where(User.email == email))
    if user is None or not pwd_context.verify(body.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    return TokenResponse(
        access_token=create_access_token(email), email=email, name=user.name
    )


async def get_current_user(
    creds: Annotated[HTTPAuthorizationCredentials | None, Depends(security)],
) -> str:
    if creds is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(
            creds.credentials,
            settings.secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        sub = payload.get("sub")
        if not sub:
            raise HTTPException(status_code=401, detail="Invalid token")
        return str(sub)
    except JWTError as exc:
        raise HTTPException(status_code=401, detail="Invalid token") from exc
