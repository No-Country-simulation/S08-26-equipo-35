# app/api/v1/auth.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.schemas.auth import UserRegister, UserResponse # Esquemas separados
from app.schemas.auth import UserLogin, LoginResponse
from app.services.auth_service import register_user_service
from app.services.auth_service import login_user_service
from app.core.security import create_access_token
from app.core.config import settings

router = APIRouter()

#======================================================================================================================================
@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    try:
        # Delegamos toda la lógica al servicio
        new_user = register_user_service(db, user_data)
        return new_user
    except ValueError as e:
        # Si el servicio dice que el email ya existe
        raise HTTPException(status_code=400, detail=str(e))


#=======================================================================================================================================
@router.post("/login", response_model=LoginResponse, status_code=status.HTTP_200_OK)
def login(user_data: UserLogin, db: Session = Depends(get_db)):

    user = login_user_service(db, user_data.email, user_data.password)

    access_token = create_access_token(data={"sub": user.email})

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60 # O el tiempo que hayas definido en la .env
    }