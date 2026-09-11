# app/main.py
from fastapi import FastAPI
from app.api.v1.auth import router as auth_router


app = FastAPI(
    title="SplitFlow API",
    description="Backend para división de gastos",
    version="1.0.0"
)

# --> tags=["Auth"]: Agrupa los endpoints en Swagger (/docs) bajo la etiqueta "Auth".
app.include_router(auth_router, prefix="/api/v1", tags=["Auth"])


#======================================================================================================================
#======================================================================================================================


from fastapi.middleware.cors import CORSMiddleware



app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # en desarrollo puedes dejarlo abierto
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

