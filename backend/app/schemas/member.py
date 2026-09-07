from uuid import UUID

from pydantic import BaseModel, EmailStr


class AddMemberRequest(BaseModel):
    email: EmailStr


class MemberResponse(BaseModel):
    id: UUID
    user_id: UUID
    name: str
    email: EmailStr
    role: str
    status: str