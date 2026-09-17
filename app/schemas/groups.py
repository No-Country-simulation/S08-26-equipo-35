from pydantic import BaseModel, field_validator, ConfigDict
from uuid import UUID
from datetime import datetime

from app.models.groups import GroupStatus

class GroupCreate(BaseModel):
	name: str

	@field_validator("name")
	@classmethod
	def name_NotEmpty(cls, v: str) -> str:
		v = v.strip()
		if not v:
			raise ValueError("The name is empty ")
		if len(v) > 100:
			raise ValueError("the name is not must be 100 character long more")
		return v

#-------------------------------------------------------------------------------------------------
class GroupResponse(BaseModel):
	group_id: UUID
	group_name: str
	created_at: datetime
	created_by_user_id: UUID # El user creator tiene UUID

	model_config = ConfigDict(from_attributes=True, populate_by_name=True)


#==================================================================================================
class GroupMemberResponse(BaseModel):
	user_id: UUID
	joined_at: datetime

	model_config = ConfigDict(from_attributes=True)

class DetailGroupResponse(BaseModel):
	group_id: UUID
	group_name: str
	status: GroupStatus
	created_at: datetime
	members: list[GroupMemberResponse]  #--> Se anida la lista de users en el grupo 

	model_config = ConfigDict(from_attributes=True)


#----------------------------------------------------------------------------------------------------------

class UpdateGroup(BaseModel):
	group_name: str | None=None
	status: GroupStatus | None=None


class UpdateGroupResponse(BaseModel):
	group_name: str | None=None
	status: GroupStatus | None=None