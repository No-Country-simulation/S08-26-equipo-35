import asyncio
from uuid import UUID

from fastapi import WebSocket
from starlette.websockets import WebSocketDisconnect


class ConnectionManager:
    def __init__(self) -> None:
        self.active_connections: dict[str, set[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, group_id: UUID | str, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self.active_connections.setdefault(str(group_id), set()).add(websocket)

    async def disconnect(self, group_id: UUID | str, websocket: WebSocket) -> None:
        group_key = str(group_id)
        async with self._lock:
            connections = self.active_connections.get(group_key)
            if connections is None:
                return
            connections.discard(websocket)
            if not connections:
                self.active_connections.pop(group_key, None)

    async def broadcast_to_group(
        self, group_id: UUID | str, message: dict
    ) -> None:
        group_key = str(group_id)
        async with self._lock:
            connections = tuple(self.active_connections.get(group_key, ()))

        disconnected = []
        for websocket in connections:
            try:
                await websocket.send_json(message)
            except (OSError, WebSocketDisconnect, RuntimeError):
                disconnected.append(websocket)

        for websocket in disconnected:
            await self.disconnect(group_key, websocket)

    async def send_personal(
        self, group_id: UUID | str, websocket: WebSocket, message: dict
    ) -> bool:
        try:
            await websocket.send_json(message)
            return True
        except (OSError, WebSocketDisconnect, RuntimeError):
            await self.disconnect(group_id, websocket)
            return False


manager = ConnectionManager()
