from decimal import Decimal

import pytest
from fastapi import HTTPException

from app.models.expenses import SplitType
from app.schemas.expenses import ExpenseCreate, ExpenseSplitDetail, ExpenseUpdate
from app.services import expense_service, settlement_service


def test_expense_update_and_delete_emit_events(
    db_session, test_expense, test_user, monkeypatch
):
    events = []
    monkeypatch.setattr(
        expense_service,
        "publish_event",
        lambda group_id, event_type, payload: events.append(event_type),
    )

    expense_service.update_expense(
        db_session,
        test_expense.expense_id,
        ExpenseUpdate(title="Updated dinner"),
        test_user.user_id,
    )
    expense_service.delete_expense(
        db_session, test_expense.expense_id, test_user.user_id
    )

    assert events == [
        "expense.updated",
        "balance.updated",
        "expense.deleted",
        "balance.updated",
    ]


def _register_pending_payment(db_session, group, payer, creditor):
    expense = ExpenseCreate(
        payer_user_id=creditor.user_id,
        title="Shared meal",
        total_amount=Decimal("15.00"),
        split_type=SplitType.EXACT_AMOUNT,
        expense_category="Food",
        splits=[
            ExpenseSplitDetail(
                user_id=payer.user_id,
                amount_owed=Decimal("15.00"),
            )
        ],
    )
    expense_service.create_expense(
        db_session, group.group_id, expense, creditor.user_id
    )
    return settlement_service.register_payment(
        db_session,
        group.group_id,
        payer.user_id,
        creditor.user_id,
        Decimal("15.00"),
    )


def test_pending_settlement_created_and_cancelled_do_not_update_balances(
    db_session, test_group_with_members, test_user, test_users, monkeypatch
):
    events = []
    monkeypatch.setattr(
        settlement_service,
        "publish_event",
        lambda group_id, event_type, payload: events.append(event_type),
    )
    payment = _register_pending_payment(
        db_session, test_group_with_members, test_user, test_users[0]
    )

    settlement_service.cancel_payment(
        db_session, payment.settlement_id, test_user.user_id
    )

    assert events == ["settlement.created", "settlement.cancelled"]


def test_paid_settlement_emits_balance_update_and_cannot_be_cancelled(
    db_session, test_group_with_members, test_user, test_users, monkeypatch
):
    events = []
    monkeypatch.setattr(
        settlement_service,
        "publish_event",
        lambda group_id, event_type, payload: events.append(event_type),
    )
    payment = _register_pending_payment(
        db_session, test_group_with_members, test_user, test_users[0]
    )
    events.clear()

    settlement_service.mark_payment_paid(
        db_session, payment.settlement_id, test_user.user_id
    )
    assert events == ["settlement.paid", "balance.updated"]

    with pytest.raises(HTTPException):
        settlement_service.cancel_payment(
            db_session, payment.settlement_id, test_user.user_id
        )
    assert events == ["settlement.paid", "balance.updated"]
