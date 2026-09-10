# app/db/session.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings # Aquí es donde usas tu .env

# 1. Creamos el motor usando la URL de tu .env
engine = create_engine(settings.DATABASE_URL, pool_pre_ping=True)

# 2. Creamos la fábrica de sesiones
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 3. La función mágica que usaremos en los endpoints
def get_db():
    db = SessionLocal()
    try:
        yield db # Esto mantiene la conexión abierta durante la petición
    finally:
        db.close() # Esto la cierra apenas termina la petición