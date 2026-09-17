from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.expenses import Expense, SplitType
from app.models.expense_splits import ExpenseSplit
from app.models.groups import Group
from app.models.group_members import GroupMember
from app.schemas.expenses import (
    ExpenseCreate,
    ExpenseUpdate
)


CENT = Decimal("0.01")


# ============================================================
# HELPERS
# ============================================================

def get_group_or_404(
    db: Session,
    group_id: UUID
):
    group = (
        db.query(Group)
        .filter(Group.group_id == group_id)
        .first()
    )

    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Grupo no encontrado"
        )

    return group


def is_group_member(
    db: Session,
    group_id: UUID,
    user_id: UUID
):
    return (
        db.query(GroupMember)
        .filter(
            GroupMember.group_id == group_id,
            GroupMember.user_id == user_id
        )
        .first()
        is not None
    )


def validate_group_member(
    db: Session,
    group_id: UUID,
    user_id: UUID,
    message: str
):
    if not is_group_member(
        db,
        group_id,
        user_id
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=message
        )


def get_group_members(
    db: Session,
    group_id: UUID
):
    return (
        db.query(GroupMember)
        .filter(
            GroupMember.group_id == group_id
        )
        .all()
    )


# ============================================================
# EQUAL SPLIT
# ============================================================

def calculate_equal_splits(
    total_amount: Decimal,
    members: list[GroupMember]
):
    if not members:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El grupo no tiene miembros"
        )

    # Trabajamos en centavos para evitar errores
    # de redondeo.
    total_cents = int(
        (total_amount * 100).quantize(Decimal("1"))
    )

    member_count = len(members)

    base_cents = total_cents // member_count
    remainder = total_cents % member_count

    splits = []

    for index, member in enumerate(members):

        amount_cents = base_cents

        # Repartimos los centavos sobrantes
        # entre los primeros miembros.
        if index < remainder:
            amount_cents += 1

        amount = (
            Decimal(amount_cents) / Decimal("100")
        ).quantize(CENT)

        splits.append({
            "user_id": member.user_id,
            "amount_owed": amount
        })

    return splits


# ============================================================
# EXACT AMOUNT
# ============================================================

def validate_exact_splits(
    db: Session,
    group_id: UUID,
    total_amount: Decimal,
    splits
):
    if not splits:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Debe proporcionar las divisiones "
                "cuando split_type es EXACT_AMOUNT"
            )
        )

    user_ids = [
        split.user_id
        for split in splits
    ]

    # No permitir usuarios repetidos
    if len(user_ids) != len(set(user_ids)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No puede haber usuarios repetidos en las divisiones"
        )

    for split in splits:

        if split.amount_owed <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Los montos deben ser mayores a 0"
            )

        validate_group_member(
            db,
            group_id,
            split.user_id,
            "Todos los usuarios de la división deben pertenecer al grupo"
        )

    total_splits = sum(
        (
            split.amount_owed
            for split in splits
        ),
        Decimal("0")
    )

    total_splits = total_splits.quantize(CENT)
    total_amount = total_amount.quantize(CENT)

    if total_splits != total_amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"La suma de las divisiones ({total_splits}) "
                f"debe coincidir con el total "
                f"({total_amount})"
            )
        )

    return [
        {
            "user_id": split.user_id,
            "amount_owed": split.amount_owed.quantize(CENT)
        }
        for split in splits
    ]


# ============================================================
# CREATE EXPENSE
# ============================================================

def create_expense(
    db: Session,
    group_id: UUID,
    expense_data: ExpenseCreate,
    current_user_id: UUID
):
    # 1. Verificar que el grupo exista
    get_group_or_404(
        db,
        group_id
    )

    # 2. Verificar que quien crea el gasto
    #    pertenece al grupo
    validate_group_member(
        db,
        group_id,
        current_user_id,
        "No tienes permisos para crear gastos en este grupo"
    )

    # 3. Verificar que el pagador pertenece
    #    al grupo
    validate_group_member(
        db,
        group_id,
        expense_data.payer_user_id,
        "El usuario que paga debe pertenecer al grupo"
    )

    # 4. Calcular las divisiones
    if expense_data.split_type == SplitType.EQUAL:

        members = get_group_members(
            db,
            group_id
        )

        splits = calculate_equal_splits(
            expense_data.total_amount,
            members
        )

    else:

        splits = validate_exact_splits(
            db,
            group_id,
            expense_data.total_amount,
            expense_data.splits
        )

    # 5. Crear Expense
    new_expense = Expense(
        group_id=group_id,
        payer_user_id=expense_data.payer_user_id,
        title=expense_data.title,
        total_amount=expense_data.total_amount,
        split_type=expense_data.split_type,
        expense_category=expense_data.expense_category
    )

    try:
        db.add(new_expense)

        # Obtener expense_id
        db.flush()

        # 6. Crear ExpenseSplit
        for split in splits:

            new_split = ExpenseSplit(
                expense_id=new_expense.expense_id,
                user_id=split["user_id"],
                amount_owed=split["amount_owed"]
            )

            db.add(new_split)

        db.commit()
        db.refresh(new_expense)

        return get_expense_by_id(
            db,
            new_expense.expense_id
        )

    except Exception:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al crear el gasto"
        )


