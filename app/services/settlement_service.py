# app/services/settlement_service.py
from collections import defaultdict
from datetime import datetime, timezone
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.expense_splits import ExpenseSplit
from app.models.expenses import Expense
from app.models.group_members import GroupMember
from app.models.groups import Group
from app.models.settlements import Settlement, SettlementStatus
from app.models.users import User
from app.services.expense_service import get_group_or_404, validate_group_member

CENT = Decimal("0.01")
TOLERANCE = Decimal("0.01")

# Estados que descuentan deuda (PAID es el actual, CONFIRMED es legacy).
SETTLED_STATUSES = (SettlementStatus.PAID, SettlementStatus.CONFIRMED)


def _quant(value: Decimal) -> Decimal:
    return Decimal(value).quantize(CENT)


def _user_names(db: Session, user_ids: set[UUID]) -> dict:
    if not user_ids:
        return {}
    users = db.query(User).filter(User.user_id.in_(list(user_ids))).all()
    return {u.user_id: u.name for u in users}


# ============================================================
# BALANCES
# ============================================================

def compute_balances(db: Session, group_id: UUID) -> list[dict]:
    """Calcula paid / owed / net por miembro.

    net = paid - owed + ajustes por pagos PAID/CONFIRMED.
    net > 0 cobra, net < 0 debe.
    """
    get_group_or_404(db, group_id)

    members = (
        db.query(GroupMember)
        .filter(GroupMember.group_id == group_id)
        .all()
    )
    member_ids = [m.user_id for m in members]
    names = _user_names(db, set(member_ids))

    paid: dict = defaultdict(lambda: Decimal("0"))
    owed: dict = defaultdict(lambda: Decimal("0"))

    expenses = db.query(Expense).filter(Expense.group_id == group_id).all()
    expense_ids = [e.expense_id for e in expenses]
    for expense in expenses:
        paid[expense.payer_user_id] += Decimal(expense.total_amount)

    if expense_ids:
        splits = (
            db.query(ExpenseSplit)
            .filter(ExpenseSplit.expense_id.in_(expense_ids))
            .all()
        )
        for split in splits:
            owed[split.user_id] += Decimal(split.amount_owed)

    # Los pagos saldados reducen la deuda: el que paga recupera neto,
    # el que recibe lo pierde (ya cobro).
    settlements = (
        db.query(Settlement)
        .filter(
            Settlement.group_id == group_id,
            Settlement.status.in_(list(SETTLED_STATUSES)),
        )
        .all()
    )
    for s in settlements:
        amount = Decimal(s.amount)
        # payer (deudor) paga -> su neto sube (debe menos)
        # receiver (acreedor) cobra -> su neto baja (le deben menos)
        owed[s.payer_user_id] -= amount
        paid[s.receiver_user_id] -= amount

    balances = []
    for user_id in member_ids:
        p = _quant(paid.get(user_id, Decimal("0")))
        o = _quant(owed.get(user_id, Decimal("0")))
        net = _quant(p - o)
        balances.append(
            {
                "user_id": user_id,
                "name": names.get(user_id, ""),
                "paid": p,
                "owed": o,
                "net_balance": net,
            }
        )

    return balances


# ============================================================
# MIN-CASH-FLOW
# ============================================================

def calculate_debts_from_balances(balances: list[dict]) -> list[dict]:
    """Greedy min-cash-flow: empareja mayor deudor con mayor acreedor."""
    debtors = [
        {"user_id": b["user_id"], "name": b["name"], "amount": -b["net_balance"]}
        for b in balances
        if b["net_balance"] < -TOLERANCE / 2
    ]
    creditors = [
        {"user_id": b["user_id"], "name": b["name"], "amount": b["net_balance"]}
        for b in balances
        if b["net_balance"] > TOLERANCE / 2
    ]

    debtors.sort(key=lambda x: x["amount"], reverse=True)
    creditors.sort(key=lambda x: x["amount"], reverse=True)

    debts: list[dict] = []
    i = j = 0
    while i < len(debtors) and j < len(creditors):
        debtor = debtors[i]
        creditor = creditors[j]
        transfer = _quant(min(debtor["amount"], creditor["amount"]))

        if transfer >= CENT:
            debts.append(
                {
                    "debtor_user_id": debtor["user_id"],
                    "debtor_name": debtor["name"],
                    "creditor_user_id": creditor["user_id"],
                    "creditor_name": creditor["name"],
                    "amount": transfer,
                }
            )
            debtor["amount"] = _quant(debtor["amount"] - transfer)
            creditor["amount"] = _quant(creditor["amount"] - transfer)

        if debtor["amount"] < CENT:
            i += 1
        if creditor["amount"] < CENT:
            j += 1

    return debts


# ============================================================
# BREAKDOWN por gasto
# ============================================================

