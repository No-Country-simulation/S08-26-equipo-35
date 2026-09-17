"""from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session 
from app.db.session import get_db
from app.schemas.groups import GroupCreate, GroupResponse # Ajusta según tus schemas
from app.services.groups import create_group_service, get_groups_service"""

from fastapi import APIRouter

router = APIRouter(prefix="/groups", tags=["Groups"])

#oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/login")



#-------------------------------------------------------------------------------------------------------------
"""from app.db.session import get_async_db   # --> Conexion a la db 
from sqlalchemy.ext.asyncio import AsyncSession"""

"""@router.post("/create", response_model=GroupResponse, status_code=201)
async def create_group(group_data:GroupCreate, db: AsyncSession=Depends(get_async_db), current_user:str=Depends(oauth2_scheme)):

    new_group= await create_group_service(db, group_data, current_user)
    return new_group"""

#=====================================================================================================================
"""@router.get("/list", response_model=GroupResponse, status_code=200)
async def list_groups(db: AsyncSession=Depends(get_db),   current_user: str=Depends(oauth2_scheme)):
	list_groups= get_groups_service(db, current_user)
	return list_groups"""


#=======================================================================================================================
"""from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_async_db
from uuid import UUID"""

#from app.services.groups import get_groupID_service
from app.schemas.groups import DetailGroupResponse
from uuid import UUID

"""@router.get("/detail/{id_group}", response_model=DetailGroupResponse, status_code=200)
async def group_detail( id_group:UUID, db: AsyncSession=Depends(get_async_db), current_user: str=Depends(oauth2_scheme)):
	detail_group= await get_groupID_service(db, id_group)
	return detail_group"""


#=============================================================================================================================
# --> Update Details Group
from app.schemas.groups import UpdateGroup, UpdateGroupResponse
from app.services.groups import update_group_service

"""@router.patch("/{id_group}", response_model=UpdateGroupResponse, status_code=200)
async def update_group(id_group:UUID, data_group:UpdateGroup, db:AsyncSession=Depends(get_async_db), current_user:str=Depends(oauth2_scheme)):
	group_update= await update_group_service(id_group, data_group, db)
	return group_update
"""

#-----------------------------------------------------------------------------------------------------------------------
"""@router.delete("/{id_group}", status_code=204)
async def delete_group(id_group:UUID, db:AsyncSession=Depends(get_async_db), current_user:str=Depends(oauth2_scheme)):
	group_delete= await delete_group_service(id_group, db)
	return group_delete"""



#===============================================================================================================================
#===============================================================================================================================
#SYNC 
#==============================================================================================================================
from sqlalchemy.orm import Session 
from fastapi import Depends
from app.db.session import get_db

from app.core.security import get_current_user
from app.schemas.groups import GroupCreate, GroupResponse
from app.schemas.groups import UpdateGroup, UpdateGroupResponse
from app.models.users import User
from app.services.groups import create_group_service

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