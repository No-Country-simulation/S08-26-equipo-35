from pydantic import BaseModel
from uuid import UUID



class ResponseProfile(BaseModel):
	user_id: UUID
	name: str
	email: str


class UpdateUser(BaseModel):
	name: str | None = None
	email: str | None = None


   

# app/schemas/users.py
class MessageResponse(BaseModel):
    message: str