def get_debt_breakdown(
    db: Session,
    group_id: UUID,
    debtor_id: UUID,
    creditor_id: UUID,
    debt_amount: Decimal,
) -> list[dict]:
    """Gastos donde el deudor participo y el acreedor pago.

    Se asigna por antiguedad hasta cubrir debt_amount para que el
    desglose sume exactamente la deuda (ej: 12k+4k+2.5k = 18.5k).
    """
    rows = (
        db.query(ExpenseSplit, Expense)
        .join(Expense, ExpenseSplit.expense_id == Expense.expense_id)
        .filter(
            Expense.group_id == group_id,
            Expense.payer_user_id == creditor_id,
            ExpenseSplit.user_id == debtor_id,
        )
        .order_by(Expense.created_at.asc())
        .all()
    )

    breakdown: list[dict] = []
    remaining = _quant(debt_amount)
    for split, expense in rows:
        if remaining < CENT:
            break
        owed = _quant(Decimal(split.amount_owed))
        take = min(owed, remaining)
        breakdown.append(
            {
                "expense_id": expense.expense_id,
                "title": expense.title,
                "expense_category": expense.expense_category,
                "amount": take,
            }
        )
        remaining = _quant(remaining - take)

    return breakdown


# ============================================================
# CONSULTAS
# ============================================================

def get_group_debts(db: Session, group_id: UUID) -> dict:
    balances = compute_balances(db, group_id)
    raw_debts = calculate_debts_from_balances(balances)

    debts = []
    for d in raw_debts:
        expenses = get_debt_breakdown(
            db, group_id, d["debtor_user_id"], d["creditor_user_id"], d["amount"]
        )
        debts.append({**d, "status": "PENDING", "expenses": expenses})

    is_settled = len(debts) == 0
    return {
        "group_id": group_id,
        "balances": balances,
        "debts": debts,
        "is_settled": is_settled,
    }


def get_user_debts(db: Session, group_id: UUID, user_id: UUID) -> dict:
    validate_group_member(db, group_id, user_id, "El usuario no pertenece al grupo")
    result = get_group_debts(db, group_id)
    result["debts"] = [
        d
        for d in result["debts"]
        if d["debtor_user_id"] == user_id or d["creditor_user_id"] == user_id
    ]
    return result


def get_group_settlement_status(db: Session, group_id: UUID) -> dict:
    result = get_group_debts(db, group_id)
    total = sum((d["amount"] for d in result["debts"]), Decimal("0"))
    return {
        "group_id": group_id,
        "is_settled": result["is_settled"],
        "pending_count": len(result["debts"]),
        "total_pending_amount": _quant(total),
        "debts": result["debts"],
    }


def list_payments(db: Session, group_id: UUID) -> list[Settlement]:
    get_group_or_404(db, group_id)
    return (
        db.query(Settlement)
        .filter(Settlement.group_id == group_id)
        .order_by(Settlement.settled_at.desc())
        .all()
    )


# ============================================================
# PAGOS
# ============================================================

def _total_owed_by(db: Session, group_id: UUID, user_id: UUID) -> Decimal:
    result = get_group_debts(db, group_id)
    total = sum(
        (d["amount"] for d in result["debts"] if d["debtor_user_id"] == user_id),
        Decimal("0"),
    )
    return _quant(total)


def register_payment(
    db: Session,
    group_id: UUID,
    payer_user_id: UUID,
    receiver_user_id: UUID,
    amount: Decimal,
) -> Settlement:
    get_group_or_404(db, group_id)
    validate_group_member(
        db, group_id, payer_user_id, "El pagador debe pertenecer al grupo"
    )
    validate_group_member(
        db, group_id, receiver_user_id, "El receptor debe pertenecer al grupo"
    )

    if payer_user_id == receiver_user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El pagador y el receptor no pueden ser el mismo usuario",
        )

    amount = _quant(amount)
    if amount < CENT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El monto debe ser mayor a 0",
        )

    owed = _total_owed_by(db, group_id, payer_user_id)
    if owed < CENT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El pagador no tiene deudas pendientes en este grupo",
        )
    if amount - owed > TOLERANCE / 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"El monto ({amount}) excede la deuda del pagador ({owed})",
        )

    settlement = Settlement(
        group_id=group_id,
        payer_user_id=payer_user_id,
        receiver_user_id=receiver_user_id,
        amount=amount,
        status=SettlementStatus.PENDING,
    )
    db.add(settlement)
    db.commit()
    db.refresh(settlement)
    return settlement


def mark_payment_paid(
    db: Session, settlement_id: UUID, current_user_id: UUID
) -> Settlement:
    settlement = (
        db.query(Settlement)
        .filter(Settlement.settlement_id == settlement_id)
        .first()
    )
    if not settlement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Pago no encontrado"
        )

    validate_group_member(
        db,
        settlement.group_id,
        current_user_id,
        "No tienes permisos sobre este pago",
    )

    if settlement.payer_user_id != current_user_id and (
        settlement.receiver_user_id != current_user_id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el pagador o el receptor pueden confirmar el pago",
        )

    if settlement.status in SETTLED_STATUSES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El pago ya fue confirmado",
        )

    settlement.status = SettlementStatus.PAID
    settlement.settled_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(settlement)

    # Si ya no quedan deudas, marcar el grupo como SETTLED (best-effort).
    try:
        from app.models.groups import GroupStatus

        status_info = get_group_settlement_status(db, settlement.group_id)
        if status_info["is_settled"]:
            group = (
                db.query(Group)
                .filter(Group.group_id == settlement.group_id)
                .first()
            )
            if group is not None:
                group.status = GroupStatus.SETTLED
                db.commit()
    except Exception:
        db.rollback()

    return settlement
