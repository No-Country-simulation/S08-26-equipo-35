from sqlalchemy import Column, DateTime, ForeignKey, UUID as SQL_UUID
from sqlalchemy.sql import func
from app.db.base import Base

class GroupMember(Base):
    __tablename__ = 'group_members'

    # Clave Foránea hacia GROUPS
    group_id = Column(SQL_UUID(as_uuid=True), ForeignKey('groups.group_id'), primary_key=True, nullable=False)
    
    # Clave Foránea hacia USERS
    user_id = Column(SQL_UUID(as_uuid=True), ForeignKey('users.user_id'), primary_key=True, nullable=False)
    
    # Fecha de unión
    joined_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())