# tests/test_payments_crud.py
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import uuid4

import pytest
from fastapi import HTTPException, status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token
from app.models.expenses import SplitType
from app.models.group_members import GroupMember
from app.models.groups import Group
from app.models.settlements import SettlementStatus
from app.models.users import User
from app.schemas.expenses import ExpenseCreate, ExpenseSplitDetail
from app.services.expense_service import create_expense
from app.services.settlement_service import (
    cancel_payment,
    get_group_debts,
    get_payment_by_id,
    list_payments_filtered,
    mark_payment_paid,
    register_payment,
)


def _exact_expense(db_session, group, payer, debtor, amount="100.00"):
    data = ExpenseCreate(
        payer_user_id=payer.user_id,
        title="Dinner",
        total_amount=Decimal(amount),
        split_type=SplitType.EXACT_AMOUNT,
        expense_category="Food",
        splits=[ExpenseSplitDetail(user_id=debtor.user_id, amount_owed=Decimal(amount))],
    )
    return create_expense(db_session, group.group_id, data, payer.user_id)


def _token_for(user: User) -> str:
    return create_access_token(
        data={"sub": user.email},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )


# ============================================================
# SERVICIO
# ============================================================

def test_get_payment_by_id_ok(db_session: Session, test_group_with_members: Group, test_user: User, test_users):
    creditor = test_users[0]
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "50.00")
    payment = register_payment(
        db_session, test_group_with_members.group_id, test_user.user_id, creditor.user_id, Decimal("50.00")
    )
    found = get_payment_by_id(db_session, payment.settlement_id, test_user.user_id)
    assert found.settlement_id == payment.settlement_id


def test_get_payment_by_id_not_found(db_session: Session, test_user: User):
    with pytest.raises(HTTPException) as exc:
        get_payment_by_id(db_session, uuid4(), test_user.user_id)
    assert exc.value.status_code == 404


def test_get_payment_by_id_forbidden_for_outsider(
    db_session: Session, test_group_with_members: Group, test_user: User, test_users
):
    creditor = test_users[0]
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "50.00")
    payment = register_payment(
        db_session, test_group_with_members.group_id, test_user.user_id, creditor.user_id, Decimal("50.00")
    )
    outsider = User(
        user_id=uuid4(), name="Out", email="out_pay@example.com",
        password_hash="h", preferred_payout_alias="x",
        preferred_payout_type="CBU", created_at=datetime.utcnow(),
    )
    db_session.add(outsider)
    db_session.commit()
    with pytest.raises(HTTPException) as exc:
        get_payment_by_id(db_session, payment.settlement_id, outsider.user_id)
    assert exc.value.status_code == 403


def test_list_payments_filtered_by_status_and_pagination(
    db_session: Session, test_group_with_members: Group, test_user: User, test_users
):
    creditor = test_users[0]
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "100.00")
    p1 = register_payment(
        db_session, test_group_with_members.group_id, test_user.user_id, creditor.user_id, Decimal("40.00")
    )
    p2 = register_payment(
        db_session, test_group_with_members.group_id, test_user.user_id, creditor.user_id, Decimal("30.00")
    )
    mark_payment_paid(db_session, p1.settlement_id, test_user.user_id)

    paid = list_payments_filtered(db_session, test_group_with_members.group_id, status_filter=["PAID"])
    assert {p.settlement_id for p in paid} == {p1.settlement_id}

    pending = list_payments_filtered(db_session, test_group_with_members.group_id, status_filter="PENDING")
    assert {p.settlement_id for p in pending} == {p2.settlement_id}

    page = list_payments_filtered(db_session, test_group_with_members.group_id, limit=1, offset=0)
    assert len(page) == 1

    by_payer = list_payments_filtered(db_session, test_group_with_members.group_id, payer_id=test_user.user_id)
    assert len(by_payer) == 2
    by_receiver = list_payments_filtered(db_session, test_group_with_members.group_id, receiver_id=creditor.user_id)
    assert len(by_receiver) == 2


def test_list_payments_invalid_status_fails(
    db_session: Session, test_group_with_members: Group
):
    with pytest.raises(HTTPException) as exc:
        list_payments_filtered(db_session, test_group_with_members.group_id, status_filter=["NOPE"])
    assert exc.value.status_code == 400


def test_cancel_payment_flow(
    db_session: Session, test_group_with_members: Group, test_user: User, test_users
):
    creditor = test_users[0]
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "80.00")
    payment = register_payment(
        db_session, test_group_with_members.group_id, test_user.user_id, creditor.user_id, Decimal("80.00")
    )
    cancelled = cancel_payment(db_session, payment.settlement_id, test_user.user_id)
    assert cancelled.status == SettlementStatus.CANCELLED
    # CANCELLED no descuenta deuda
    assert len(get_group_debts(db_session, test_group_with_members.group_id)["debts"]) == 1

    with pytest.raises(HTTPException) as exc:
        cancel_payment(db_session, payment.settlement_id, test_user.user_id)
    assert exc.value.status_code == 400


