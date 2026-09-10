from sqlalchemy import Column, String, DateTime, ForeignKey, Numeric, CheckConstraint, UUID as SQL_UUID
from sqlalchemy.sql import func
import uuid
import enum
from sqlalchemy import Enum as SQLEnum
from app.db.base import Base

class SplitType(enum.Enum):
    EQUAL = "EQUAL"
    EXACT_AMOUNT = "EXACT_AMOUNT"

class Expense(Base):
    __tablename__ = 'expenses'

    expense_id = Column(SQL_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Relaciones
    group_id = Column(SQL_UUID(as_uuid=True), ForeignKey('groups.group_id'), nullable=False)
    payer_user_id = Column(SQL_UUID(as_uuid=True), ForeignKey('users.user_id'), nullable=False)
    
    title = Column(String(150), nullable=False)
    
    # DECIMAL(12,2) se representa como Numeric(12, 2) en SQLAlchemy
    total_amount = Column(Numeric(12, 2), nullable=False)
    
    # Usamos Enum nativo para el tipo de división
    split_type = Column(SQLEnum(SplitType, name="split_type_enum"), nullable=False)
    
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    # Restricción de integridad: El monto debe ser mayor a 0
    __table_args__ = (
        CheckConstraint('total_amount > 0', name='check_positive_amount'),
    )