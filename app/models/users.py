from sqlalchemy import Column, String, DateTime, UUID as SQL_UUID
from sqlalchemy.sql import func
import uuid
import enum
from sqlalchemy import Enum as SQLEnum
from app.db.base import Base


class PayoutMethod(str, enum.Enum):
    ALIAS = "alias"
    CBU = "cbu"
    CVU = "cvu"



class User(Base):
    __tablename__ = "users"
    
    user_id = Column(SQL_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, nullable=False)
    password_hash = Column(String, nullable=False) 
#    preferred_payout_alias = Column(String(100), nullable=True)
    preferred_payout_alias = Column(String(100), nullable=True) 
    preferred_payout_type = Column(SQLEnum(PayoutMethod, name="payout_method_enum"), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable= False, server_default=func.now())



#===============================================================================================================
