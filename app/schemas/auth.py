from pydantic import BaseModel, EmailStr, SecretStr, field_validator
from datetime import datetime
from app.core.security import validate_password

class UserRegister(BaseModel):
	name:str
	email: EmailStr
	password: SecretStr

	@field_validator("password")
	@classmethod

	def validator_password(cls, v: SecretStr) -> SecretStr:
		password = v.get_secret_value()
		validate_password(password)
		return v



class UserResponse(BaseModel):
	email: EmailStr 
	created_at: datetime



#================================================================================================================
#================================================================================================================
class UserLogin(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
	access_token: str
	token_type: str = "bearer"
	expires_in: int
#    user: Optional[UserPublic] = None   # Opcional, pero muy útil para Flutter


#-----------------------------------------------------------
class ChangePassword(BaseModel):
    old_password: SecretStr      # Para verificar identidad
    new_password: SecretStr      # La nueva en texto plano

    @field_validator("new_password")
    @classmethod
    def validator_password(cls, v: SecretStr) -> SecretStr:
        password = v.get_secret_value()
        validate_password(password)  # Tu función de validación existente
        return v


# app/schemas/auth.py
class MessageResponse(BaseModel):
    message: str

