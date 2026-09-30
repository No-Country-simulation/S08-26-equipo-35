# app/schemas/balances.py
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel

from app.schemas.settlements import BalanceResponse, DebtResponse


class GroupBalanceSummaryResponse(BaseModel):
    """Resumen agregado por grupo (Balance Summary nivel grupo)."""

    group_id: UUID
    total_expenses: Decimal
    total_settled_amount: Decimal
    total_pending_amount: Decimal
    pending_count: int
    member_count: int
    is_settled: bool
    balances: list[BalanceResponse] = []
    suggested_transfers: list[DebtResponse] = []


class PerGroupUserSummary(BaseModel):
    """Detalle por grupo dentro del resumen global del usuario."""

    group_id: UUID
    group_name: str
    owed: Decimal
    to_receive: Decimal
    net: Decimal
    pending_count: int
    is_settled: bool


class UserGlobalSummaryResponse(BaseModel):
    """Resumen global del usuario en todos sus grupos (Balance Summary global)."""

    user_id: UUID
    total_owed: Decimal
    total_to_receive: Decimal
    net: Decimal
    group_count: int
    per_group: list[PerGroupUserSummary] = []