# ============================================================
# GET EXPENSE BY ID
# ============================================================

def get_expense_by_id(
    db: Session,
    expense_id: UUID
):
    expense = (
        db.query(Expense)
        .filter(
            Expense.expense_id == expense_id
        )
        .first()
    )

    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado"
        )

    splits = (
        db.query(ExpenseSplit)
        .filter(
            ExpenseSplit.expense_id == expense_id
        )
        .all()
    )

    return {
        "expense_id": expense.expense_id,
        "group_id": expense.group_id,
        "payer_user_id": expense.payer_user_id,
        "title": expense.title,
        "total_amount": expense.total_amount,
        "split_type": expense.split_type,
        "expense_category": expense.expense_category,
        "created_at": expense.created_at,
        "splits": splits
    }


# ============================================================
# GET EXPENSES FOR GROUP
# ============================================================

def get_expenses_for_group(
    db: Session,
    group_id: UUID
):
    get_group_or_404(
        db,
        group_id
    )

    expenses = (
        db.query(Expense)
        .filter(
            Expense.group_id == group_id
        )
        .order_by(
            Expense.created_at.desc()
        )
        .all()
    )

    result = []

    for expense in expenses:

        splits = (
            db.query(ExpenseSplit)
            .filter(
                ExpenseSplit.expense_id == expense.expense_id
            )
            .all()
        )

        result.append({
            "expense_id": expense.expense_id,
            "group_id": expense.group_id,
            "payer_user_id": expense.payer_user_id,
            "title": expense.title,
            "total_amount": expense.total_amount,
            "split_type": expense.split_type,
            "expense_category": expense.expense_category,
            "created_at": expense.created_at,
            "splits": splits
        })

    return result


# ============================================================
# UPDATE EXPENSE
# ============================================================

def update_expense(
    db: Session,
    expense_id: UUID,
    expense_data: ExpenseUpdate,
    current_user_id: UUID
):
    expense = (
        db.query(Expense)
        .filter(
            Expense.expense_id == expense_id
        )
        .first()
    )

    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado"
        )

    # Verificar permisos
    validate_group_member(
        db,
        expense.group_id,
        current_user_id,
        "No tienes permisos para modificar este gasto"
    )

    # Valores actuales o nuevos
    payer_user_id = (
        expense_data.payer_user_id
        if expense_data.payer_user_id is not None
        else expense.payer_user_id
    )

    title = (
        expense_data.title
        if expense_data.title is not None
        else expense.title
    )

    total_amount = (
        expense_data.total_amount
        if expense_data.total_amount is not None
        else expense.total_amount
    )

    split_type = (
        expense_data.split_type
        if expense_data.split_type is not None
        else expense.split_type
    )

    expense_category = (
        expense_data.expense_category
        if expense_data.expense_category is not None
        else expense.expense_category
    )

    # Verificar payer
    validate_group_member(
        db,
        expense.group_id,
        payer_user_id,
        "El usuario que paga debe pertenecer al grupo"
    )

    # Recalcular divisiones
    if split_type == SplitType.EQUAL:

        members = get_group_members(
            db,
            expense.group_id
        )

        splits = calculate_equal_splits(
            total_amount,
            members
        )

    else:

        splits = validate_exact_splits(
            db,
            expense.group_id,
            total_amount,
            expense_data.splits
        )

    try:
        # Actualizar gasto
        expense.payer_user_id = payer_user_id
        expense.title = title
        expense.total_amount = total_amount
        expense.split_type = split_type
        expense.expense_category = expense_category

        # Eliminar divisiones anteriores
        (
            db.query(ExpenseSplit)
            .filter(
                ExpenseSplit.expense_id == expense_id
            )
            .delete(
                synchronize_session=False
            )
        )

        # Crear nuevas divisiones
        for split in splits:

            new_split = ExpenseSplit(
                expense_id=expense.expense_id,
                user_id=split["user_id"],
                amount_owed=split["amount_owed"]
            )

            db.add(new_split)

        db.commit()
        db.refresh(expense)

        return get_expense_by_id(
            db,
            expense_id
        )

    except Exception:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al actualizar el gasto"
        )


# ============================================================
# DELETE EXPENSE
# ============================================================

def delete_expense(
    db: Session,
    expense_id: UUID,
    current_user_id: UUID
):
    expense = (
        db.query(Expense)
        .filter(
            Expense.expense_id == expense_id
        )
        .first()
    )

    if not expense:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gasto no encontrado"
        )

    # Verificar permisos
    validate_group_member(
        db,
        expense.group_id,
        current_user_id,
        "No tienes permisos para eliminar este gasto"
    )

    try:
        # Primero eliminar divisiones
        (
            db.query(ExpenseSplit)
            .filter(
                ExpenseSplit.expense_id == expense_id
            )
            .delete(
                synchronize_session=False
            )
        )

        # Después eliminar gasto
        db.delete(expense)

        db.commit()

        return {
            "message": "Gasto eliminado correctamente"
        }

    except Exception:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error al eliminar el gasto"
        )

