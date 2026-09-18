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

from app.models.users import User
from app.services.groups import create_group_service
from app.services.groups import update_group_service



@router.post("/create", response_model=GroupResponse, status_code=201)
def create_group(
    group_data: GroupCreate,
    current_user: User = Depends(get_current_user),  
    db: Session = Depends(get_db)
):
    return create_group_service(db, group_data, current_user)


#------------------------------------------------------------------------------------------------------------------------------
from app.services.groups import get_groups_service

@router.get("/list", response_model=list[GroupResponse], status_code=200)
def list_groups(
	db:Session=Depends(get_db),
	current_user: User=Depends(get_current_user)
	):

	list_groups= get_groups_service(db, current_user)
	return list_groups



#------------------------------------------------------------------------------------------------------------------------
from app.services.groups import get_detailGroup_service

@router.get("/detail/{id_group}", response_model=DetailGroupResponse, status_code=200)
def group_detail(
	id_group:UUID,
	db: Session=Depends(get_db),
	current_user: User=Depends(get_current_user)
	):

	detail_group= get_detailGroup_service(db, id_group)
	return detail_group



#----------------------------------------------------------------------------------------------------------------------------
from app.services.groups import update_group_service

@router.patch("/{id_group}", response_model=UpdateGroupResponse, status_code=200)
def update_group(
	id_group:UUID,
	data_group:UpdateGroup,
	db:Session=Depends(get_db),
	current_user:str=Depends(get_current_user)
	):


	group_update= update_group_service(id_group, data_group, db)
	return group_update


#----------------------------------------------------------------------------------------------------------------------------
from app.services.groups import delete_group_service

@router.delete("/{id_group}", status_code=204)
def delete_group(id_group:UUID, db:Session=Depends(get_db), current_user:User=Depends(get_current_user)):
	group_delete= delete_group_service(id_group, db)
	return group_delete