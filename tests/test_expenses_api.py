# tests/test_expenses_api.py
import pytest
from uuid import uuid4
from decimal import Decimal
from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.users import User
from app.models.groups import Group, GroupStatus
from app.models.group_members import GroupMember
from app.models.expenses import Expense, SplitType
from app.models.expense_splits import ExpenseSplit
from app.schemas.expenses import ExpenseCreate, ExpenseSplitDetail
from datetime import datetime, timedelta


def test_create_group_expense_equal_split_success(authenticated_client: TestClient, db_session: Session, test_group_with_members: Group, test_user: User):
    expense_data = {
        "payer_user_id": str(test_user.user_id),
        "title": "API Test Equal Split",
        "total_amount": 120.00,
        "split_type": "EQUAL",
        "expense_category": "Utilities"
    }
    response = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/expenses",
        json=expense_data
    )
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["title"] == "API Test Equal Split"
    assert Decimal(data["total_amount"]) == Decimal("120.00")
    assert data["split_type"] == "EQUAL"
    assert len(data["splits"]) == len(db_session.query(GroupMember).filter(GroupMember.group_id == test_group_with_members.group_id).all())
    assert sum(Decimal(s["amount_owed"]) for s in data["splits"]) == Decimal("120.00")


def test_create_group_expense_exact_amount_split_success(authenticated_client: TestClient, db_session: Session, test_group_with_members: Group, test_user: User, test_users: list[User]):
    # Asegurarse de que al menos 2 usuarios sean miembros del grupo
    members = db_session.query(GroupMember).filter(GroupMember.group_id == test_group_with_members.group_id).limit(2).all()
    
    splits_data = [
        {"user_id": str(members[0].user_id), "amount_owed": 75.50},
        {"user_id": str(members[1].user_id), "amount_owed": 24.50}
    ]
    expense_data = {
        "payer_user_id": str(test_user.user_id),
        "title": "API Test Exact Split",
        "total_amount": 100.00,
        "split_type": "EXACT_AMOUNT",
        "expense_category": "Shopping",
        "splits": splits_data
    }
    response = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/expenses",
        json=expense_data
    )
    assert response.status_code == status.HTTP_201_CREATED
    data = response.json()
    assert data["title"] == "API Test Exact Split"
    assert Decimal(data["total_amount"]) == Decimal("100.00")
    assert data["split_type"] == "EXACT_AMOUNT"
    assert len(data["splits"]) == 2
    assert sum(Decimal(s["amount_owed"]) for s in data["splits"]) == Decimal("100.00")


def test_create_group_expense_invalid_total_amount(authenticated_client: TestClient, test_group_with_members: Group, test_user: User):
    expense_data = {
        "payer_user_id": str(test_user.user_id),
        "title": "Invalid Amount",
        "total_amount": 0.00,  # Invalid amount
        "split_type": "EQUAL",
        "expense_category": "Food"
    }
    response = authenticated_client.post(
        f"/api/v1/groups/{test_group_with_members.group_id}/expenses",
        json=expense_data
    )
    assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY  # Pydantic validation error


def test_create_group_expense_creator_not_member(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User):
    # Crear un usuario que NO es miembro del grupo
    non_member_user = User(
        user_id=uuid4(),
        name="Non Member",
        email="nonmember@example.com",
        password_hash="hashed_password",
        preferred_payout_alias="nm_alias",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow()
    )
    db_session.add(non_member_user)
    db_session.commit()
    db_session.refresh(non_member_user)

    # Autenticar como el usuario no miembro
    from app.core.security import create_access_token
    from app.core.config import settings
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    non_member_token = create_access_token(
        data={"sub": non_member_user.email}, expires_delta=access_token_expires
    )
    authenticated_client.headers["Authorization"] = f"Bearer {non_member_token}"

    expense_data = {
        "payer_user_id": str(test_user.user_id), # Payer puede ser miembro, pero el creador no
        "title": "Forbidden Expense",
        "total_amount": 10.00,
        "split_type": "EQUAL",
        "expense_category": "Test"
    }
    response = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/expenses",
        json=expense_data
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "No tienes permisos para crear gastos en este grupo" in response.json()["detail"]


