"""
Cubre: create_group_service, get_groups_service, get_detailGroup_service, update_group_service,
delete_group_service.

Se mockea la Session de SQLAlchemy para no depender de una DB real.
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
    delete_group_service,
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

        assert mock_db.add.call_count == 2  # Group + GroupMember del creador
        mock_db.flush.assert_called_once()
        mock_db.commit.assert_called_once()
        mock_db.refresh.assert_called_once()
        assert result is not None

    def test_create_group_uses_current_user_id_as_creator(self, mock_db, current_user):
        group_data = GroupCreate(name="Nuevo grupo")

        create_group_service(mock_db, group_data, current_user)

        added_group = mock_db.add.call_args_list[0][0][0]
        assert added_group.created_by_user_id == current_user.user_id

    def test_create_group_adds_creator_as_member(self, mock_db, current_user):
        group_data = GroupCreate(name="Nuevo grupo")

        create_group_service(mock_db, group_data, current_user)

        added_member = mock_db.add.call_args_list[1][0][0]
        assert isinstance(added_member, GroupMember)
        assert added_member.user_id == current_user.user_id

    def test_create_group_maps_name_to_group_name_column(self, mock_db, current_user):
        """Evita que vuelva a colarse el mismatch name/group_name."""
        group_data = GroupCreate(name="Nuevo grupo")

        create_group_service(mock_db, group_data, current_user)

        added_group = mock_db.add.call_args_list[0][0][0]
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

    def test_get_groups_empty_returns_empty_list(self, mock_db, current_user):
        mock_result = MagicMock()
        mock_result.scalars.return_value.all.return_value = []
        mock_db.execute.return_value = mock_result

        result = get_groups_service(mock_db, current_user)

        assert result == []

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

    def _mock_two_executes(self, mock_db, first, second):
        r1 = MagicMock()
        r1.scalar_one_or_none.return_value = first
        r2 = MagicMock()
        r2.scalar_one_or_none.return_value = second
        mock_db.execute.side_effect = [r1, r2]

    def test_get_detail_success(self, mock_db, current_user, fake_group):
        member = MagicMock(spec=GroupMember)
        self._mock_two_executes(mock_db, fake_group, member)

        result = get_detailGroup_service(mock_db, fake_group.group_id, current_user)

        assert result == fake_group

    def test_get_detail_not_found_raises_404(self, mock_db, current_user):
        mock_result = MagicMock()
        mock_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = mock_result

        with pytest.raises(HTTPException) as exc_info:
            get_detailGroup_service(mock_db, uuid4(), current_user)

        assert exc_info.value.status_code == 404

    def test_get_detail_forbidden_for_non_member(self, mock_db, current_user, fake_group):
        self._mock_two_executes(mock_db, fake_group, None)

        with pytest.raises(HTTPException) as exc_info:
            get_detailGroup_service(mock_db, fake_group.group_id, current_user)

        assert exc_info.value.status_code == 403


# ---------------------------------------------------------------------------
# update_group_service
# ---------------------------------------------------------------------------

class TestUpdateGroupService:

    def _mock_three_executes(self, mock_db, group, member, updated):
        r1 = MagicMock()
        r1.scalar_one_or_none.return_value = group
        r2 = MagicMock()
        r2.scalar_one_or_none.return_value = member
        r_update = MagicMock()  # resultado del UPDATE (no se usa)
        r3 = MagicMock()
        r3.scalar_one_or_none.return_value = updated
        mock_db.execute.side_effect = [r1, r2, r_update, r3]

    def test_update_group_success(self, mock_db, current_user, fake_group):
        data = UpdateGroup(group_name="Nombre actualizado")
        member = MagicMock(spec=GroupMember)

        self._mock_three_executes(mock_db, fake_group, member, fake_group)

        result = update_group_service(fake_group.group_id, data, mock_db, current_user)

        mock_db.commit.assert_called_once()
        assert result == fake_group

    def test_update_group_no_data_raises_422(self, mock_db, current_user, fake_group):
        data = UpdateGroup()  # sin campos seteados

        with pytest.raises(HTTPException) as exc_info:
            update_group_service(fake_group.group_id, data, mock_db, current_user)

        assert exc_info.value.status_code == 422
        mock_db.execute.assert_not_called()

    def test_update_group_not_found_raises_404(self, mock_db, current_user):
        data = UpdateGroup(group_name="No existe")

        select_result = MagicMock()
        select_result.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = select_result

        with pytest.raises(HTTPException) as exc_info:
            update_group_service(uuid4(), data, mock_db, current_user)

        assert exc_info.value.status_code == 404

    def test_update_group_forbidden_for_non_member(self, mock_db, current_user, fake_group):
        data = UpdateGroup(group_name="No soy miembro")

        r1 = MagicMock()
        r1.scalar_one_or_none.return_value = fake_group
        r2 = MagicMock()
        r2.scalar_one_or_none.return_value = None
        mock_db.execute.side_effect = [r1, r2]

        with pytest.raises(HTTPException) as exc_info:
            update_group_service(fake_group.group_id, data, mock_db, current_user)

        assert exc_info.value.status_code == 403


# ---------------------------------------------------------------------------
# delete_group_service
# ---------------------------------------------------------------------------

class TestDeleteGroupService:

    def test_delete_group_success(self, mock_db, current_user, fake_group):
        fake_group.created_by_user_id = current_user.user_id
        r1 = MagicMock()
        r1.scalar_one_or_none.return_value = fake_group
        r2 = MagicMock()
        r2.rowcount = 1
        mock_db.execute.side_effect = [r1, r2]

        delete_group_service(fake_group.group_id, mock_db, current_user)

        mock_db.commit.assert_called_once()

    def test_delete_group_not_found_raises_404(self, mock_db, current_user):
        r1 = MagicMock()
        r1.scalar_one_or_none.return_value = None
        mock_db.execute.return_value = r1

        with pytest.raises(HTTPException) as exc_info:
            delete_group_service(uuid4(), mock_db, current_user)

        assert exc_info.value.status_code == 404

    def test_delete_group_forbidden_for_non_creator(self, mock_db, current_user, fake_group):
        # fake_group.created_by_user_id es otro uuid (fixture) -> 403
        assert fake_group.created_by_user_id != current_user.user_id
        r1 = MagicMock()
        r1.scalar_one_or_none.return_value = fake_group
        mock_db.execute.return_value = r1

        with pytest.raises(HTTPException) as exc_info:
            delete_group_service(fake_group.group_id, mock_db, current_user)

        assert exc_info.value.status_code == 403