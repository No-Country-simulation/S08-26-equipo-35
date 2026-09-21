# tests/test_settlement_service.py
from datetime import datetime
from decimal import Decimal
from uuid import uuid4

import pytest
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models.expenses import SplitType
from app.models.group_members import GroupMember
from app.models.groups import Group, GroupStatus
from app.models.settlements import SettlementStatus
from app.models.users import User
from app.schemas.expenses import ExpenseCreate, ExpenseSplitDetail
from app.services.expense_service import create_expense
from app.services.settlement_service import (
    calculate_debts_from_balances,
    compute_balances,
    get_group_debts,
    get_group_settlement_status,
    get_user_debts,
    mark_payment_paid,
    register_payment,
)


def _make_group_with(db_session: Session, users: list[User], name="Settlement Group"):
    group = Group(
        group_id=uuid4(),
        group_name=name,
        created_by_user_id=users[0].user_id,
        status=GroupStatus.ACTIVE,
        created_at=datetime.utcnow(),
    )
    db_session.add(group)
    db_session.commit()
    db_session.refresh(group)
    for u in users:
        db_session.add(
            GroupMember(
                group_id=group.group_id,
                user_id=u.user_id,
                joined_at=datetime.utcnow(),
            )
        )
    db_session.commit()
    return group


def _exact_expense(db_session, group, payer, debtor, title, category, amount):
    data = ExpenseCreate(
        payer_user_id=payer.user_id,
        title=title,
        total_amount=Decimal(str(amount)),
        split_type=SplitType.EXACT_AMOUNT,
        expense_category=category,
        splits=[
            ExpenseSplitDetail(user_id=debtor.user_id, amount_owed=Decimal(str(amount)))
        ],
    )
    return create_expense(db_session, group.group_id, data, payer.user_id)


# ============================================================
# BALANCES
# ============================================================

def test_balances_based_on_expenses(db_session: Session, test_user: User, test_users):
    maria = test_users[0]
    debtor = test_users[1]
    group = _make_group_with(db_session, [maria, debtor])

    _exact_expense(db_session, group, maria, debtor, "Accommodation", "Lodging", "12000.00")
    _exact_expense(db_session, group, maria, debtor, "Groceries", "Food", "4000.00")
    _exact_expense(db_session, group, maria, debtor, "Transportation", "Transport", "2500.00")

    balances = {b["user_id"]: b for b in compute_balances(db_session, group.group_id)}

    assert balances[maria.user_id]["paid"] == Decimal("18500.00")
    assert balances[maria.user_id]["owed"] == Decimal("0.00")
    assert balances[maria.user_id]["net_balance"] == Decimal("18500.00")

    assert balances[debtor.user_id]["paid"] == Decimal("0.00")
    assert balances[debtor.user_id]["owed"] == Decimal("18500.00")
    assert balances[debtor.user_id]["net_balance"] == Decimal("-18500.00")


def test_empty_group_has_zero_balances(db_session: Session, test_group: Group, test_user: User):
    db_session.add(
        GroupMember(
            group_id=test_group.group_id,
            user_id=test_user.user_id,
            joined_at=datetime.utcnow(),
        )
    )
    db_session.commit()
    balances = compute_balances(db_session, test_group.group_id)
    assert len(balances) == 1
    assert balances[0]["net_balance"] == Decimal("0.00")


# ============================================================
# DEBTS + BREAKDOWN
# ============================================================

def test_generate_debts_between_members(db_session: Session, test_user: User, test_users):
    maria = test_users[0]
    debtor = test_users[1]
    group = _make_group_with(db_session, [maria, debtor])

    _exact_expense(db_session, group, maria, debtor, "Accommodation", "Lodging", "12000.00")
    _exact_expense(db_session, group, maria, debtor, "Groceries", "Food", "4000.00")
    _exact_expense(db_session, group, maria, debtor, "Transportation", "Transport", "2500.00")

    result = get_group_debts(db_session, group.group_id)
    assert result["is_settled"] is False
    assert len(result["debts"]) == 1

    debt = result["debts"][0]
    assert debt["debtor_user_id"] == debtor.user_id
    assert debt["creditor_user_id"] == maria.user_id
    assert debt["amount"] == Decimal("18500.00")


def test_debt_breakdown_lists_contributing_expenses(
    db_session: Session, test_user: User, test_users
):
    maria = test_users[0]
    debtor = test_users[1]
    group = _make_group_with(db_session, [maria, debtor])

    _exact_expense(db_session, group, maria, debtor, "Accommodation", "Lodging", "12000.00")
    _exact_expense(db_session, group, maria, debtor, "Groceries", "Food", "4000.00")
    _exact_expense(db_session, group, maria, debtor, "Transportation", "Transport", "2500.00")

    result = get_group_debts(db_session, group.group_id)
    debt = result["debts"][0]

    titles = {e["title"]: e["amount"] for e in debt["expenses"]}
    assert titles == {
        "Accommodation": Decimal("12000.00"),
        "Groceries": Decimal("4000.00"),
        "Transportation": Decimal("2500.00"),
    }
    assert sum(titles.values(), Decimal("0")) == debt["amount"]


