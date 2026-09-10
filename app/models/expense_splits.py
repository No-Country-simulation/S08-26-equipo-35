from sqlalchemy import Column, ForeignKey, Numeric, UUID as SQL_UUID
import uuid
from app.db.base import Base

class ExpenseSplit(Base):
    __tablename__ = 'expense_splits'

    split_id = Column(SQL_UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Relación con el gasto principal
    expense_id = Column(SQL_UUID(as_uuid=True), ForeignKey('expenses.expense_id'), nullable=False)
    
    # Relación con el usuario que debe pagar su parte
    user_id = Column(SQL_UUID(as_uuid=True), ForeignKey('users.user_id'), nullable=False)
    
    # El monto exacto que esta persona debe por este gasto específico
    amount_owed = Column(Numeric(12, 2), nullable=False)