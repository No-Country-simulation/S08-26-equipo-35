from sqlalchemy import select, update, delete, func
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from uuid import UUID
from fastapi import HTTPException, Depends
from fastapi import Response

from app.core.security import get_current_user
from app.schemas.groups import GroupCreate
from app.schemas.groups import UpdateGroup
from app.schemas.groups import AddGroupMemberRequest

from app.models.users import User
from app.models.group_members import GroupMember
from app.models.groups import Group, GroupStatus

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


def _require_creator(db:Session, group:Group, user_id:UUID):
	if group.created_by_user_id != user_id:
		raise HTTPException(status_code=403, detail="Solo el creador puede gestionar los miembros")


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


#==================================================================================================================================
# Members CRUD
#==================================================================================================================================

def _resolve_user_for_member(db:Session, payload:AddGroupMemberRequest) -> User:
	user = None
	if payload.user_id is not None:
		user = db.execute(select(User).where(User.user_id == payload.user_id)).scalar_one_or_none()
	else:
		email = (payload.email or "").strip().lower()
		user = db.execute(
			select(User).where(func.lower(User.email) == email)
		).scalar_one_or_none()
	if not user:
		raise HTTPException(status_code=404, detail="Usuario no encontrado")
	return user


def add_group_member_service(db:Session, id_group:UUID, payload:AddGroupMemberRequest, current_user:User):
	group = _get_group_or_404(db, id_group)
	_require_creator(db, group, current_user.user_id)

	if group.status == GroupStatus.SETTLED:
		raise HTTPException(status_code=400, detail="No se pueden agregar miembros a un grupo liquidado")

	user = _resolve_user_for_member(db, payload)

	existing = db.execute(
		select(GroupMember).where(
			GroupMember.group_id == id_group,
			GroupMember.user_id == user.user_id
		)
	).scalar_one_or_none()
	if existing:
		raise HTTPException(status_code=409, detail="El usuario ya es miembro del grupo")

	try:
		member = GroupMember(group_id=id_group, user_id=user.user_id)
		db.add(member)
		db.commit()
		db.refresh(member)
		return member
	except IntegrityError:
		db.rollback()
		raise HTTPException(status_code=409, detail="El usuario ya es miembro del grupo")


def list_group_members_service(db:Session, id_group:UUID, current_user:User):
	_get_group_or_404(db, id_group)
	_require_member(db, id_group, current_user.user_id)

	result = db.execute(
		select(GroupMember).where(GroupMember.group_id == id_group).order_by(GroupMember.joined_at.asc())
	).scalars().all()
	return result


def remove_group_member_service(db:Session, id_group:UUID, user_id:UUID, current_user:User):
	group = _get_group_or_404(db, id_group)
	_require_creator(db, group, current_user.user_id)

	if user_id == group.created_by_user_id:
		raise HTTPException(status_code=400, detail="No se puede eliminar al creador del grupo")

	member = db.execute(
		select(GroupMember).where(
			GroupMember.group_id == id_group,
			GroupMember.user_id == user_id
		)
	).scalar_one_or_none()
	if not member:
		raise HTTPException(status_code=404, detail="El usuario no es miembro del grupo")

	db.delete(member)
	db.commit()
	return {"message": "Miembro eliminado correctamente"}
