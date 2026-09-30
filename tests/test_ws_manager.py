import asyncio
from uuid import uuid4
from unittest.mock import AsyncMock

from starlette.websockets import WebSocketDisconnect

from app.ws.manager import ConnectionManager


def test_connect_disconnect_and_broadcast():
    async def scenario():
        manager = ConnectionManager()
        group_id = uuid4()
        first = AsyncMock()
        second = AsyncMock()

        await manager.connect(group_id, first)
        await manager.connect(group_id, second)
        await manager.broadcast_to_group(group_id, {"type": "expense.created"})

        first.accept.assert_awaited_once()
        second.accept.assert_awaited_once()
        first.send_json.assert_awaited_once_with({"type": "expense.created"})
        second.send_json.assert_awaited_once_with({"type": "expense.created"})

        await manager.disconnect(group_id, first)
        assert manager.active_connections[str(group_id)] == {second}
        await manager.disconnect(group_id, second)
        assert str(group_id) not in manager.active_connections

    asyncio.run(scenario())


def test_broadcast_removes_unexpectedly_disconnected_socket():
    async def scenario():
        manager = ConnectionManager()
        group_id = uuid4()
        websocket = AsyncMock()
        websocket.send_json.side_effect = WebSocketDisconnect(code=1000)
        await manager.connect(group_id, websocket)

        await manager.broadcast_to_group(group_id, {"type": "expense.created"})

        assert str(group_id) not in manager.active_connections

    asyncio.run(scenario())


def test_broadcast_removes_socket_after_transport_error():
    async def scenario():
        manager = ConnectionManager()
        group_id = uuid4()
        websocket = AsyncMock()
        websocket.send_json.side_effect = OSError("transport closed")
        await manager.connect(group_id, websocket)

        await manager.broadcast_to_group(group_id, {"type": "expense.created"})

        assert str(group_id) not in manager.active_connections

    asyncio.run(scenario())
