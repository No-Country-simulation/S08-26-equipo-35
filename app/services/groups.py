"""from sqlalchemy import select, update
from sqlalchemy.orm import Session
from fastapi import HTTPException
from uuid import UUID

from app.schemas.groups import GroupCreate
from app.models.groups import Group
from app.models.group_members import GroupMember



#--------------------------------------------------------------------------------------------------------------------
from app.db.session import get_async_db   # --> Conexion a la db 
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import get_current_userId
from uuid import UUID"""

"""async def create_group_service(db:AsyncSession ,group_data:GroupCreate, current_user:str):
	user_id= get_current_userId(current_user)
	new_group= Group(
		name=group_data.name,
		created_by_user_id=user_id
		)
	db.add(new_group)
	await db.commit()
	await db.refresh(new_group)      # Para refrescar y obtener el uuid
	return new_group

"""
#------------------------------------------------------------------------------------------------------------------------
"""async def get_groups_service(db: AsyncSession, accesss_token:str):
	user_id= get_current_userId(accesss_token)

	#Buscar user en db
	stm= select(GroupMember).where(GroupMember.user_id == user_id)
	result= await db.execute(stm).scalars().all()
	if result is None:
		raise HTTPException(status_code=404, detail="User Not Found")

	#Return data
	return result
"""

#------------------------------------------------------------------------------------------------------------------------
"""async def get_groupID_service(db: AsyncSession, id_group:UUID ):
	result= await db.execute(select(Group).where(Group.group_id == id_group))
	groups= result.scalar_one_or_none()
	if not groups:
		raise HTTPException(status_code=404, detail="Group Not Found") 

	return groups"""


#---------------------------------------------------------------------------------------------------------------------------
from app.schemas.groups import UpdateGroup

"""async def update_group_service(id_group: UUID, data_group:UpdateGroup, db: AsyncSession):
	data= data_group.model_dump(exclude_unset=True)

	if not data:
		raise HTTPException(status_code=422, detail="Not received data")

	result= await db.execute(update(Group).where(Group.group_id == id_group).values(**data))
	await db.commit()

	# Devolver data 
	select_stm= await db.execute(select(Group).where(Group.group_id == id_group))
	group_updated= select_stm.scalar_one()
	return group_updated"""



#----------------------------------------------------------------------------------------------------------------------------
from fastapi import Response

"""async def delete_group_service(id_group:UUID, db:AsyncSession):
	stm= delete(Group).where(Group.group_id == id_group)
	result= await db.execute(stm)
	await db.commit()

	if result.rowcount == 0:
		raise HTTPException(status_code=404, detail="El grupo no existe o ya fue eliminado")

	return Response(status_code=204)"""


#================================================================================================================================
#================================================================================================================================
#SYNC
#=================================================================================================================================
from sqlalchemy import select, update, delete
from sqlalchemy.orm import Session
from uuid import UUID
from fastapi import HTTPException, Depends
from fastapi import Response

from app.core.security import get_current_user
from app.schemas.groups import GroupCreate
from app.schemas.groups import UpdateGroup

from app.models.users import User
from app.models.group_members import GroupMember
from app.models.groups import Group

#-------------------------------------------------------------------------------------------------------------------------------
def create_group_service(db:Session ,group_data:GroupCreate, current_user:User):
	      
	user= current_user.user_id
	
	new_group= Group(
		group_name=group_data.name,
		created_by_user_id=user
		)
	db.add(new_group)
	db.commit()
	db.refresh(new_group)      # Para refrescar y obtener el uuid
	return new_group


#--------------------------------------------------------------------------------------------------------------------------------
def get_groups_service(db:Session, current_user:User):
	id_user= current_user.user_id

	#Buscar user en db
	stm= select(GroupMember).where(GroupMember.user_id == id_user)
	result= db.execute(stm).scalars().all()
	if not result:
		raise HTTPException(status_code=404, detail="User Not Found")

	return [membership.group for membership in result]


#-----------------------------------------------------------------------------------------------------------------------------------
def get_detailGroup_service(db:Session, id_group:UUID ):
	result= db.execute(select(Group).where(Group.group_id == id_group))
	groups= result.scalar_one_or_none()
	if not groups:
		raise HTTPException(status_code=404, detail="Group Not Found") 

	return groups



#------------------------------------------------------------------------------------------------------------------------------------
def update_group_service(id_group:UUID, data_group:UpdateGroup, db:Session):
	data= data_group.model_dump(exclude_unset=True)

	if not data:
		raise HTTPException(status_code=422, detail="Not received data")

	result= db.execute(update(Group).where(Group.group_id == id_group).values(**data))
	db.commit()

	# Devolver data 
	select_stm= db.execute(select(Group).where(Group.group_id == id_group))
	group_updated= select_stm.scalar_one_or_none()

	if not group_updated:
		raise HTTPException(status_code=404, detail="Group Not Found")

	return group_updated



#----------------------------------------------------------------------------------------------------------------------------------
def delete_group_service(id_group:UUID, db:Session):
	stm= delete(Group).where(Group.group_id == id_group)
	result= db.execute(stm)
	db.commit()

	if result.rowcount == 0:
		raise HTTPException(status_code=404, detail="El grupo no existe o ya fue eliminado")

	return Response(status_code=204)
