# app/schemas/settlements.py
from datetime import datetime
from decimal import Decimal
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


# ============================================================
# BALANCES
# ============================================================

class BalanceResponse(BaseModel):
    user_id: UUID
    name: str
    paid: Decimal
    owed: Decimal
    net_balance: Decimal

    model_config = ConfigDict(from_attributes=True)


# ============================================================
# DEBT BREAKDOWN
# ============================================================

class DebtExpenseBreakdown(BaseModel):
    expense_id: UUID
    title: str
    expense_category: str
    amount: Decimal


class DebtResponse(BaseModel):
    debtor_user_id: UUID
    debtor_name: str
    creditor_user_id: UUID
    creditor_name: str
    amount: Decimal
    status: Literal["PENDING", "PAID"] = "PENDING"
    expenses: list[DebtExpenseBreakdown] = []


# ============================================================
# PAYMENTS (settlement records)
# ============================================================

class SettlementCreate(BaseModel):
    receiver_user_id: UUID
    amount: Decimal = Field(gt=0, decimal_places=2)


class SettlementResponse(BaseModel):
    settlement_id: UUID
    group_id: UUID
    payer_user_id: UUID
    receiver_user_id: UUID
    amount: Decimal
    status: str
    settled_at: datetime

    model_config = ConfigDict(from_attributes=True)


class SettlementStatusUpdate(BaseModel):
    status: Literal["PAID"]


# ============================================================
# GROUP STATUS
# ============================================================

class GroupSettlementStatus(BaseModel):
    group_id: UUID
    is_settled: bool
    pending_count: int
    total_pending_amount: Decimal
    debts: list[DebtResponse] = []


class GroupDebtsResponse(BaseModel):
    group_id: UUID
    balances: list[BalanceResponse]
    debts: list[DebtResponse]
    is_settled: bool
