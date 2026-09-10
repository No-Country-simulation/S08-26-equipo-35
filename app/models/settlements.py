from sqlalchemy import Column, String, DateTime, ForeignKey, Numeric, UUID as SQL_UUID
from sqlalchemy.sql import func
import uuid
import enum
from sqlalchemy import Enum as SQLEnum
from app.db.base import Base

class SettlementStatus(enum.Enum):
    CONFIRMED = "CONFIRMED"
    PENDING = "PENDING"

class Settlement(Base):
    __tablename__ = 'settlements'

    settlement_id = Column(SQL_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Relación con el grupo donde ocurre el pago
    group_id = Column(SQL_UUID(as_uuid=True), ForeignKey('groups.group_id'), nullable=False)
    
    # Usuario que PAGA (el deudor)
    payer_user_id = Column(SQL_UUID(as_uuid=True), ForeignKey('users.user_id'), nullable=False)
    
    # Usuario que RECIBE (el acreedor)
    receiver_user_id = Column(SQL_UUID(as_uuid=True), ForeignKey('users.user_id'), nullable=False)
    
    amount = Column(Numeric(12, 2), nullable=False)
    
    # Estado del pago usando Enum nativo
    status = Column(SQLEnum(SettlementStatus, name="settlement_status_enum"), nullable=False, default=SettlementStatus.PENDING)
    
    settled_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())