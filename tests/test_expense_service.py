# tests/test_expense_service.py
import pytest
from uuid import uuid4
from decimal import Decimal
from datetime import datetime
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.services.expense_service import (
    create_expense,
    get_expense_by_id,
    get_expenses_for_group,
    update_expense,
    delete_expense,
    calculate_equal_splits,
    validate_exact_splits,
    is_group_member,
    validate_group_member,
    get_group_members,
    get_group_or_404
)
from app.models.expenses import Expense, SplitType
from app.models.expense_splits import ExpenseSplit
from app.schemas.expenses import ExpenseCreate, ExpenseUpdate, ExpenseSplitDetail
from app.models.groups import Group, GroupStatus
from app.models.users import User
from app.models.group_members import GroupMember


def test_get_group_or_404_success(db_session: Session, test_group: Group):
    found_group = get_group_or_404(db_session, test_group.group_id)
    assert found_group.group_id == test_group.group_id


def test_get_group_or_404_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        get_group_or_404(db_session, uuid4())
    assert excinfo.value.status_code == status.HTTP_404_NOT_FOUND


def test_is_group_member_true(db_session: Session, test_group: Group, test_user: User):
    member = GroupMember(group_id=test_group.group_id, user_id=test_user.user_id, joined_at=datetime.utcnow())
    db_session.add(member)
    db_session.commit()
    assert is_group_member(db_session, test_group.group_id, test_user.user_id) is True


def test_is_group_member_false(db_session: Session, test_group: Group, test_user: User):
    assert is_group_member(db_session, test_group.group_id, test_user.user_id) is False


def test_validate_group_member_success(db_session: Session, test_group: Group, test_user: User):
    member = GroupMember(group_id=test_group.group_id, user_id=test_user.user_id, joined_at=datetime.utcnow())
    db_session.add(member)
    db_session.commit()
    validate_group_member(db_session, test_group.group_id, test_user.user_id, "Forbidden")


def test_validate_group_member_forbidden(db_session: Session, test_group: Group, test_user: User):
    with pytest.raises(HTTPException) as excinfo:
        validate_group_member(db_session, test_group.group_id, test_user.user_id, "Forbidden message")
    assert excinfo.value.status_code == status.HTTP_403_FORBIDDEN
    assert excinfo.value.detail == "Forbidden message"


def test_get_group_members_success(db_session: Session, test_group: Group, test_users: list[User]):
    member1 = GroupMember(group_id=test_group.group_id, user_id=test_users[0].user_id, joined_at=datetime.utcnow())
    member2 = GroupMember(group_id=test_group.group_id, user_id=test_users[1].user_id, joined_at=datetime.utcnow())
    db_session.add_all([member1, member2])
    db_session.commit()
    members = get_group_members(db_session, test_group.group_id)
    assert len(members) == 2
    assert {m.user_id for m in members} == {test_users[0].user_id, test_users[1].user_id}


def test_calculate_equal_splits_even(db_session: Session, test_group_with_members: Group):
    members = get_group_members(db_session, test_group_with_members.group_id)
    total_amount = Decimal("100.00")
    splits = calculate_equal_splits(total_amount, members)
    
    assert len(splits) == len(members)
    assert sum(s["amount_owed"] for s in splits) == total_amount
    for split in splits:
        assert split["amount_owed"] == (total_amount / len(members)).quantize(Decimal("0.01"))


