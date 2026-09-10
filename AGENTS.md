# Contexto del Proyecto: SplitFlow

## 1. Propósito
Aplicación móvil para dividir gastos entre grupos de personas. Un usuario registra un gasto, el sistema calcula automáticamente quién debe a quién, y ofrece un algoritmo de liquidación que minimiza el número de transferencias necesarias para saldar todas las deudas.

## 2. Arquitectura (Modular Monolith)
- **Cliente**: Flutter mobile (grupos, gastos, balances, liquidación)
- **Backend**: FastAPI modular monolith
  - `app/api/v1/`: Routers REST (auth.py, groups.py, expenses.py, settlements.py)
  - `app/core/`: Configuración y seguridad (config.py, security.py)
  - `app/db/`: Sesión y base de SQLAlchemy (base.py, session.py)
  - `app/models/`: Modelos SQLAlchemy (users, groups, expenses, splits, settlements)
  - `app/schemas/`: Esquemas Pydantic (request/response)
  - `app/services/`: Lógica de negocio
  - `app/ws/`: WebSocket para tiempo real
- **Datos**: PostgreSQL (fuente de verdad) + Redis (pub/sub, cache)
- **Push**: Firebase Cloud Messaging (FCM)
- **Plataforma**: Docker Compose (dev) + GitHub Actions (CI/CD)

## 3. Stack Tecnológico
- Python 3.x, FastAPI, SQLAlchemy 2.0, Alembic
- PostgreSQL 15, Redis 7
- Pydantic v2, python-jose (JWT), passlib+bcrypt, Faker
- pytest + httpx (testing)
- **Gestor de dependencias: pip + venv + requirements.txt**

## 4. Flujo de Trabajo con el Entorno Virtual
```bash
# Crear el entorno virtual (solo la primera vez)
python -m venv .venv

# Activar el entorno (Windows PowerShell)
.venv\Scripts\Activate.ps1

# Activar el entorno (Windows CMD)
.venv\Scripts\activate.bat

# Activar el entorno (Git Bash / WSL)
source .venv/Scripts/activate

# Instalar dependencias
pip install -r requirements.txt

# Ejecutar la aplicación en desarrollo
uvicorn app.main:app --reload

# Aplicar migraciones
alembic upgrade head

# Cargar datos de prueba
python seed_db.py

# Ejecutar tests
pytest
```

## 5. Estructura de Carpetas Actual
```
.
├── alembic.ini
├── requirements.txt
├── seed_db.py
├── README.md
├── .gitignore
├── alembic/
│   ├── env.py
│   └── versions/          # 5 migraciones
└── app/
    ├── main.py            # Punto de entrada FastAPI
    ├── api/v1/auth.py     # Endpoints de autenticación
    ├── core/config.py     # Configuración
    ├── core/security.py   # JWT, hashing
    ├── db/base.py, session.py
    ├── models/            # 6 modelos SQLAlchemy
    ├── schemas/auth.py    # Schemas Pydantic (solo auth)
    ├── services/auth_service.py
    └── ws/                # WebSocket (vacío actualmente)
```

## 6. Estado Actual del Proyecto (al 10 Sep 2026)
### Completado
- Modelos de datos (User, Group, GroupMember, Expense, ExpenseParticipant, Payment)
- Migraciones Alembic (5 versiones)
- Autenticación JWT (register, login, tokens)
- Script de seed con datos de prueba

### En Progreso
- Endpoints CRUD de grupos y gastos (solo auth.py existe)

### Pendiente
- Docker Compose (dev environment)
- Endpoints CRUD completos (groups, expenses)
- Sistema de splits (equal, exact, percentage)
- Algoritmo de liquidación (min-cash-flow)
- WebSocket real-time sync
- Integración FCM (push notifications)
- Tests (integración + E2E)
- CI/CD (GitHub Actions)
- Optimización (queries, cache, pool)

## 7. Convenciones de Código
- FastAPI async handlers por defecto
- Pydantic v2 para validación
- SQLAlchemy 2.0 con sesiones async
- Routers separados por dominio en `app/api/v1/`
- Lógica de negocio en `app/services/`, no en routers
- Esquemas Pydantic separados de modelos SQLAlchemy
- Usar `pip install -r requirements.txt` para instalar dependencias
- Nunca versionar la carpeta del entorno virtual (`.venv/`, `env_*/`)

## 8. Comandos Esenciales
```bash
# Entorno virtual
python -m venv .venv                    # Crear (una sola vez)
.venv\Scripts\activate                  # Activar en Windows
pip install -r requirements.txt         # Instalar dependencias

# Base de datos
alembic upgrade head                    # Aplicar migraciones
alembic revision --autogenerate -m "msg"  # Nueva migración
python seed_db.py                       # Cargar datos de prueba

# Aplicación
uvicorn app.main:app --reload           # Desarrollo
pytest                                  # Tests
```

## 9. Flujo Principal del Dominio
`expense.created → balances recalculated → WebSocket broadcast + FCM notification`

## 10. Referencias
- Plan completo: 15 tareas en 4 semanas (Foundations → Core Logic → Integration → Polish)
- Diagrama de arquitectura: modular monolith con 4 capas (Cliente, App, Datos, Plataforma)
- Semana 1: Docker, modelos, JWT, CRUD básico
- Semana 2: WebSocket, splits, algoritmo de liquidación
- Semana 3: FCM, tests, integración Flutter
- Semana 4: Bug fixes, CI/CD, performance, demo