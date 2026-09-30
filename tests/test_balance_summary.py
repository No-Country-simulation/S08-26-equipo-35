# tests/test_balance_summary.py
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import uuid4

from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token
from app.models.expenses import SplitType
from app.models.group_members import GroupMember
from app.models.groups import Group, GroupStatus
from app.models.users import User
from app.schemas.expenses import ExpenseCreate, ExpenseSplitDetail
from app.services.expense_service import create_expense
from app.services.settlement_service import (
    get_group_balance_summary,
    get_user_global_summary,
    mark_payment_paid,
    register_payment,
)


def _exact_expense(db_session, group, payer, debtor, amount="100.00", title="Dinner"):
    data = ExpenseCreate(
        payer_user_id=payer.user_id,
        title=title,
        total_amount=Decimal(amount),
        split_type=SplitType.EXACT_AMOUNT,
        expense_category="Food",
        splits=[ExpenseSplitDetail(user_id=debtor.user_id, amount_owed=Decimal(amount))],
    )
    return create_expense(db_session, group.group_id, data, payer.user_id)


def _make_group(db_session, users, name="G"):
    group = Group(
        group_id=uuid4(), group_name=name,
        created_by_user_id=users[0].user_id,
        status=GroupStatus.ACTIVE, created_at=datetime.utcnow(),
    )
    db_session.add(group)
    db_session.commit()
    db_session.refresh(group)
    for u in users:
        db_session.add(GroupMember(group_id=group.group_id, user_id=u.user_id, joined_at=datetime.utcnow()))
    db_session.commit()
    return group


# ============================================================
# SERVICIO - nivel grupo
# ============================================================

def test_group_summary_totals(db_session: Session, test_users):
    a, b = test_users[0], test_users[1]
    group = _make_group(db_session, [a, b], "Summary G")
    _exact_expense(db_session, group, a, b, "120.00", "Hotel")
    _exact_expense(db_session, group, a, b, "80.00", "Food")

    summary = get_group_balance_summary(db_session, group.group_id)
    assert summary["total_expenses"] == Decimal("200.00")
    assert summary["total_pending_amount"] == Decimal("200.00")
    assert summary["total_settled_amount"] == Decimal("0.00")
    assert summary["pending_count"] == 1
    assert summary["member_count"] == 2
    assert summary["is_settled"] is False
    assert len(summary["balances"]) == 2
    assert len(summary["suggested_transfers"]) == 1


def test_group_summary_after_payment(db_session: Session, test_users):
    a, b = test_users[0], test_users[1]
    group = _make_group(db_session, [a, b], "Summary Paid")
    _exact_expense(db_session, group, a, b, "100.00")
    payment = register_payment(db_session, group.group_id, b.user_id, a.user_id, Decimal("100.00"))
    mark_payment_paid(db_session, payment.settlement_id, b.user_id)

    summary = get_group_balance_summary(db_session, group.group_id)
    assert summary["is_settled"] is True
    assert summary["total_pending_amount"] == Decimal("0.00")
    assert summary["total_settled_amount"] == Decimal("100.00")
    assert summary["suggested_transfers"] == []


def test_group_summary_empty_group(db_session: Session, test_group: Group, test_user: User):
    db_session.add(GroupMember(group_id=test_group.group_id, user_id=test_user.user_id, joined_at=datetime.utcnow()))
    db_session.commit()
    summary = get_group_balance_summary(db_session, test_group.group_id)
    assert summary["total_expenses"] == Decimal("0.00")
    assert summary["is_settled"] is True
    assert summary["member_count"] == 1


# ============================================================
# SERVICIO - nivel global
# ============================================================

def test_user_global_summary_across_groups(db_session: Session, test_users):
    a, b, c = test_users[0], test_users[1], test_users[2]
    g1 = _make_group(db_session, [a, b], "G1")
    g2 = _make_group(db_session, [a, c], "G2")
    _exact_expense(db_session, g1, a, b, "100.00")  # b debe 100 a a
    _exact_expense(db_session, g2, c, a, "40.00")   # a debe 40 a c

    summary_b = get_user_global_summary(db_session, b.user_id)
    assert summary_b["total_owed"] == Decimal("100.00")
    assert summary_b["total_to_receive"] == Decimal("0.00")
    assert summary_b["net"] == Decimal("-100.00")
    assert summary_b["group_count"] == 1

    summary_a = get_user_global_summary(db_session, a.user_id)
    assert summary_a["total_to_receive"] == Decimal("100.00")
    assert summary_a["total_owed"] == Decimal("40.00")
    assert summary_a["net"] == Decimal("60.00")
    assert summary_a["group_count"] == 2
    assert {g["group_id"] for g in summary_a["per_group"]} == {g1.group_id, g2.group_id}


def test_user_global_summary_no_groups(db_session: Session, test_user: User):
    summary = get_user_global_summary(db_session, test_user.user_id)
    assert summary["total_owed"] == Decimal("0.00")
    assert summary["group_count"] == 0
    assert summary["per_group"] == []


# ============================================================
# API
# ============================================================

def test_api_group_balance_summary(
    authenticated_client: TestClient, db_session: Session,
    test_group_with_members: Group, test_user: User, test_users,
):
    creditor = db_session.query(User).filter(User.user_id == test_users[0].user_id).first()
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "90.00")
    r = authenticated_client.get(f"/api/v1/groups/{test_group_with_members.group_id}/balance-summary")
    assert r.status_code == status.HTTP_200_OK
    data = r.json()
    assert data["group_id"] == str(test_group_with_members.group_id)
    assert Decimal(str(data["total_expenses"])) == Decimal("90.00")
    assert Decimal(str(data["total_pending_amount"])) > 0
    assert "balances" in data and "suggested_transfers" in data
    assert data["member_count"] >= 2


def test_api_group_balance_summary_forbidden(
    authenticated_client: TestClient, db_session: Session, test_group: Group
):
    outsider = User(
        user_id=uuid4(), name="OutS", email="outsider_sum@example.com",
        password_hash="h", preferred_payout_alias="x",
        preferred_payout_type="CBU", created_at=datetime.utcnow(),
    )
    db_session.add(outsider)
    db_session.commit()
    token = create_access_token(
        data={"sub": outsider.email},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    authenticated_client.headers["Authorization"] = f"Bearer {token}"
    r = authenticated_client.get(f"/api/v1/groups/{test_group.group_id}/balance-summary")
    assert r.status_code == status.HTTP_403_FORBIDDEN


def test_api_user_global_summary(
    authenticated_client: TestClient, db_session: Session,
    test_group_with_members: Group, test_user: User, test_users,
):
    creditor = db_session.query(User).filter(User.user_id == test_users[0].user_id).first()
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "90.00")
    r = authenticated_client.get("/api/v1/users/me/balance-summary")
    assert r.status_code == status.HTTP_200_OK
    data = r.json()
    assert data["user_id"] == str(test_user.user_id)
    assert data["group_count"] >= 1
    assert Decimal(str(data["total_owed"])) >= Decimal("0")
    assert "per_group" in data
