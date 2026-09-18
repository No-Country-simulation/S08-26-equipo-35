"""
Se mockea la Session de SQLAlchemy para no depender de una DB real.
Ajustá los imports (paths) según la estructura real de tu proyecto.
"""

import pytest
from unittest.mock import MagicMock, patch
from uuid import uuid4
from fastapi import HTTPException

from app.services.users import (
    profile_service,
    update_service,
    delete_user_service,
)
from app.services.auth_service import (
    register_user_service,
    login_user_service,
    change_password_service,
)
from app.models.users import User
from app.schemas.users import UpdateUser
from app.schemas.auth import UserRegister, ChangePassword


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def mock_db():
    return MagicMock()


@pytest.fixture
def current_user():
    user = MagicMock(spec=User)
    user.user_id = uuid4()
    user.name = "Mario"
    user.email = "mario@example.com"
    user.password_hash = "hashed_old_password"
    return user


# ---------------------------------------------------------------------------
# profile_service
# ---------------------------------------------------------------------------

class TestProfileService:

    def test_profile_success(self, mock_db, current_user):
        mock_result = MagicMock()
        mock_result.scalars.return_value.first.return_value = current_user
        mock_db.execute.return_value = mock_result

        result = profile_service(mock_db, current_user)

        assert result == current_user

    def test_profile_not_found_raises_404(self, mock_db, current_user):
        mock_result = MagicMock()
        mock_result.scalars.return_value.first.return_value = None
        mock_db.execute.return_value = mock_result

        with pytest.raises(HTTPException) as exc_info:
            profile_service(mock_db, current_user)

        assert exc_info.value.status_code == 404


# ---------------------------------------------------------------------------
# update_service
# ---------------------------------------------------------------------------

class TestUpdateService:

    def test_update_success(self, mock_db, current_user):
        data = UpdateUser(name="Nuevo nombre")

        select_result = MagicMock()
        select_result.scalars.return_value.first.return_value = current_user
        mock_db.execute.return_value = select_result

        result = update_service(mock_db, data, current_user)

        mock_db.commit.assert_called_once()
        assert result == current_user

    def test_update_no_data_raises_422(self, mock_db, current_user):
        data = UpdateUser()  # sin campos seteados

        with pytest.raises(HTTPException) as exc_info:
            update_service(mock_db, data, current_user)

        assert exc_info.value.status_code == 422
        mock_db.execute.assert_not_called()

    def test_update_user_not_found_raises_404(self, mock_db, current_user):
        data = UpdateUser(name="Nuevo nombre")

        select_result = MagicMock()
        select_result.scalars.return_value.first.return_value = None
        mock_db.execute.return_value = select_result

        with pytest.raises(HTTPException) as exc_info:
            update_service(mock_db, data, current_user)

        assert exc_info.value.status_code == 404


# ---------------------------------------------------------------------------
# delete_user_service
# ---------------------------------------------------------------------------

class TestDeleteUserService:

    def test_delete_success(self, mock_db, current_user):
        select_result = MagicMock()
        select_result.scalars.return_value.first.return_value = current_user
        mock_db.execute.return_value = select_result

        result = delete_user_service(mock_db, current_user)

        mock_db.commit.assert_called_once()
        assert result == {"message": "Usuario eliminado correctamente"}

    def test_delete_user_not_found_raises_404(self, mock_db, current_user):
        select_result = MagicMock()
        select_result.scalars.return_value.first.return_value = None
        mock_db.execute.return_value = select_result

        with pytest.raises(HTTPException) as exc_info:
            delete_user_service(mock_db, current_user)

        assert exc_info.value.status_code == 404


# ---------------------------------------------------------------------------
# register_user_service
# ---------------------------------------------------------------------------

class TestRegisterUserService:

    def test_register_success(self, mock_db):
        user_data = UserRegister(
            name="Mario",
            email="mario@example.com",
            password="Password123!",
        )

        # db.query(User).filter(...).first() -> None (no existe todavía)
        mock_db.query.return_value.filter.return_value.first.return_value = None

        with patch("app.services.auth_service.hash_password", return_value="hashed_pw") as mock_hash:
            result = register_user_service(mock_db, user_data)

        mock_hash.assert_called_once_with("Password123!")
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()

        added_user = mock_db.add.call_args[0][0]
        assert added_user.email == "mario@example.com"
        assert added_user.password_hash == "hashed_pw"

    def test_register_duplicate_email_raises_400(self, mock_db, current_user):
        user_data = UserRegister(
            name="Mario",
            email="mario@example.com",
            password="Password123!",
        )

        # db.query(User).filter(...).first() -> ya existe
        mock_db.query.return_value.filter.return_value.first.return_value = current_user

        with pytest.raises(HTTPException) as exc_info:
            register_user_service(mock_db, user_data)

        assert exc_info.value.status_code == 400
        mock_db.add.assert_not_called()


# ---------------------------------------------------------------------------
# login_user_service
# ---------------------------------------------------------------------------

class TestLoginUserService:

    def test_login_success(self, mock_db, current_user):
        mock_db.query.return_value.filter.return_value.first.return_value = current_user

        with patch("app.services.auth_service.verify_password", return_value=True):
            result = login_user_service(mock_db, current_user.email, "correct_password")

        assert result == current_user

    def test_login_user_not_found_raises_400(self, mock_db):
        mock_db.query.return_value.filter.return_value.first.return_value = None

        with pytest.raises(HTTPException) as exc_info:
            login_user_service(mock_db, "noexiste@example.com", "cualquier_pass")

        assert exc_info.value.status_code == 400

    def test_login_wrong_password_raises_400(self, mock_db, current_user):
        mock_db.query.return_value.filter.return_value.first.return_value = current_user

        with patch("app.services.auth_service.verify_password", return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                login_user_service(mock_db, current_user.email, "wrong_password")

        assert exc_info.value.status_code == 400


# ---------------------------------------------------------------------------
# change_password_service
# ---------------------------------------------------------------------------

class TestChangePasswordService:

    def test_change_password_success(self, mock_db, current_user):
        data = ChangePassword(
            old_password="OldPassword123!",
            new_password="NewPassword123!",
        )

        select_result = MagicMock()
        select_result.scalars.return_value.first.return_value = current_user
        mock_db.execute.return_value = select_result

        with patch("app.services.auth_service.verify_password", return_value=True), \
             patch("app.services.auth_service.hash_password", return_value="new_hashed_pw"):
            result = change_password_service(mock_db, data, current_user)

        mock_db.commit.assert_called_once()
        assert result == current_user

    def test_change_password_wrong_old_password_raises_400(self, mock_db, current_user):
        data = ChangePassword(
            old_password="WrongOldPassword!",
            new_password="NewPassword123!",
        )

        with patch("app.services.auth_service.verify_password", return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                change_password_service(mock_db, data, current_user)

        assert exc_info.value.status_code == 400
        mock_db.execute.assert_not_called()