def test_cancel_paid_fails(
    db_session: Session, test_group_with_members: Group, test_user: User, test_users
):
    creditor = test_users[0]
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "80.00")
    payment = register_payment(
        db_session, test_group_with_members.group_id, test_user.user_id, creditor.user_id, Decimal("80.00")
    )
    mark_payment_paid(db_session, payment.settlement_id, test_user.user_id)
    with pytest.raises(HTTPException) as exc:
        cancel_payment(db_session, payment.settlement_id, test_user.user_id)
    assert exc.value.status_code == 400


def test_pay_cancelled_fails(
    db_session: Session, test_group_with_members: Group, test_user: User, test_users
):
    creditor = test_users[0]
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "80.00")
    payment = register_payment(
        db_session, test_group_with_members.group_id, test_user.user_id, creditor.user_id, Decimal("80.00")
    )
    cancel_payment(db_session, payment.settlement_id, creditor.user_id)
    with pytest.raises(HTTPException) as exc:
        mark_payment_paid(db_session, payment.settlement_id, test_user.user_id)
    assert exc.value.status_code == 400


# ============================================================
# API
# ============================================================

def test_api_get_payment_by_id(
    authenticated_client: TestClient, db_session: Session,
    test_group_with_members: Group, test_user: User, test_users,
):
    creditor = db_session.query(User).filter(User.user_id == test_users[0].user_id).first()
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "60.00")
    r = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(creditor.user_id), "amount": 60.00},
    )
    assert r.status_code == status.HTTP_201_CREATED, r.text
    pid = r.json()["settlement_id"]

    r = authenticated_client.get(f"/api/v1/groups/{test_group_with_members.group_id}/payments/{pid}")
    assert r.status_code == status.HTTP_200_OK
    assert r.json()["settlement_id"] == pid


def test_api_get_payment_wrong_group_returns_404(
    authenticated_client: TestClient, db_session: Session,
    test_group_with_members: Group, test_group: Group, test_user: User, test_users,
):
    creditor = db_session.query(User).filter(User.user_id == test_users[0].user_id).first()
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "60.00")
    r = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(creditor.user_id), "amount": 60.00},
    )
    pid = r.json()["settlement_id"]
    # test_group existe pero el pago no pertenece a ese grupo
    db_session.add(GroupMember(group_id=test_group.group_id, user_id=test_user.user_id, joined_at=datetime.utcnow()))
    db_session.commit()
    r = authenticated_client.get(f"/api/v1/groups/{test_group.group_id}/payments/{pid}")
    assert r.status_code == status.HTTP_404_NOT_FOUND


def test_api_list_payments_with_filters(
    authenticated_client: TestClient, db_session: Session,
    test_group_with_members: Group, test_user: User, test_users,
):
    creditor = db_session.query(User).filter(User.user_id == test_users[0].user_id).first()
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "100.00")
    authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(creditor.user_id), "amount": 40.00},
    )
    authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(creditor.user_id), "amount": 30.00},
    )
    r = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        params={"status": "PENDING", "limit": 1, "offset": 0},
    )
    assert r.status_code == status.HTTP_200_OK
    assert len(r.json()) == 1
    assert r.json()[0]["status"] == "PENDING"

    r = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        params={"status": "NOPE"},
    )
    assert r.status_code == status.HTTP_400_BAD_REQUEST


def test_api_cancel_payment(
    authenticated_client: TestClient, db_session: Session,
    test_group_with_members: Group, test_user: User, test_users,
):
    creditor = db_session.query(User).filter(User.user_id == test_users[0].user_id).first()
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "70.00")
    r = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(creditor.user_id), "amount": 70.00},
    )
    pid = r.json()["settlement_id"]
    r = authenticated_client.patch(f"/api/v1/payments/{pid}/cancel")
    assert r.status_code == status.HTTP_200_OK
    assert r.json()["status"] == "CANCELLED"
    # segundo intento falla
    r = authenticated_client.patch(f"/api/v1/payments/{pid}/cancel")
    assert r.status_code == status.HTTP_400_BAD_REQUEST


def test_api_cancel_payment_forbidden_for_outsider(
    authenticated_client: TestClient, db_session: Session,
    test_group_with_members: Group, test_user: User, test_users,
):
    creditor = db_session.query(User).filter(User.user_id == test_users[0].user_id).first()
    _exact_expense(db_session, test_group_with_members, creditor, test_user, "70.00")
    r = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(creditor.user_id), "amount": 70.00},
    )
    pid = r.json()["settlement_id"]
    outsider = User(
        user_id=uuid4(), name="Out2", email="out2_pay@example.com",
        password_hash="h", preferred_payout_alias="x",
        preferred_payout_type="CBU", created_at=datetime.utcnow(),
    )
    db_session.add(outsider)
    db_session.commit()
    authenticated_client.headers["Authorization"] = f"Bearer {_token_for(outsider)}"
    r = authenticated_client.patch(f"/api/v1/payments/{pid}/cancel")
    assert r.status_code == status.HTTP_403_FORBIDDEN
