import anyio
import pytest
from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from app.models.groups import Group
from app.services import expense_service
from app.ws.manager import manager


def test_websocket_accepts_member_and_answers_ping(
    client: TestClient,
    test_group_with_members: Group,
    test_user_token: str,
):
    with client.websocket_connect(
        f"/ws/groups/{test_group_with_members.group_id}?token={test_user_token}"
    ) as websocket:
        websocket.send_json({"type": "ping"})
        assert websocket.receive_json() == {"type": "pong"}


def test_websocket_rejects_missing_token(client: TestClient, test_group: Group):
    with pytest.raises(WebSocketDisconnect):
        with client.websocket_connect(f"/ws/groups/{test_group.group_id}"):
            pass


def test_websocket_rejects_non_member(
    client: TestClient, test_group: Group, test_user_token: str
):
    with pytest.raises(WebSocketDisconnect):
        with client.websocket_connect(
            f"/ws/groups/{test_group.group_id}?token={test_user_token}"
        ):
            pass


def test_created_expense_is_broadcast_to_connected_member(
    authenticated_client: TestClient,
    test_group_with_members: Group,
    test_user,
    test_user_token: str,
    monkeypatch,
):
    def publish_to_connected_clients(group_id, event_type, payload):
        event = {
            "type": event_type,
            "group_id": str(group_id),
            "payload": payload,
        }
        anyio.from_thread.run(manager.broadcast_to_group, group_id, event)

    monkeypatch.setattr(expense_service, "publish_event", publish_to_connected_clients)
    path = f"/ws/groups/{test_group_with_members.group_id}?token={test_user_token}"

    with authenticated_client.websocket_connect(path) as websocket:
        response = authenticated_client.post(
            f"/api/v1/groups/{test_group_with_members.group_id}/expenses",
            json={
                "payer_user_id": str(test_user.user_id),
                "title": "Live expense",
                "total_amount": 24.0,
                "split_type": "EQUAL",
                "expense_category": "Food",
            },
        )
        assert response.status_code == 201, response.text
        assert websocket.receive_json()["type"] == "expense.created"
        assert websocket.receive_json()["type"] == "balance.updated"