def test_calculate_equal_splits_uneven(db_session: Session, test_group_with_members: Group):
    # Asegurarse de tener un número de miembros que genere un resto
    members = get_group_members(db_session, test_group_with_members.group_id)
    # Si tenemos más de 2 miembros, podemos forzar un resto.
    # Si la fixture test_group_with_members tiene 6 miembros, 100/6 no es exacto
    if len(members) < 3: # Asegurarse de que haya al menos 3 para que 100/3 sea inexacto
        test_group_with_members.group_id = uuid4() # Crear un grupo nuevo para no modificar la fixture
        db_session.add(test_group_with_members)
        db_session.add(GroupMember(group_id=test_group_with_members.group_id, user_id=uuid4(), joined_at=datetime.utcnow()))
        db_session.add(GroupMember(group_id=test_group_with_members.group_id, user_id=uuid4(), joined_at=datetime.utcnow()))
        db_session.add(GroupMember(group_id=test_group_with_members.group_id, user_id=uuid4(), joined_at=datetime.utcnow()))
        db_session.commit()
        members = get_group_members(db_session, test_group_with_members.group_id)

    total_amount = Decimal("100.00")
    splits = calculate_equal_splits(total_amount, members)

    assert len(splits) == len(members)
    assert sum(s["amount_owed"] for s in splits).quantize(Decimal("0.01")) == total_amount
    
    expected_base = (total_amount * 100 // len(members)) / Decimal("100")
    remainder_count = (total_amount * 100 % len(members))
    
    amounts = [s["amount_owed"] for s in splits]
    assert amounts.count(expected_base + Decimal("0.01")) == remainder_count
    assert amounts.count(expected_base) == len(members) - remainder_count


def test_calculate_equal_splits_empty_members(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        calculate_equal_splits(Decimal("100.00"), [])
    assert excinfo.value.status_code == status.HTTP_400_BAD_REQUEST
    assert excinfo.value.detail == "El grupo no tiene miembros"


def test_validate_exact_splits_success(db_session: Session, test_group_with_members: Group, test_users: list[User]):
    member_user_ids = [m.user_id for m in get_group_members(db_session, test_group_with_members.group_id)]
    
    # Asegúrate de que los usuarios de test_users sean miembros del grupo
    valid_splits_data = [
        ExpenseSplitDetail(user_id=member_user_ids[0], amount_owed=Decimal("50.00")),
        ExpenseSplitDetail(user_id=member_user_ids[1], amount_owed=Decimal("50.00"))
    ]
    total_amount = Decimal("100.00")
    validated_splits = validate_exact_splits(db_session, test_group_with_members.group_id, total_amount, valid_splits_data)
    
    assert len(validated_splits) == 2
    assert sum(s["amount_owed"] for s in validated_splits) == total_amount


def test_validate_exact_splits_no_splits(db_session: Session, test_group_with_members: Group):
    with pytest.raises(HTTPException) as excinfo:
        validate_exact_splits(db_session, test_group_with_members.group_id, Decimal("100.00"), [])
    assert excinfo.value.status_code == status.HTTP_400_BAD_REQUEST
    assert "Debe proporcionar las divisiones" in excinfo.value.detail


def test_validate_exact_splits_repeated_users(db_session: Session, test_group_with_members: Group, test_user: User):
    splits_data = [
        ExpenseSplitDetail(user_id=test_user.user_id, amount_owed=Decimal("50.00")),
        ExpenseSplitDetail(user_id=test_user.user_id, amount_owed=Decimal("50.00"))
    ]
    with pytest.raises(HTTPException) as excinfo:
        validate_exact_splits(db_session, test_group_with_members.group_id, Decimal("100.00"), splits_data)
    assert excinfo.value.status_code == status.HTTP_400_BAD_REQUEST
    assert "No puede haber usuarios repetidos" in excinfo.value.detail


def test_validate_exact_splits_non_member_user(db_session: Session, test_group: Group):
    non_member_user_id = uuid4()
    splits_data = [
        ExpenseSplitDetail(user_id=non_member_user_id, amount_owed=Decimal("100.00"))
    ]
    with pytest.raises(HTTPException) as excinfo:
        validate_exact_splits(db_session, test_group.group_id, Decimal("100.00"), splits_data)
    assert excinfo.value.status_code == status.HTTP_403_FORBIDDEN
    assert "Todos los usuarios de la división deben pertenecer al grupo" in excinfo.value.detail


def test_validate_exact_splits_invalid_amount(db_session: Session, test_group_with_members: Group, test_user: User):
    splits_data = [
        ExpenseSplitDetail(user_id=test_user.user_id, amount_owed=Decimal("0.00"))
    ]
    with pytest.raises(HTTPException) as excinfo:
        validate_exact_splits(db_session, test_group_with_members.group_id, Decimal("0.00"), splits_data)
    assert excinfo.value.status_code == status.HTTP_400_BAD_REQUEST
    assert "Los montos deben ser mayores a 0" in excinfo.value.detail


def test_validate_exact_splits_sum_mismatch(db_session: Session, test_group_with_members: Group, test_user: User):
    splits_data = [
        ExpenseSplitDetail(user_id=test_user.user_id, amount_owed=Decimal("60.00"))
    ]
    with pytest.raises(HTTPException) as excinfo:
        validate_exact_splits(db_session, test_group_with_members.group_id, Decimal("100.00"), splits_data)
    assert excinfo.value.status_code == status.HTTP_400_BAD_REQUEST
    assert "La suma de las divisiones" in excinfo.value.detail


def test_create_expense_equal_split_success(db_session: Session, test_group_with_members: Group, test_user: User):
    expense_data = ExpenseCreate(
        payer_user_id=test_user.user_id,
        title="Test Equal Split",
        total_amount=Decimal("150.00"),
        split_type=SplitType.EQUAL,
        expense_category="Entertainment",
        splits=None
    )
    expense = create_expense(db_session, test_group_with_members.group_id, expense_data, test_user.user_id)
    
    assert expense["title"] == "Test Equal Split"
    assert expense["total_amount"] == Decimal("150.00")
    assert expense["split_type"] == SplitType.EQUAL
    assert len(expense["splits"]) == len(get_group_members(db_session, test_group_with_members.group_id))
    assert sum(s.amount_owed for s in expense["splits"]) == expense["total_amount"]


def test_create_expense_exact_amount_split_success(db_session: Session, test_group_with_members: Group, test_users: list[User], test_user: User):
    member_user_ids = [m.user_id for m in get_group_members(db_session, test_group_with_members.group_id)]
    
    splits_data = [
        ExpenseSplitDetail(user_id=member_user_ids[0], amount_owed=Decimal("70.00")),
        ExpenseSplitDetail(user_id=member_user_ids[1], amount_owed=Decimal("30.00"))
    ]
    expense_data = ExpenseCreate(
        payer_user_id=test_user.user_id,
        title="Test Exact Split",
        total_amount=Decimal("100.00"),
        split_type=SplitType.EXACT_AMOUNT,
        expense_category="Shopping",
        splits=splits_data
    )
    expense = create_expense(db_session, test_group_with_members.group_id, expense_data, test_user.user_id)
    
    assert expense["title"] == "Test Exact Split"
    assert expense["total_amount"] == Decimal("100.00")
    assert expense["split_type"] == SplitType.EXACT_AMOUNT
    assert len(expense["splits"]) == 2
    assert sum(s.amount_owed for s in expense["splits"]) == expense["total_amount"]
    assert {s.user_id for s in expense["splits"]} == {member_user_ids[0], member_user_ids[1]}


def test_create_expense_group_not_found(db_session: Session, test_user: User):
    expense_data = ExpenseCreate(
        payer_user_id=test_user.user_id,
        title="Title", total_amount=Decimal("10.00"), split_type=SplitType.EQUAL, expense_category="Category"
    )
    with pytest.raises(HTTPException) as excinfo:
        create_expense(db_session, uuid4(), expense_data, test_user.user_id)
    assert excinfo.value.status_code == status.HTTP_404_NOT_FOUND


def test_create_expense_creator_not_member(db_session: Session, test_group: Group, test_user: User):
    non_member_user_id = uuid4()
    expense_data = ExpenseCreate(
        payer_user_id=test_user.user_id,
        title="Title", total_amount=Decimal("10.00"), split_type=SplitType.EQUAL, expense_category="Category"
    )
    with pytest.raises(HTTPException) as excinfo:
        create_expense(db_session, test_group.group_id, expense_data, non_member_user_id)
    assert excinfo.value.status_code == status.HTTP_403_FORBIDDEN
    assert "No tienes permisos" in excinfo.value.detail


def test_create_expense_payer_not_member(db_session: Session, test_group: Group, test_user: User):
    member = GroupMember(group_id=test_group.group_id, user_id=test_user.user_id, joined_at=datetime.utcnow())
    db_session.add(member)
    db_session.commit()
    non_member_payer_id = uuid4()
    expense_data = ExpenseCreate(
        payer_user_id=non_member_payer_id,
        title="Title", total_amount=Decimal("10.00"), split_type=SplitType.EQUAL, expense_category="Category"
    )
    with pytest.raises(HTTPException) as excinfo:
        create_expense(db_session, test_group.group_id, expense_data, test_user.user_id)
    assert excinfo.value.status_code == status.HTTP_403_FORBIDDEN
    assert "El usuario que paga" in excinfo.value.detail


def test_get_expense_by_id_success(db_session: Session, test_expense: Expense):
    expense = get_expense_by_id(db_session, test_expense.expense_id)
    assert expense["expense_id"] == test_expense.expense_id
    assert expense["title"] == test_expense.title
    assert len(expense["splits"]) > 0


def test_get_expense_by_id_not_found(db_session: Session):
    with pytest.raises(HTTPException) as excinfo:
        get_expense_by_id(db_session, uuid4())
    assert excinfo.value.status_code == status.HTTP_404_NOT_FOUND


def test_get_expenses_for_group_success(db_session: Session, test_group_with_members: Group, test_expense: Expense):
    # Crear un segundo gasto para el mismo grupo
    user_ids = [m.user_id for m in get_group_members(db_session, test_group_with_members.group_id)]
    second_expense_data = ExpenseCreate(
        payer_user_id=user_ids[0],
        title="Second Expense",
        total_amount=Decimal("50.00"),
        split_type=SplitType.EQUAL,
        expense_category="Transport",
        splits=None
    )
    second_expense = create_expense(db_session, test_group_with_members.group_id, second_expense_data, user_ids[0])

    expenses = get_expenses_for_group(db_session, test_group_with_members.group_id)
    assert len(expenses) == 2
    # Verifica el orden (más reciente primero)
    assert expenses[0]["expense_id"] == second_expense["expense_id"]
    assert expenses[1]["expense_id"] == test_expense.expense_id


def test_get_expenses_for_group_empty(db_session: Session, test_group: Group):
    expenses = get_expenses_for_group(db_session, test_group.group_id)
    assert len(expenses) == 0


def test_update_expense_title_success(db_session: Session, test_expense: Expense, test_user: User):
    update_data = ExpenseUpdate(title="Updated Dinner Title")
    updated_expense = update_expense(db_session, test_expense.expense_id, update_data, test_user.user_id)
    assert updated_expense["title"] == "Updated Dinner Title"
    assert updated_expense["expense_id"] == test_expense.expense_id


def test_update_expense_total_amount_equal_split(db_session: Session, test_expense: Expense, test_user: User):
    update_data = ExpenseUpdate(total_amount=Decimal("200.00"), split_type=SplitType.EQUAL)
    updated_expense = update_expense(db_session, test_expense.expense_id, update_data, test_user.user_id)
    assert updated_expense["total_amount"] == Decimal("200.00")
    assert updated_expense["split_type"] == SplitType.EQUAL
    # Verificar que los splits se recalcularon
    assert sum(s.amount_owed for s in updated_expense["splits"]) == Decimal("200.00")


def test_update_expense_total_amount_exact_split(db_session: Session, test_group_with_members: Group, test_expense: Expense, test_users: list[User], test_user: User):
    # Cambiar el tipo de split a EXACT_AMOUNT para el test
    current_members = get_group_members(db_session, test_group_with_members.group_id)
    splits_data = [
        ExpenseSplitDetail(user_id=current_members[0].user_id, amount_owed=Decimal("70.00")),
        ExpenseSplitDetail(user_id=current_members[1].user_id, amount_owed=Decimal("30.00"))
    ]
    update_data_to_exact = ExpenseUpdate(split_type=SplitType.EXACT_AMOUNT, total_amount=Decimal("100.00"), splits=splits_data)
    updated_expense_exact = update_expense(db_session, test_expense.expense_id, update_data_to_exact, test_user.user_id)
    assert updated_expense_exact["split_type"] == SplitType.EXACT_AMOUNT
    assert updated_expense_exact["total_amount"] == Decimal("100.00")
    assert sum(s.amount_owed for s in updated_expense_exact["splits"]) == Decimal("100.00")

    # Ahora, actualizar el monto total con EXACT_AMOUNT
    new_splits_data = [
        ExpenseSplitDetail(user_id=current_members[0].user_id, amount_owed=Decimal("80.00")),
        ExpenseSplitDetail(user_id=current_members[1].user_id, amount_owed=Decimal("40.00"))
    ]
    update_data_amount_change = ExpenseUpdate(total_amount=Decimal("120.00"), splits=new_splits_data)
    updated_expense_amount = update_expense(db_session, test_expense.expense_id, update_data_amount_change, test_user.user_id)
    assert updated_expense_amount["total_amount"] == Decimal("120.00")
    assert sum(s.amount_owed for s in updated_expense_amount["splits"]) == Decimal("120.00")


def test_update_expense_not_found(db_session: Session, test_user: User):
    update_data = ExpenseUpdate(title="Non Existent")
    with pytest.raises(HTTPException) as excinfo:
        update_expense(db_session, uuid4(), update_data, test_user.user_id)
    assert excinfo.value.status_code == status.HTTP_404_NOT_FOUND


def test_update_expense_forbidden(db_session: Session, test_expense: Expense):
    non_member_user_id = uuid4()
    update_data = ExpenseUpdate(title="Forbidden Update")
    with pytest.raises(HTTPException) as excinfo:
        update_expense(db_session, test_expense.expense_id, update_data, non_member_user_id)
    assert excinfo.value.status_code == status.HTTP_403_FORBIDDEN


def test_delete_expense_success(db_session: Session, test_expense: Expense, test_user: User):
    response = delete_expense(db_session, test_expense.expense_id, test_user.user_id)
    assert response == {"message": "Gasto eliminado correctamente"}
    
    with pytest.raises(HTTPException) as excinfo:
        get_expense_by_id(db_session, test_expense.expense_id)
    assert excinfo.value.status_code == status.HTTP_404_NOT_FOUND
    
    # Verificar que los splits también se eliminaron
    splits = db_session.query(ExpenseSplit).filter(ExpenseSplit.expense_id == test_expense.expense_id).all()
    assert len(splits) == 0


def test_delete_expense_not_found(db_session: Session, test_user: User):
    with pytest.raises(HTTPException) as excinfo:
        delete_expense(db_session, uuid4(), test_user.user_id)
    assert excinfo.value.status_code == status.HTTP_404_NOT_FOUND


def test_delete_expense_forbidden(db_session: Session, test_expense: Expense):
    non_member_user_id = uuid4()
    with pytest.raises(HTTPException) as excinfo:
        delete_expense(db_session, test_expense.expense_id, non_member_user_id)
    assert excinfo.value.status_code == status.HTTP_403_FORBIDDEN