def test_get_group_expenses_success(authenticated_client: TestClient, db_session: Session, test_group_with_members: Group, test_expense: Expense, test_user: User):
    # Crear un segundo gasto para asegurar el orden
    members = db_session.query(GroupMember).filter(GroupMember.group_id == test_group_with_members.group_id).all()
    second_expense_data_create = ExpenseCreate(
        payer_user_id=members[0].user_id,
        title="Second Group Expense",
        total_amount=Decimal("50.00"),
        split_type=SplitType.EQUAL,
        expense_category="Transport",
        splits=None
    )
    from app.services.expense_service import create_expense
    second_expense_obj = create_expense(db_session, test_group_with_members.group_id, second_expense_data_create, test_user.user_id)


    response = authenticated_client.get(
        f"/api/v1/groups/{test_group_with_members.group_id}/expenses"
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert len(data) == 2
    # Verificar que el más reciente aparece primero
    assert data[0]["expense_id"] == str(second_expense_obj["expense_id"])
    assert data[1]["expense_id"] == str(test_expense.expense_id)


def test_get_group_expenses_forbidden(authenticated_client: TestClient, db_session: Session, test_group: Group):
    # Autenticar como un usuario que NO es miembro del grupo
    non_member_user = User(
        user_id=uuid4(),
        name="Non Member 2",
        email="nonmember2@example.com",
        password_hash="hashed_password",
        preferred_payout_alias="nm2_alias",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow()
    )
    db_session.add(non_member_user)
    db_session.commit()
    db_session.refresh(non_member_user)

    from app.core.security import create_access_token
    from app.core.config import settings
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    non_member_token = create_access_token(
        data={"sub": non_member_user.email}, expires_delta=access_token_expires
    )
    authenticated_client.headers["Authorization"] = f"Bearer {non_member_token}"

    response = authenticated_client.get(
        f"/api/v1/groups/{test_group.group_id}/expenses"
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "No perteneces a este grupo" in response.json()["detail"]


def test_get_expense_by_id_success(authenticated_client: TestClient, test_expense: Expense):
    response = authenticated_client.get(
        f"/api/v1/expenses/{test_expense.expense_id}"
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["expense_id"] == str(test_expense.expense_id)
    assert Decimal(data["total_amount"]) == test_expense.total_amount


def test_get_expense_by_id_not_found(authenticated_client: TestClient):
    response = authenticated_client.get(
        f"/api/v1/expenses/{uuid4()}"
    )
    assert response.status_code == status.HTTP_404_NOT_FOUND


def test_get_expense_by_id_forbidden(authenticated_client: TestClient, db_session: Session, test_group: Group, test_expense: Expense):
    # Crear un usuario que NO es miembro del grupo al que pertenece el gasto
    non_member_user = User(
        user_id=uuid4(),
        name="Non Member 3",
        email="nonmember3@example.com",
        password_hash="hashed_password",
        preferred_payout_alias="nm3_alias",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow()
    )
    db_session.add(non_member_user)
    db_session.commit()
    db_session.refresh(non_member_user)

    from app.core.security import create_access_token
    from app.core.config import settings
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    non_member_token = create_access_token(
        data={"sub": non_member_user.email}, expires_delta=access_token_expires
    )
    authenticated_client.headers["Authorization"] = f"Bearer {non_member_token}"

    response = authenticated_client.get(
        f"/api/v1/expenses/{test_expense.expense_id}"
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "No tienes acceso a este gasto" in response.json()["detail"]


def test_update_expense_success(authenticated_client: TestClient, db_session: Session, test_expense: Expense, test_user: User):
    update_data = {
        "title": "Updated API Expense",
        "total_amount": 150.00,
        "expense_category": "Updated Category",
        "split_type": "EQUAL"
    }
    response = authenticated_client.put(
        f"/api/v1/expenses/{test_expense.expense_id}",
        json=update_data
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["title"] == "Updated API Expense"
    assert Decimal(data["total_amount"]) == Decimal("150.00")
    assert data["expense_category"] == "Updated Category"
    assert data["split_type"] == "EQUAL"
    assert sum(Decimal(s["amount_owed"]) for s in data["splits"]) == Decimal("150.00")


def test_update_expense_not_found(authenticated_client: TestClient, test_user: User):
    update_data = {"title": "Not Found"}
    response = authenticated_client.put(
        f"/api/v1/expenses/{uuid4()}",
        json=update_data
    )
    assert response.status_code == status.HTTP_404_NOT_FOUND


def test_update_expense_forbidden(authenticated_client: TestClient, db_session: Session, test_expense: Expense):
    # Crear un usuario que NO es miembro del grupo al que pertenece el gasto
    non_member_user = User(
        user_id=uuid4(),
        name="Non Member 4",
        email="nonmember4@example.com",
        password_hash="hashed_password",
        preferred_payout_alias="nm4_alias",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow()
    )
    db_session.add(non_member_user)
    db_session.commit()
    db_session.refresh(non_member_user)

    from app.core.security import create_access_token
    from app.core.config import settings
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    non_member_token = create_access_token(
        data={"sub": non_member_user.email}, expires_delta=access_token_expires
    )
    authenticated_client.headers["Authorization"] = f"Bearer {non_member_token}"

    update_data = {"title": "Forbidden Update"}
    response = authenticated_client.put(
        f"/api/v1/expenses/{test_expense.expense_id}",
        json=update_data
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "No tienes permisos para modificar este gasto" in response.json()["detail"]


def test_delete_expense_success(authenticated_client: TestClient, db_session: Session, test_expense: Expense, test_user: User):
    expense_id_to_delete = test_expense.expense_id
    response = authenticated_client.delete(
        f"/api/v1/expenses/{expense_id_to_delete}"
    )
    assert response.status_code == status.HTTP_200_OK
    assert response.json() == {"message": "Gasto eliminado correctamente"}
    
    # Verificar que el gasto ya no existe
    response_get = authenticated_client.get(
        f"/api/v1/expenses/{expense_id_to_delete}"
    )
    assert response_get.status_code == status.HTTP_404_NOT_FOUND

    # Verificar que los splits asociados también se eliminaron
    splits_exist = db_session.query(ExpenseSplit).filter(ExpenseSplit.expense_id == expense_id_to_delete).first()
    assert splits_exist is None


def test_delete_expense_not_found(authenticated_client: TestClient, test_user: User):
    response = authenticated_client.delete(
        f"/api/v1/expenses/{uuid4()}"
    )
    assert response.status_code == status.HTTP_404_NOT_FOUND


def test_delete_expense_forbidden(authenticated_client: TestClient, db_session: Session, test_expense: Expense):
    # Crear un usuario que NO es miembro del grupo al que pertenece el gasto
    non_member_user = User(
        user_id=uuid4(),
        name="Non Member 5",
        email="nonmember5@example.com",
        password_hash="hashed_password",
        preferred_payout_alias="nm5_alias",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow()
    )
    db_session.add(non_member_user)
    db_session.commit()
    db_session.refresh(non_member_user)

    from app.core.security import create_access_token
    from app.core.config import settings
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    non_member_token = create_access_token(
        data={"sub": non_member_user.email}, expires_delta=access_token_expires
    )
    authenticated_client.headers["Authorization"] = f"Bearer {non_member_token}"

    response = authenticated_client.delete(
        f"/api/v1/expenses/{test_expense.expense_id}"
    )
    assert response.status_code == status.HTTP_403_FORBIDDEN
    assert "No tienes permisos para eliminar este gasto" in response.json()["detail"]

