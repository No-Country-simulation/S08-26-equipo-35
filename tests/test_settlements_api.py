# tests/test_settlements_api.py
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import uuid4

from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.expenses import SplitType
from app.models.group_members import GroupMember
from app.models.groups import Group
from app.models.users import User
from app.schemas.expenses import ExpenseCreate
from app.services.expense_service import create_expense


def _seed_maria_example(db_session: Session, group: Group, maria: User, debtor: User):
    for title, category, amount in [
        ("Accommodation", "Lodging", "12000.00"),
        ("Groceries", "Food", "4000.00"),
        ("Transportation", "Transport", "2500.00"),
    ]:
        from app.schemas.expenses import ExpenseSplitDetail

        data = ExpenseCreate(
            payer_user_id=maria.user_id,
            title=title,
            total_amount=Decimal(amount),
            split_type=SplitType.EXACT_AMOUNT,
            expense_category=category,
            splits=[
                ExpenseSplitDetail(
                    user_id=debtor.user_id, amount_owed=Decimal(amount)
                )
            ],
        )
        create_expense(db_session, group.group_id, data, maria.user_id)


def test_get_balances_success(
    authenticated_client: TestClient,
    db_session: Session,
    test_group_with_members: Group,
    test_user: User,
    test_expense,
):
    response = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/balances"
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert len(data) > 0
    by_user = {row["user_id"]: row for row in data}
    assert str(test_user.user_id) in by_user
    # El pagador del fixture tiene neto positivo
    assert Decimal(by_user[str(test_user.user_id)]["net_balance"]) > 0


def test_get_debts_with_breakdown(
    authenticated_client: TestClient,
    db_session: Session,
    test_group_with_members: Group,
    test_user: User,
    test_users: list[User],
):
    maria = test_users[0]
    # Hacer a maria miembro ya lo es por la fixture; usarla como acreedora
    _seed_maria_example(db_session, test_group_with_members, maria, test_user)

    # Autenticarse como maria para consultar
    from app.core.config import settings
    from app.core.security import create_access_token

    token = create_access_token(
        data={"sub": maria.email},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    authenticated_client.headers["Authorization"] = f"Bearer {token}"

    response = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/debts"
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["is_settled"] is False
    mine = [d for d in data["debts"] if d["debtor_user_id"] == str(test_user.user_id)]
    assert len(mine) >= 1
    debt = mine[0]
    assert Decimal(debt["amount"]) > 0
    assert len(debt["expenses"]) >= 1
    assert all("title" in e and "amount" in e for e in debt["expenses"])


def test_get_my_debts(
    authenticated_client: TestClient,
    db_session: Session,
    test_group_with_members: Group,
    test_user: User,
    test_expense,
):
    response = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/debts/me"
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    for debt in data["debts"]:
        assert (
            debt["debtor_user_id"] == str(test_user.user_id)
            or debt["creditor_user_id"] == str(test_user.user_id)
        )


def test_get_debts_forbidden_for_non_member(
    authenticated_client: TestClient, db_session: Session, test_group: Group
):
    outsider = User(
        user_id=uuid4(),
        name="Outsider",
        email="outsider_sett@example.com",
        password_hash="hashed",
        preferred_payout_alias="x",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow(),
    )
    db_session.add(outsider)
    db_session.commit()

    from app.core.config import settings
    from app.core.security import create_access_token

    token = create_access_token(
        data={"sub": outsider.email},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    authenticated_client.headers["Authorization"] = f"Bearer {token}"

    response = authenticated_client.get(
        f"/api/v1/groups/{test_group.group_id}/debts"
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN


def test_payment_flow_settles_group(
    authenticated_client: TestClient,
    db_session: Session,
    test_group_with_members: Group,
    test_user: User,
    test_users: list[User],
):
    members = (
        db_session.query(GroupMember)
        .filter(GroupMember.group_id == test_group_with_members.group_id)
        .all()
    )
    debtor_id = next(
        m.user_id for m in members if m.user_id != test_user.user_id
    )

    # Gasto simple: test_user paga 100, division exacta solo al deudor
    from app.schemas.expenses import ExpenseSplitDetail

    data = ExpenseCreate(
        payer_user_id=test_user.user_id,
        title="Settle dinner",
        total_amount=Decimal("100.00"),
        split_type=SplitType.EXACT_AMOUNT,
        expense_category="Food",
        splits=[ExpenseSplitDetail(user_id=debtor_id, amount_owed=Decimal("100.00"))],
    )
    create_expense(db_session, test_group_with_members.group_id, data, test_user.user_id)

    # Status inicial: no saldado
    r = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/settlements/status"
    )
    assert r.status_code == status.HTTP_200_OK
    assert r.json()["is_settled"] is False

    # Registrar pago como el deudor
    from app.core.config import settings
    from app.core.security import create_access_token

    debtor = db_session.query(User).filter(User.user_id == debtor_id).first()
    token = create_access_token(
        data={"sub": debtor.email},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    authenticated_client.headers["Authorization"] = f"Bearer {token}"

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(test_user.user_id), "amount": 100.00},
    )
    assert r.status_code == status.HTTP_201_CREATED, r.text
    assert r.json()["status"] == "PENDING"
    settlement_id = r.json()["settlement_id"]

    # Confirmar pago -> PAID
    r = authenticated_client.patch(f"/api/v1/payments/{settlement_id}/pay")
    assert r.status_code == status.HTTP_200_OK
    assert r.json()["status"] == "PAID"

    # Volver a consultar: el pago puntual existe como PAID.
    r2 = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments"
    )
    assert r2.status_code == status.HTTP_200_OK
    paid = [p for p in r2.json() if p["settlement_id"] == settlement_id]
    assert len(paid) == 1 and paid[0]["status"] == "PAID"


def test_payment_amount_validation(
    authenticated_client: TestClient,
    db_session: Session,
    test_group_with_members: Group,
    test_user: User,
):
    # Monto 0 -> 422 de Pydantic
    response = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/payments",
        json={"receiver_user_id": str(test_user.user_id), "amount": 0},
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
