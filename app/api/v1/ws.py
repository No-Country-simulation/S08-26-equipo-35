import asyncio
import time
from uuid import UUID

from fastapi import APIRouter, Depends, Query, WebSocket, WebSocketException, status
from sqlalchemy.orm import Session
from starlette.websockets import WebSocketDisconnect

from app.db.session import get_db
from app.ws.auth import authenticate_ws, authorize_group_membership
from app.ws.manager import manager

router = APIRouter()
HEARTBEAT_TIMEOUT_SECONDS = 60


@router.websocket("/ws/groups/{group_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    group_id: UUID,
    token: str = Query(...),
    db: Session = Depends(get_db),
) -> None:
    try:
        user = authenticate_ws(token, db)
        authorize_group_membership(db, group_id, user.user_id)
    except WebSocketException as exc:
        await websocket.close(code=exc.code, reason=exc.reason)
        return

    await manager.connect(group_id, websocket)
    last_ping = time.monotonic()
    try:
        while True:
            remaining = HEARTBEAT_TIMEOUT_SECONDS - (time.monotonic() - last_ping)
            try:
                message = await asyncio.wait_for(
                    websocket.receive_json(), timeout=max(remaining, 0)
                )
            except asyncio.TimeoutError:
                await websocket.close(
                    code=status.WS_1001_GOING_AWAY,
                    reason="Heartbeat timeout",
                )
                break
            except WebSocketDisconnect:
                break

            if isinstance(message, dict) and message.get("type") == "ping":
                last_ping = time.monotonic()
                if not await manager.send_personal(
                    group_id, websocket, {"type": "pong"}
                ):
                    break
    finally:
        await manager.disconnect(group_id, websocket)
