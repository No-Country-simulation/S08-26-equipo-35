# app/services/auth_service.py
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.users import User
from app.schemas.auth import UserRegister, UserLogin
from app.core.security import hash_password 
from sqlalchemy import select, update

def register_user_service(db: Session, user_data: UserRegister):
    # 1. Verificar si el email ya está registrado (Evita duplicados)
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="El correo electrónico ya está registrado"
        )

    # 2. Extraer la contraseña del objeto SecretStr y hashearla
    plain_password = user_data.password.get_secret_value()
    hashed_password = hash_password(plain_password)

    # 3. Crear la instancia del modelo User
    new_user = User(
        name=user_data.name,
        email=user_data.email,
        password_hash=hashed_password
    )

    # 4. Guardar en la base de datos
    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user) # Recarga el objeto para obtener el ID generado
        return new_user
    except Exception as e:
        db.rollback() # Si algo falla, deshace los cambios para no dejar basura
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
            detail=f"Error al registrar el usuario: {str(e)}"
        )



#========================================================================================================================================
#========================================================================================================================================
from app.models.users import User

from app.core.security import  verify_password
from datetime import timedelta


def login_user_service(db: Session, email: str, password: str):
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=400, detail="Credenciales incorrectas")
    
    return user



#------------------------------------------------------------------------------------------------------------
def change_password_service(db: Session, data, current_user):
    # 1. Verificar contraseña anterior
    if not verify_password(data.old_password.get_secret_value(), current_user.password_hash):
        raise HTTPException(status_code=400, detail="Contraseña actual incorrecta")

    # 2. Hashear la nueva contraseña
    hashed_password = hash_password(data.new_password.get_secret_value())

    # 3. Actualizar en DB
    stmt = update(User).where(User.user_id == current_user.user_id).values(password_hash=hashed_password)
    db.execute(stmt)
    db.commit()

    # 4. Recargar el usuario para devolverlo
    result = db.execute(select(User).where(User.user_id == current_user.user_id))
    user_db = result.scalars().first()

    return user_db

