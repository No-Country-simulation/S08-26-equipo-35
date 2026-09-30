from fastapi import APIRouter

router = APIRouter()


from uuid import UUID
from sqlalchemy.orm import Session 
from fastapi import Depends
from app.db.session import get_db

from app.core.security import get_current_user
from app.schemas.groups import GroupCreate, GroupResponse
from app.schemas.groups import UpdateGroup, UpdateGroupResponse
from app.schemas.groups import DetailGroupResponse
from app.schemas.groups import AddGroupMemberRequest, GroupMemberResponse, RemoveGroupMemberResponse

from app.models.users import User
from app.services.groups import create_group_service
from app.services.groups import update_group_service



@router.post("/groups/create", response_model=GroupResponse, status_code=201)
def create_group(
    group_data: GroupCreate,
    current_user: User = Depends(get_current_user),  
    db: Session = Depends(get_db)
):
    return create_group_service(db, group_data, current_user)


#------------------------------------------------------------------------------------------------------------------------------
from app.services.groups import get_groups_service

@router.get("/groups/list", response_model=list[GroupResponse], status_code=200)
def list_groups(
	db:Session=Depends(get_db),
	current_user: User=Depends(get_current_user)
	):

	list_groups= get_groups_service(db, current_user)
	return list_groups



#------------------------------------------------------------------------------------------------------------------------
from app.services.groups import get_detailGroup_service

@router.get("/groups/detail/{id_group}", response_model=DetailGroupResponse, status_code=200)
def group_detail(
	id_group:UUID,
	db: Session=Depends(get_db),
	current_user: User=Depends(get_current_user)
	):

	detail_group= get_detailGroup_service(db, id_group, current_user)
	return detail_group



#----------------------------------------------------------------------------------------------------------------------------
from app.services.groups import update_group_service

@router.patch("/groups/{id_group}", response_model=UpdateGroupResponse, status_code=200)
def update_group(
	id_group:UUID,
	data_group:UpdateGroup,
	db:Session=Depends(get_db),
	current_user:User=Depends(get_current_user)
	):


	group_update= update_group_service(id_group, data_group, db, current_user)
	return group_update


#----------------------------------------------------------------------------------------------------------------------------
from app.services.groups import delete_group_service

@router.delete("/groups/{id_group}", status_code=204)
def delete_group(id_group:UUID, db:Session=Depends(get_db), current_user:User=Depends(get_current_user)):
	group_delete= delete_group_service(id_group, db, current_user)
	return group_delete


#----------------------------------------------------------------------------------------------------------------------------
# Members CRUD — solo el creador puede agregar/remover, cualquier miembro puede listar
from app.services.groups import add_group_member_service, list_group_members_service, remove_group_member_service

@router.post("/groups/{id_group}/members", response_model=GroupMemberResponse, status_code=201)
def add_group_member(
	id_group:UUID,
	payload:AddGroupMemberRequest,
	db:Session=Depends(get_db),
	current_user:User=Depends(get_current_user)
	):
	return add_group_member_service(db, id_group, payload, current_user)


@router.get("/groups/{id_group}/members", response_model=list[GroupMemberResponse], status_code=200)
def list_group_members(
	id_group:UUID,
	db:Session=Depends(get_db),
	current_user:User=Depends(get_current_user)
	):
	return list_group_members_service(db, id_group, current_user)


@router.delete("/groups/{id_group}/members/{user_id}", response_model=RemoveGroupMemberResponse, status_code=200)
def remove_group_member(
	id_group:UUID,
	user_id:UUID,
	db:Session=Depends(get_db),
	current_user:User=Depends(get_current_user)
	):
	return remove_group_member_service(db, id_group, user_id, current_user)