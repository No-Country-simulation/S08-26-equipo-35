# app/api/v1/settlements.py
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.models.group_members import GroupMember
from app.models.users import User
from app.schemas.settlements import (
    BalanceResponse,
    GroupDebtsResponse,
    GroupSettlementStatus,
    SettlementCreate,
    SettlementResponse,
)
from app.services.settlement_service import (
    compute_balances,
    get_group_debts,
    get_group_settlement_status,
    get_user_debts,
    list_payments,
    mark_payment_paid,
    register_payment,
)

router = APIRouter()


def _require_membership(db: Session, group_id: UUID, user_id: UUID):
    member = (
        db.query(GroupMember)
        .filter(
            GroupMember.group_id == group_id,
            GroupMember.user_id == user_id,
        )
        .first()
    )
    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No perteneces a este grupo",
        )


# ============================================================
# BALANCES
# ============================================================

@router.get("/groups/{group_id}/balances", response_model=list[BalanceResponse])
def get_balances(
    group_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    return compute_balances(db, group_id)


# ============================================================
# DEBTS
# ============================================================

@router.get("/groups/{group_id}/debts", response_model=GroupDebtsResponse)
def get_debts(
    group_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    return get_group_debts(db, group_id)


@router.get("/groups/{group_id}/debts/me", response_model=GroupDebtsResponse)
def get_my_debts(
    group_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    return get_user_debts(db, group_id, current_user.user_id)


@router.get(
    "/groups/{group_id}/debts/user/{user_id}", response_model=GroupDebtsResponse
)
def get_debts_for_user(
    group_id: UUID,
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    return get_user_debts(db, group_id, user_id)


@router.get(
    "/groups/{group_id}/settlements/status", response_model=GroupSettlementStatus
)
def get_settlement_status(
    group_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    return get_group_settlement_status(db, group_id)


# ============================================================
# PAYMENTS
# ============================================================

@router.get(
    "/groups/{group_id}/payments", response_model=list[SettlementResponse]
)
def get_payments(
    group_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    payments = list_payments(db, group_id)
    return [
        {
            "settlement_id": p.settlement_id,
            "group_id": p.group_id,
            "payer_user_id": p.payer_user_id,
            "receiver_user_id": p.receiver_user_id,
            "amount": p.amount,
            "status": p.status.value if hasattr(p.status, "value") else str(p.status),
            "settled_at": p.settled_at,
        }
        for p in payments
    ]


@router.post(
    "/groups/{group_id}/payments",
    response_model=SettlementResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_payment(
    group_id: UUID,
    payment: SettlementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    settlement = register_payment(
        db=db,
        group_id=group_id,
        payer_user_id=current_user.user_id,
        receiver_user_id=payment.receiver_user_id,
        amount=payment.amount,
    )
    return {
        "settlement_id": settlement.settlement_id,
        "group_id": settlement.group_id,
        "payer_user_id": settlement.payer_user_id,
        "receiver_user_id": settlement.receiver_user_id,
        "amount": settlement.amount,
        "status": settlement.status.value
        if hasattr(settlement.status, "value")
        else str(settlement.status),
        "settled_at": settlement.settled_at,
    }


@router.patch(
    "/payments/{settlement_id}/pay", response_model=SettlementResponse
)
def pay_settlement(
    settlement_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    settlement = mark_payment_paid(
        db=db,
        settlement_id=settlement_id,
        current_user_id=current_user.user_id,
    )
    return {
        "settlement_id": settlement.settlement_id,
        "group_id": settlement.group_id,
        "payer_user_id": settlement.payer_user_id,
        "receiver_user_id": settlement.receiver_user_id,
        "amount": settlement.amount,
        "status": settlement.status.value
        if hasattr(settlement.status, "value")
        else str(settlement.status),
        "settled_at": settlement.settled_at,
    }


# Alias para compatibilidad: DebtResponse tambien disponible como settlements
@router.get("/groups/{group_id}/settlements", response_model=GroupDebtsResponse)
def get_settlements_alias(
    group_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    _require_membership(db, group_id, current_user.user_id)
    return get_group_debts(db, group_id)
