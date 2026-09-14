# app/api/v1/expenses.py
from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status
)
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.core.security import get_current_user
from app.models.users import User
from app.models.group_members import GroupMember

from app.schemas.expenses import (
    ExpenseCreate,
    ExpenseUpdate,
    ExpenseResponse
)

from app.services.expense_service import (
    create_expense,
    get_expense_by_id,
    get_expenses_for_group,
    update_expense,
    delete_expense
)


router = APIRouter()


# ============================================================
# CREATE EXPENSE
# ============================================================

@router.post(
    "/groups/{group_id}/expenses",
    response_model=ExpenseResponse,
    status_code=status.HTTP_201_CREATED
)
def create_group_expense(
    group_id: UUID,
    expense_data: ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return create_expense(
        db=db,
        group_id=group_id,
        expense_data=expense_data,
        current_user_id=current_user.user_id
    )


# ============================================================
# GET GROUP EXPENSES
# ============================================================

@router.get(
    "/groups/{group_id}/expenses",
    response_model=list[ExpenseResponse]
)
def get_group_expenses(
    group_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    member = (
        db.query(GroupMember)
        .filter(
            GroupMember.group_id == group_id,
            GroupMember.user_id == current_user.user_id
        )
        .first()
    )

    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No perteneces a este grupo"
        )

    return get_expenses_for_group(
        db,
        group_id
    )


# ============================================================
# GET EXPENSE
# ============================================================

@router.get(
    "/expenses/{expense_id}",
    response_model=ExpenseResponse
)
def get_expense(
    expense_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    expense = get_expense_by_id(
        db,
        expense_id
    )

    member = (
        db.query(GroupMember)
        .filter(
            GroupMember.group_id == expense["group_id"],
            GroupMember.user_id == current_user.user_id
        )
        .first()
    )

    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes acceso a este gasto"
        )

    return expense


# ============================================================
# UPDATE EXPENSE
# ============================================================

@router.put(
    "/expenses/{expense_id}",
    response_model=ExpenseResponse
)
def update_expense_endpoint(
    expense_id: UUID,
    expense_data: ExpenseUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return update_expense(
        db=db,
        expense_id=expense_id,
        expense_data=expense_data,
        current_user_id=current_user.user_id
    )


# ============================================================
# DELETE EXPENSE
# ============================================================

@router.delete(
    "/expenses/{expense_id}"
)
def delete_expense_endpoint(
    expense_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return delete_expense(
        db=db,
        expense_id=expense_id,
        current_user_id=current_user.user_id
    )

