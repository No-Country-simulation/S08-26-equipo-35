from fastapi import APIRouter, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import select, update, delete

from app.models.users import User
from app.schemas.users import UpdateUser



def profile_service(db:Session, current_user):
	user_id = current_user.user_id
	query = select(User).where(User.user_id == user_id)
	result = db.execute(query)
	user_db = result.scalars().first()

	if not user_db:
		raise HTTPException(status_code=404, detail="User Not Found")

	return user_db


#--------------------------------------------------------------------------------------------
def update_service(db:Session, user_data:UpdateUser, current_user):
	id_user = current_user.user_id

	data= user_data.model_dump(exclude_unset=True)

	if not data:
		raise HTTPException(status_code=422, detail="Not received data")

	result= db.execute(update(User).where(User.user_id == id_user).values(**data))
	db.commit()

	# Devolver data 
	result= db.execute(select(User).where(User.user_id == id_user))
	user_db = result.scalars().first()

	if not user_db:
		raise HTTPException(status_code=404, detail="User Not Found")

	return user_db



#--------------------------------------------------------------------------------------------
def delete_user_service(db: Session, current_user):
    id_user = current_user.user_id

    # Verificamos que exista antes de borrar (buena práctica)
    stmt_select = select(User).where(User.user_id == id_user)
    result = db.execute(stmt_select)
    user_db = result.scalars().first()

    if not user_db:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    # Ejecutamos el borrado
    stmt_delete = delete(User).where(User.user_id == id_user)
    db.execute(stmt_delete)
    db.commit()

    return {"message": "Usuario eliminado correctamente"}