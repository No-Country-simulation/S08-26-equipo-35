from sqlalchemy import Column, String, DateTime, ForeignKey, UUID as SQL_UUID, Enum as SQLEnum
import uuid
from datetime import datetime
from sqlalchemy.sql import func
import enum 
from app.db.base import Base # Asumiendo que usas la misma base que en Users

class GroupStatus(enum.Enum):
    ACTIVE = "active"
    SETTLED = "settled"

class Group(Base):
    __tablename__ = 'groups'

    group_id = Column(SQL_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    group_name = Column(String(100), nullable=False)
    
    # FK apuntando a la tabla users
    created_by_user_id = Column(SQL_UUID(as_uuid=True), ForeignKey('users.user_id'), nullable=False)
    
    # Enum nativo de PostgreSQL
    status = Column(SQLEnum(GroupStatus, name="group_status_enum"), nullable=False, default=GroupStatus.ACTIVE)
    
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())