def test_min_cash_flow_minimizes_transfers():
    balances = [
        {"user_id": uuid4(), "name": "A", "net_balance": Decimal("100.00")},
        {"user_id": uuid4(), "name": "B", "net_balance": Decimal("-60.00")},
        {"user_id": uuid4(), "name": "C", "net_balance": Decimal("-40.00")},
    ]
    debts = calculate_debts_from_balances(balances)
    # 2 deudores, 1 acreedor -> solo 2 transferencias, no 3
    assert len(debts) == 2
    assert sum((d["amount"] for d in debts), Decimal("0")) == Decimal("100.00")


def test_user_debts_filters_correctly(db_session: Session, test_user: User, test_users):
    a, b, c = test_users[0], test_users[1], test_users[2]
    group = _make_group_with(db_session, [a, b, c])

    data = ExpenseCreate(
        payer_user_id=a.user_id,
        title="Dinner",
        total_amount=Decimal("90.00"),
        split_type=SplitType.EXACT_AMOUNT,
        expense_category="Food",
        splits=[
            ExpenseSplitDetail(user_id=b.user_id, amount_owed=Decimal("60.00")),
            ExpenseSplitDetail(user_id=c.user_id, amount_owed=Decimal("30.00")),
        ],
    )
    create_expense(db_session, group.group_id, data, a.user_id)

    mine = get_user_debts(db_session, group.group_id, b.user_id)
    assert len(mine["debts"]) == 1
    assert mine["debts"][0]["debtor_user_id"] == b.user_id

    uninvolved = get_user_debts(db_session, group.group_id, a.user_id)
    assert len(uninvolved["debts"]) == 2  # acreedor en ambas


# ============================================================
# PAYMENTS + STATUS
# ============================================================

def test_register_payment_creates_pending(db_session: Session, test_user: User, test_users):
    maria = test_users[0]
    debtor = test_users[1]
    group = _make_group_with(db_session, [maria, debtor])
    _exact_expense(db_session, group, maria, debtor, "Hotel", "Lodging", "100.00")

    payment = register_payment(
        db_session, group.group_id, debtor.user_id, maria.user_id, Decimal("100.00")
    )
    assert payment.status == SettlementStatus.PENDING
    assert payment.amount == Decimal("100.00")

    # PENDING no descuenta la deuda todavia
    assert len(get_group_debts(db_session, group.group_id)["debts"]) == 1


def test_payment_paid_updates_status_and_settles(
    db_session: Session, test_user: User, test_users
):
    maria = test_users[0]
    debtor = test_users[1]
    group = _make_group_with(db_session, [maria, debtor])
    _exact_expense(db_session, group, maria, debtor, "Hotel", "Lodging", "100.00")

    payment = register_payment(
        db_session, group.group_id, debtor.user_id, maria.user_id, Decimal("100.00")
    )
    confirmed = mark_payment_paid(db_session, payment.settlement_id, debtor.user_id)
    assert confirmed.status == SettlementStatus.PAID

    result = get_group_debts(db_session, group.group_id)
    assert result["is_settled"] is True
    assert result["debts"] == []

    status_info = get_group_settlement_status(db_session, group.group_id)
    assert status_info["is_settled"] is True
    assert status_info["pending_count"] == 0
    assert status_info["total_pending_amount"] == Decimal("0.00")


def test_register_payment_same_user_fails(db_session: Session, test_user: User, test_users):
    a, b = test_users[0], test_users[1]
    group = _make_group_with(db_session, [a, b])
    _exact_expense(db_session, group, a, b, "Dinner", "Food", "50.00")
    with pytest.raises(HTTPException) as exc:
        register_payment(db_session, group.group_id, b.user_id, b.user_id, Decimal("10.00"))
    assert exc.value.status_code == 400


def test_register_payment_exceeding_debt_fails(
    db_session: Session, test_user: User, test_users
):
    a, b = test_users[0], test_users[1]
    group = _make_group_with(db_session, [a, b])
    _exact_expense(db_session, group, a, b, "Dinner", "Food", "50.00")
    with pytest.raises(HTTPException) as exc:
        register_payment(db_session, group.group_id, b.user_id, a.user_id, Decimal("999.00"))
    assert exc.value.status_code == 400
    assert "excede" in exc.value.detail


def test_register_payment_without_debt_fails(
    db_session: Session, test_user: User, test_users
):
    a, b = test_users[0], test_users[1]
    group = _make_group_with(db_session, [a, b])
    # Sin gastos: nadie debe nada
    with pytest.raises(HTTPException) as exc:
        register_payment(db_session, group.group_id, b.user_id, a.user_id, Decimal("10.00"))
    assert exc.value.status_code == 400
