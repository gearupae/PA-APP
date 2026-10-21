from datetime import datetime, timezone
from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.auth import get_current_user

router = APIRouter(prefix="/todos", tags=["todos"])

_todos: dict[str, dict] = {}


class TodoCreate(BaseModel):
    title: str = Field(min_length=1, max_length=500)
    due_at: datetime | None = None


class TodoUpdate(BaseModel):
    title: str | None = None
    completed: bool | None = None
    due_at: datetime | None = None


class TodoOut(BaseModel):
    id: str
    title: str
    completed: bool
    due_at: datetime | None
    created_at: datetime


def _user_todos(user: str) -> list[dict]:
    return [t for t in _todos.values() if t["user_id"] == user]


@router.get("", response_model=list[TodoOut])
async def list_todos(user: Annotated[str, Depends(get_current_user)]):
    return _user_todos(user)


@router.post("", response_model=TodoOut, status_code=201)
async def create_todo(
    body: TodoCreate, user: Annotated[str, Depends(get_current_user)]
):
    tid = str(uuid4())
    row = {
        "id": tid,
        "user_id": user,
        "title": body.title,
        "completed": False,
        "due_at": body.due_at,
        "created_at": datetime.now(timezone.utc),
    }
    _todos[tid] = row
    return row


@router.patch("/{todo_id}", response_model=TodoOut)
async def update_todo(
    todo_id: str,
    body: TodoUpdate,
    user: Annotated[str, Depends(get_current_user)],
):
    row = _todos.get(todo_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Todo not found")
    if body.title is not None:
        row["title"] = body.title
    if body.completed is not None:
        row["completed"] = body.completed
    if body.due_at is not None:
        row["due_at"] = body.due_at
    return row


@router.delete("/{todo_id}", status_code=204)
async def delete_todo(
    todo_id: str, user: Annotated[str, Depends(get_current_user)]
):
    row = _todos.get(todo_id)
    if not row or row["user_id"] != user:
        raise HTTPException(status_code=404, detail="Todo not found")
    del _todos[todo_id]
