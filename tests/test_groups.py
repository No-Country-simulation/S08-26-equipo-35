"""
Cubre: create_group_service, get_groups_service, get_detailGroup_service, update_group_service
NO incluye tests de delete_group_service (pendiente, a pedido).

Se mockea la Session de SQLAlchemy para no depender de una DB real.
Ajustá los imports (paths) según la estructura real de tu proyecto.
"""

import pytest
from unittest.mock import MagicMock
from uuid import uuid4
from fastapi import HTTPException

from app.services.groups import (
    create_group_service,
    get_groups_service,
    get_detailGroup_service,
    update_group_service,
)
from app.models.groups import Group, GroupStatus
from app.models.group_members import GroupMember
from app.models.users import User
from app.schemas.groups import GroupCreate, UpdateGroup


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
    return user


@pytest.fixture
def fake_group():
    group = MagicMock(spec=Group)
    group.group_id = uuid4()
    group.group_name = "Grupo de prueba"
    group.status = GroupStatus.ACTIVE
    group.created_by_user_id = uuid4()
    return group


# ---------------------------------------------------------------------------
# create_group_service
# ---------------------------------------------------------------------------

class TestCreateGroupService:

    def test_create_group_success(self, mock_db, current_user):
        group_data = GroupCreate(name="Nuevo grupo")

        result = create_group_service(mock_db, group_data, current_user)

        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()
        assert result is not None

    def test_create_group_uses_current_user_id_as_creator(self, mock_db, current_user):
        group_data = GroupCreate(name="Nuevo grupo")

        create_group_service(mock_db, group_data, current_user)

        added_group = mock_db.add.call_args[0][0]
        assert added_group.created_by_user_id == current_user.user_id

    def test_create_group_maps_name_to_group_name_column(self, mock_db, current_user):
        """Evita que vuelva a colarse el mismatch name/group_name."""
        group_data = GroupCreate(name="Nuevo grupo")

        create_group_service(mock_db, group_data, current_user)

        added_group = mock_db.add.call_args[0][0]
        assert added_group.group_name == "Nuevo grupo"


# ---------------------------------------------------------------------------
# get_groups_service
# ---------------------------------------------------------------------------

class TestGetGroupsService:

    def test_get_groups_success(self, mock_db, current_user, fake_group):
        membership = MagicMock(spec=GroupMember)
        membership.group = fake_group

        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [membership]
        mock_db.execute.return_value = mock_result

        result = get_groups_service(mock_db, current_user)

        assert result == [fake_group]

    def test_get_groups_empty_raises_404(self, mock_db, current_user):
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_db.execute.return_value = mock_result

        with pytest.raises(HTTPException) as exc_info:
            get_groups_service(mock_db, current_user)

        assert exc_info.value.status_code == 404

    def test_get_groups_returns_group_not_groupmember(self, mock_db, current_user, fake_group):
        membership = MagicMock(spec=GroupMember)
        membership.group = fake_group

        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = [membership]
        mock_db.execute.return_value = mock_result

        result = get_groups_service(mock_db, current_user)

        # Verifica que devuelve objetos Group (con group_name), no GroupMember
        assert hasattr(result[0], "group_name")


# ---------------------------------------------------------------------------
# get_detailGroup_service
# ---------------------------------------------------------------------------

class TestGetDetailGroupService:

    def test_get_detail_success(self, mock_db, fake_group):
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = fake_group
        mock_db.execute.return_value = mock_result

        result = get_detailGroup_service(mock_db, fake_group.group_id)

        assert result == fake_group

    def test_get_detail_not_found_raises_404(self, mock_db):
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result

        with pytest.raises(HTTPException) as exc_info:
            get_detailGroup_service(mock_db, uuid4())

        assert exc_info.value.status_code == 404


# ---------------------------------------------------------------------------
# update_group_service
# ---------------------------------------------------------------------------

class TestUpdateGroupService:

    def test_update_group_success(self, mock_db, fake_group):
        data = UpdateGroup(group_name="Nombre actualizado")

        select_result = MagicMock()
        select_result.scalar_one_or_none.return_value = fake_group
        mock_db.execute.return_value = select_result

        result = update_group_service(fake_group.group_id, data, mock_db)

        mock_db.commit.assert_called_once()
        assert result == fake_group

    def test_update_group_no_data_raises_422(self, mock_db, fake_group):
        data = UpdateGroup()  # sin campos seteados

        with pytest.raises(HTTPException) as exc_info:
            update_group_service(fake_group.group_id, data, mock_db)

        assert exc_info.value.status_code == 422
        mock_db.execute.assert_not_called()

    def test_update_group_not_found_raises_404(self, mock_db):
        data = UpdateGroup(group_name="No existe")

        select_result = MagicMock()
        select_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = select_result

        with pytest.raises(HTTPException) as exc_info:
            update_group_service(uuid4(), data, mock_db)

        assert exc_info.value.status_code == 404