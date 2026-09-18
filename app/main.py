# app/main.py
from fastapi import FastAPI
from app.api.v1.auth import router as auth_router
from app.api.v1.expenses import router as expenses_router
from app.api.v1.groups import router as groups_router
from app.api.v1.users import router as users_router

from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="SplitFlow API",
    description="Backend para división de gastos",
    version="1.0.0"
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

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # en desarrollo puedes dejarlo abierto
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)