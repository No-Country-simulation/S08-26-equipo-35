# app/schemas/expenses.py
from decimal import Decimal
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, ConfigDict

from app.models.expenses import SplitType


# ============================================================
# EXPENSE SPLIT DETAIL
# ============================================================

class ExpenseSplitDetail(BaseModel):
    user_id: UUID
    amount_owed: Decimal = Field(
        gt=0,
        decimal_places=2
    )


# ============================================================
# EXPENSE SPLIT RESPONSE
# ============================================================

class ExpenseSplitResponse(BaseModel):
    split_id: UUID
    user_id: UUID
    amount_owed: Decimal

    model_config = ConfigDict(
        from_attributes=True
    )


# ============================================================
# EXPENSE CREATE
# ============================================================

class ExpenseCreate(BaseModel):
    payer_user_id: UUID

    title: str = Field(
        min_length=1,
        max_length=150
    )

    total_amount: Decimal = Field(
        gt=0,
        decimal_places=2
    )

    split_type: SplitType

    expense_category: str = Field(
        min_length=1,
        max_length=100
    )

    # Obligatorio solamente cuando split_type = EXACT_AMOUNT
    splits: Optional[list[ExpenseSplitDetail]] = None


# ============================================================
# EXPENSE UPDATE
# ============================================================

class ExpenseUpdate(BaseModel):
    payer_user_id: Optional[UUID] = None

    title: Optional[str] = Field(
        default=None,
        min_length=1,
        max_length=150
    )

    total_amount: Optional[Decimal] = Field(
        default=None,
        gt=0,
        decimal_places=2
    )

    split_type: Optional[SplitType] = None

    expense_category: Optional[str] = Field(
        default=None,
        min_length=1,
        max_length=100
    )

    splits: Optional[list[ExpenseSplitDetail]] = None


# ============================================================
# EXPENSE RESPONSE
# ============================================================

class ExpenseResponse(BaseModel):
    expense_id: UUID
    group_id: UUID
    payer_user_id: UUID
    title: str
    total_amount: Decimal
    split_type: SplitType
    expense_category: str
    created_at: datetime
    splits: list[ExpenseSplitResponse] = []

    model_config = ConfigDict(
        from_attributes=True
    )
```
