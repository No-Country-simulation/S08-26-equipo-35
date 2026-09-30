# tests/test_group_members.py
"""CRUD de miembros del grupo + verificacion de gasto con JSON correcto/malo.

- Solo el creador puede agregar/remover (403 si no).
- Cualquier miembro puede listar (403 si no es miembro).
- Agregar por user_id o email (xor). Duplicado -> 409.
"""
from datetime import datetime, timedelta
from uuid import uuid4

from fastapi import status
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.group_members import GroupMember
from app.models.groups import Group
from app.models.users import User


def _add_creator_as_member(db_session: Session, group: Group, user: User):
    db_session.add(
        GroupMember(
            group_id=group.group_id,
            user_id=user.user_id,
            joined_at=datetime.utcnow(),
        )
    )
    db_session.commit()


def _auth_as(authenticated_client: TestClient, email: str) -> TestClient:
    from app.core.security import create_access_token
    from app.core.config import settings

    token = create_access_token(
        data={"sub": email},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    authenticated_client.headers["Authorization"] = f"Bearer {token}"
    return authenticated_client


def _make_user(db_session: Session, name: str, email: str) -> User:
    user = User(
        user_id=uuid4(),
        name=name,
        email=email,
        password_hash="hashed_password",
        preferred_payout_alias="alias",
        preferred_payout_type="CBU",
        created_at=datetime.utcnow(),
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


# ---------------------------------------------------------------------------
# ADD
# ---------------------------------------------------------------------------

def test_add_member_by_email_201(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    target = test_users[0]

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members",
        json={"email": target.email},
    )
    assert r.status_code == status.HTTP_201_CREATED, r.text
    assert r.json()["user_id"] == str(target.user_id)


def test_add_member_by_user_id_201(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    target = test_users[1]

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members",
        json={"user_id": str(target.user_id)},
    )
    assert r.status_code == status.HTTP_201_CREATED, r.text
    assert r.json()["user_id"] == str(target.user_id)


def test_add_member_email_case_insensitive(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    target = test_users[0]

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members",
        json={"email": target.email.upper()},
    )
    assert r.status_code == status.HTTP_201_CREATED, r.text


def test_add_member_duplicate_409(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    target = test_users[0]
    r1 = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members", json={"email": target.email}
    )
    assert r1.status_code == status.HTTP_201_CREATED, r1.text

    r2 = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members", json={"email": target.email}
    )
    assert r2.status_code == status.HTTP_409_CONFLICT, r2.text


def test_add_member_user_not_found_404(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User):
    _add_creator_as_member(db_session, test_group, test_user)

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members",
        json={"user_id": str(uuid4())},
    )
    assert r.status_code == status.HTTP_404_NOT_FOUND, r.text


def test_add_member_group_not_found_404(authenticated_client: TestClient, test_user: User, test_users: list[User]):
    r = authenticated_client.post(
        f"/api/v1/groups/{uuid4()}/members",
        json={"user_id": str(test_users[0].user_id)},
    )
    assert r.status_code == status.HTTP_404_NOT_FOUND, r.text


def test_add_member_forbidden_for_non_creator(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    # miembro no-creador
    non_creator = test_users[0]
    db_session.add(GroupMember(group_id=test_group.group_id, user_id=non_creator.user_id, joined_at=datetime.utcnow()))
    db_session.commit()
    _auth_as(authenticated_client, non_creator.email)

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members",
        json={"user_id": str(test_users[1].user_id)},
    )
    assert r.status_code == status.HTTP_403_FORBIDDEN, r.text


def test_add_member_empty_payload_422(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User):
    _add_creator_as_member(db_session, test_group, test_user)

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members", json={}
    )
    assert r.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY, r.text


def test_add_member_both_fields_422(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)

    r = authenticated_client.post(
        f"/api/v1/groups/{test_group.group_id}/members",
        json={"user_id": str(test_users[0].user_id), "email": test_users[0].email},
    )
    assert r.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY, r.text


# ---------------------------------------------------------------------------
# LIST
# ---------------------------------------------------------------------------

