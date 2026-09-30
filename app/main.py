# app/main.py
from fastapi import FastAPI
import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from app.api.v1.auth import router as auth_router
from app.api.v1.expenses import router as expenses_router
from app.api.v1.groups import router as groups_router
from app.api.v1.settlements import router as settlements_router
from app.api.v1.users import router as users_router
from app.api.v1.ws import router as ws_router
from app.ws.redis_pubsub import (
    close_redis_async,
    close_redis_sync,
    get_redis_async,
    subscribe_to_groups,
)

from fastapi.middleware.cors import CORSMiddleware

@asynccontextmanager
async def lifespan(app: FastAPI):
    redis_async = get_redis_async()
    pubsub_task = asyncio.create_task(subscribe_to_groups(redis_async))
    try:
        yield
    finally:
        pubsub_task.cancel()
        try:
            await pubsub_task
        except asyncio.CancelledError:
            pass
        await close_redis_async(redis_async)
        close_redis_sync()


app = FastAPI(
    title="SplitFlow API",
    description="Backend para división de gastos",
    version="1.0.0",
    lifespan=lifespan,
)

# Auth
app.include_router(
    auth_router,
    prefix="/api/v1",
    tags=["Auth"]
)

# Users
app.include_router(
    users_router,
    prefix="/api/v1",
    tags=["Users"]
)

# Expenses
app.include_router(
    expenses_router,
    prefix="/api/v1",
    tags=["Expenses"]
)

#Groups
app.include_router(
    groups_router,
    prefix="/api/v1",
    tags=["Groups"]
)

# Settlements
app.include_router(
    settlements_router,
    prefix="/api/v1",
    tags=["Settlements"]
)

app.include_router(ws_router, tags=["WebSocket"])

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # en desarrollo puedes dejarlo abierto
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)