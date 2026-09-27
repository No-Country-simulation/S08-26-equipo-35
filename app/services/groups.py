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
	db.flush()  # Obtiene group_id sin cerrar la transacción
	db.add(GroupMember(group_id=new_group.group_id, user_id=user))
	db.commit()
	db.refresh(new_group)      # Para refrescar y obtener el uuid
	return new_group


#--------------------------------------------------------------------------------------------------------------------------------
def get_groups_service(db:Session, current_user:User):
	id_user= current_user.user_id

	#Buscar memberships del user (lista vacía si no tiene grupos -> 200 [])
	stm= select(GroupMember).where(GroupMember.user_id == id_user)
	result= db.execute(stm).scalars().all()

	return [membership.group for membership in result]


# Helpers de autorización (mismo criterio que expenses/settlements: 403 si no es miembro)
def _get_group_or_404(db:Session, id_group:UUID):
	group= db.execute(select(Group).where(Group.group_id == id_group)).scalar_one_or_none()
	if not group:
		raise HTTPException(status_code=404, detail="Group Not Found")
	return group


def _require_member(db:Session, id_group:UUID, user_id:UUID):
	member= db.execute(
		select(GroupMember).where(
			GroupMember.group_id == id_group,
			GroupMember.user_id == user_id
		)
	).scalar_one_or_none()
	if not member:
		raise HTTPException(status_code=403, detail="El usuario no pertenece al grupo")


#-----------------------------------------------------------------------------------------------------------------------------------
def get_detailGroup_service(db:Session, id_group:UUID, current_user:User):
	groups= _get_group_or_404(db, id_group)
	_require_member(db, id_group, current_user.user_id)

	return groups



#------------------------------------------------------------------------------------------------------------------------------------
def update_group_service(id_group:UUID, data_group:UpdateGroup, db:Session, current_user:User):
	data= data_group.model_dump(exclude_unset=True)

	if not data:
		raise HTTPException(status_code=422, detail="Not received data")

	group= _get_group_or_404(db, id_group)
	_require_member(db, id_group, current_user.user_id)

	db.execute(update(Group).where(Group.group_id == id_group).values(**data))
	db.commit()

	# Devolver data
	select_stm= db.execute(select(Group).where(Group.group_id == id_group))
	group_updated= select_stm.scalar_one_or_none()

	if not group_updated:
		raise HTTPException(status_code=404, detail="Group Not Found")

	return group_updated



#----------------------------------------------------------------------------------------------------------------------------------
def delete_group_service(id_group:UUID, db:Session, current_user:User):
	group= _get_group_or_404(db, id_group)

	if group.created_by_user_id != current_user.user_id:
		raise HTTPException(status_code=403, detail="Solo el creador puede eliminar el grupo")

	stm= delete(Group).where(Group.group_id == id_group)
	result= db.execute(stm)
	db.commit()

	if result.rowcount == 0:
		raise HTTPException(status_code=404, detail="El grupo no existe o ya fue eliminado")

	return Response(status_code=204)
