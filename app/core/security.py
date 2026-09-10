#==========================================================================================================
#--> REGLAS FILTRO PARA REGISTRAR PASSWORD
import re
from passlib.context import CryptContext

def validate_password(password):
	if len(password)  < 8:
		raise ValueError ("Debe contener 8 elementos como mínimo")

	if not re.search(r'[A-Z]', password):
		raise ValueError("Debe tener minimo una MAYUSCULA")

	if not re.search(r'[a-z]', password):
		raise ValueError ("Debe tener minimo una minúscula")

	if not re.search(r'\d', password):
		raise ValueError ("Debe tener minimo un número")

	if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
		raise ValueError ("Debe tener minimo un caracter especial")

	return password

#=================================================================================================================
#=================================================================================================================
#---> HASH PASSWORD,  VERIFY PASSWORD 

pwd_context = CryptContext(schemes=["bcrypt"], deprecated= "auto")

def hash_password(password:str):
	return pwd_context.hash(password)



#=====================================================================================================================
#=====================================================================================================================
# --> IMPLEMENT JWT AUTHENTICATION
from passlib.context import CryptContext
from datetime import datetime, timedelta
from typing import Optional
from jose import jwt, JWTError
from app.core.config import settings


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)   #--> Tiempo q se establece en .env
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm= settings.ALGORITHM)
    return encoded_jwt