def test_list_members_ok(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    db_session.add(GroupMember(group_id=test_group.group_id, user_id=test_users[0].user_id, joined_at=datetime.utcnow()))
    db_session.commit()

    r = authenticated_client.get(f"/api/v1/groups/{test_group.group_id}/members")
    assert r.status_code == status.HTTP_200_OK, r.text
    ids = {m["user_id"] for m in r.json()}
    assert str(test_user.user_id) in ids
    assert str(test_users[0].user_id) in ids


def test_list_members_forbidden_for_non_member(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User):
    outsider = _make_user(db_session, "Outsider", "outsider@example.com")
    _auth_as(authenticated_client, outsider.email)

    r = authenticated_client.get(f"/api/v1/groups/{test_group.group_id}/members")
    assert r.status_code == status.HTTP_403_FORBIDDEN, r.text


# ---------------------------------------------------------------------------
# REMOVE
# ---------------------------------------------------------------------------

def test_remove_member_ok(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    target = test_users[0]
    db_session.add(GroupMember(group_id=test_group.group_id, user_id=target.user_id, joined_at=datetime.utcnow()))
    db_session.commit()

    r = authenticated_client.delete(
        f"/api/v1/groups/{test_group.group_id}/members/{target.user_id}"
    )
    assert r.status_code == status.HTTP_200_OK, r.text

    # ya no lista al eliminado
    r2 = authenticated_client.get(f"/api/v1/groups/{test_group.group_id}/members")
    assert str(target.user_id) not in {m["user_id"] for m in r2.json()}


def test_remove_member_not_member_404(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)

    r = authenticated_client.delete(
        f"/api/v1/groups/{test_group.group_id}/members/{test_users[0].user_id}"
    )
    assert r.status_code == status.HTTP_404_NOT_FOUND, r.text


def test_remove_creator_400(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User):
    _add_creator_as_member(db_session, test_group, test_user)

    r = authenticated_client.delete(
        f"/api/v1/groups/{test_group.group_id}/members/{test_user.user_id}"
    )
    assert r.status_code == status.HTTP_400_BAD_REQUEST, r.text


def test_remove_member_forbidden_for_non_creator(authenticated_client: TestClient, db_session: Session, test_group: Group, test_user: User, test_users: list[User]):
    _add_creator_as_member(db_session, test_group, test_user)
    non_creator = test_users[0]
    target = test_users[1]
    db_session.add(GroupMember(group_id=test_group.group_id, user_id=non_creator.user_id, joined_at=datetime.utcnow()))
    db_session.add(GroupMember(group_id=test_group.group_id, user_id=target.user_id, joined_at=datetime.utcnow()))
    db_session.commit()
    _auth_as(authenticated_client, non_creator.email)

    r = authenticated_client.delete(
        f"/api/v1/groups/{test_group.group_id}/members/{target.user_id}"
    )
    assert r.status_code == status.HTTP_403_FORBIDDEN, r.text


# ---------------------------------------------------------------------------
# Gasto: JSON correcto -> 201, JSON incompleto -> 422 (no 500)
# ---------------------------------------------------------------------------

def test_expense_correct_json_201(authenticated_client: TestClient, db_session: Session, test_user: User):
    g = Group(
        group_id=uuid4(),
        group_name="Gasto OK",
        created_by_user_id=test_user.user_id,
        created_at=datetime.utcnow(),
    )
    db_session.add(g)
    db_session.commit()
    db_session.add(GroupMember(group_id=g.group_id, user_id=test_user.user_id, joined_at=datetime.utcnow()))
    db_session.commit()

    good = {
        "payer_user_id": str(test_user.user_id),
        "title": "Cena",
        "total_amount": 120.00,
        "split_type": "EQUAL",
        "expense_category": "Food",
    }
    r = authenticated_client.post(f"/api/v1/groups/{g.group_id}/expenses", json=good)
    assert r.status_code == status.HTTP_201_CREATED, r.text


def test_expense_bad_json_422_not_500(authenticated_client: TestClient, db_session: Session, test_user: User):
    g = Group(
        group_id=uuid4(),
        group_name="Gasto malo",
        created_by_user_id=test_user.user_id,
        created_at=datetime.utcnow(),
    )
    db_session.add(g)
    db_session.commit()
    db_session.add(GroupMember(group_id=g.group_id, user_id=test_user.user_id, joined_at=datetime.utcnow()))
    db_session.commit()

    bad = {"title": "Malo", "total_amount": 10, "split_type": "EQUAL"}
    r = authenticated_client.post(f"/api/v1/groups/{g.group_id}/expenses", json=bad)
    assert r.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY, r.text
