from fastapi import APIRouter, Depends, HTTPException, status

from sqlalchemy.orm import Session

from app.services.users import profile_service, update_service, delete_user_service
from app.db.session import get_db
from app.core.security import get_current_user
from app.schemas.users import ResponseProfile, UpdateUser, MessageResponse 
from app.models.users import User


router= APIRouter()


@router.get("/me", response_model=ResponseProfile, status_code=status.HTTP_200_OK)
def profile(
	db:Session= Depends(get_db), 
	curret_user=Depends(get_current_user)
	):

	return profile_service(db, curret_user)


#-------------------------------------------------------------------------------------------------
@router.patch("/me", response_model=ResponseProfile, status_code=status.HTTP_200_OK)
def profile_update(
	data: UpdateUser,
	db: Session= Depends(get_db),
	curret_user= Depends(get_current_user)
	):

	return update_service(db, data, curret_user)



#----------------------------------------------------------------------------------------------------
@router.delete("/me", status_code=status.HTTP_200_OK, response_model=MessageResponse)
def delete_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return delete_user_service(db, current_user)