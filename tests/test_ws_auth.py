from datetime import timedelta

import pytest
from fastapi import WebSocketException

from app.core.config import settings
from app.core.security import create_access_token
from app.models.group_members import GroupMember
from app.ws.auth import authenticate_ws, authorize_group_membership


def test_authenticate_ws_accepts_valid_token(
    db_session, test_user, test_user_token
):
    assert authenticate_ws(test_user_token, db_session) == test_user


@pytest.mark.parametrize("token", ["invalid", ""])
def test_authenticate_ws_rejects_invalid_token(token, db_session):
    with pytest.raises(WebSocketException):
        authenticate_ws(token, db_session)


def test_authenticate_ws_rejects_expired_token(db_session, test_user):
    token = create_access_token(
        {"sub": test_user.email}, expires_delta=timedelta(seconds=-1)
    )
    with pytest.raises(WebSocketException):
        authenticate_ws(token, db_session)


def test_authorize_group_membership_accepts_member(
    db_session, test_group_with_members, test_user
):
    authorize_group_membership(
        db_session, test_group_with_members.group_id, test_user.user_id
    )


def test_authorize_group_membership_rejects_non_member(
    db_session, test_group, test_user
):
    with pytest.raises(WebSocketException):
        authorize_group_membership(db_session, test_group.group_id, test_user.user_id)
