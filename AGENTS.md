# Contexto del Proyecto: SplitFlow

## 1. Propósito

Aplicación móvil para dividir gastos entre grupos de personas. Un usuario registra un gasto, el sistema calcula automáticamente quién debe a quién, y ofrece un algoritmo de liquidación que minimiza el número de transferencias necesarias para saldar todas las deudas.

## 2. Arquitectura (Modular Monolith)

- **Cliente**: Flutter mobile (grupos, gastos, balances, liquidación)
- **Backend**: FastAPI modular monolith
  - `app/api/v1/`: Routers REST (auth, groups, expenses, settlements, users, ws)
  - `app/core/`: Configuración y seguridad (config.py, security.py)
  - `app/db/`: Sesión y base de SQLAlchemy (base.py, session.py)
  - `app/models/`: Modelos SQLAlchemy (users, groups, group_members, expenses, expense_splits, settlements)
  - `app/schemas/`: Esquemas Pydantic (auth, groups, expenses, settlements, balances, users)
  - `app/services/`: Lógica de negocio (auth, groups, expenses, settlements, users)
  - `app/ws/`: ConnectionManager, autenticación WebSocket y Redis Pub/Sub para tiempo real
- **Datos**: PostgreSQL 15 (fuente de verdad) + Redis 7 (pub/sub, cache)
- **Push**: Firebase Cloud Messaging (FCM) — pendiente
- **Plataforma**: Docker Compose (dev) + GitHub Actions (CI/CD) — CI/CD pendiente

## 3. Stack Tecnológico

- Python 3.12, FastAPI, SQLAlchemy 2.0, Alembic
- PostgreSQL 15, Redis 7
- Pydantic v2, python-jose (JWT), passlib+bcrypt, Faker
- pytest + httpx (testing)
- **Gestor de dependencias**: pip + venv + requirements.txt

## 4. Flujo de Trabajo

### Con Docker Compose (recomendado)

```bash
# Levantar el stack completo (API + PostgreSQL + Redis)
docker compose up --build

# En otra terminal:
docker compose exec api alembic upgrade head
docker compose exec api python seed_db.py
docker compose exec api pytest -q

# Verificar Redis
docker compose exec redis redis-cli ping

# Detener sin borrar datos
docker compose down
```

### Sin Docker (entorno virtual)

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
pytest -q
```

## 5. Estructura de Carpetas Actual

```
.
├── alembic.ini
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── seed_db.py
├── README.md
├── README-docker.md
├── AGENTS.md
├── .gitignore
├── .dockerignore
├── .env.example
├── alembic/
│   ├── env.py
│   └── versions/          # 8 migraciones
├── app/
│   ├── main.py            # Punto de entrada FastAPI
│   ├── api/v1/
│   │   ├── auth.py        # Register, login
│   │   ├── groups.py      # CRUD de grupos
│   │   ├── expenses.py    # CRUD de gastos
│   │   ├── settlements.py # CRUD de liquidaciones
│   │   ├── users.py       # Perfil de usuario
│   │   └── ws.py          # Endpoint WebSocket por grupo
│   ├── core/
│   │   ├── config.py      # Configuración
│   │   └── security.py    # JWT, hashing
│   ├── db/
│   │   ├── base.py
│   │   └── session.py
│   ├── models/            # 6 modelos SQLAlchemy
│   ├── schemas/           # Schemas Pydantic (auth, groups, expenses, settlements, balances, users)
│   ├── services/          # Lógica de negocio (auth, groups, expenses, settlements, users)
│   └── ws/
│       ├── __init__.py    # Componentes WebSocket
│       ├── auth.py        # Autenticación JWT y membresía para WebSocket
│       ├── manager.py     # Conexiones activas y broadcast por grupo
│       └── redis_pubsub.py # Publicación y suscripción de eventos con Redis
├── docs/
│   ├── images/            # Diagramas de arquitectura, data model, flow, tracking plan
│   └── websocket.md       # Contrato de eventos en tiempo real
└── tests/                 # Tests unitarios e integración
```

## 6. Estado Actual del Proyecto (al 29 Sep 2026)

### Completado
- Modelos de datos (User, Group, GroupMember, Expense, ExpenseSplit, Settlement)
- Migraciones Alembic (8 versiones)
- Autenticación JWT (register, login, tokens)
- CRUD de grupos (create, list, detail, update, delete)
- CRUD de gastos (create, list, detail, update, delete)
- CRUD de usuarios (perfil, cambio de password)
- CRUD de settlements (create, list, detail, update status: PENDING, CONFIRMED, PAID, CANCELLED)
- Sistema de balances netos por usuario
- Sistema de splits: EQUAL, EXACT_AMOUNT
- Docker Compose (API + PostgreSQL 15 + Redis 7)
- WebSocket real-time sync por grupo, autenticación JWT y Redis Pub/Sub
- Script de seed con datos de prueba
- Tests unitarios e integración (groups, expenses, settlements, users, balances)

### En Progreso
- Ninguno (último PR mergeado)

### Pendiente
- Split type: PERCENTAGE
- Algoritmo de liquidación (min-cash-flow)
- Integración FCM (push notifications)
- Tests E2E (flujo completo)
- CI/CD (GitHub Actions)
- Optimización (queries, cache, pool)
- Limpieza: `.coverage` y `test.db` están commiteados (deberían estar en `.gitignore`)

## 7. Convenciones de Código

- FastAPI async handlers por defecto
- Pydantic v2 para validación
- SQLAlchemy 2.0 con sesiones async
- Routers separados por dominio en `app/api/v1/`
- Lógica de negocio en `app/services/`, no en routers
- Esquemas Pydantic separados de modelos SQLAlchemy
- Usar `pip install -r requirements.txt` para instalar dependencias
- Nunca versionar la carpeta del entorno virtual (`.venv/`, `env_*/`)
- Nunca versionar `.env`, `.coverage`, `*.db`, `*.pdf`, `*.tsv`

## 8. Comandos Esenciales

### Docker Compose

```bash
docker compose up --build              # Levantar stack completo
docker compose up -d --build           # Levantar en background
docker compose logs -f api             # Ver logs de la API
docker compose exec api pytest -q      # Correr tests
docker compose exec api alembic upgrade head
docker compose exec api python seed_db.py
docker compose exec redis redis-cli ping
docker compose down                    # Detener sin borrar datos
docker compose down -v                 # Detener y borrar volúmenes ⚠️
```

### Entorno virtual (sin Docker)

```bash
python -m venv .venv                    # Crear (una sola vez)
.venv\Scripts\activate                  # Activar en Windows
pip install -r requirements.txt         # Instalar dependencias
alembic upgrade head                    # Aplicar migraciones
alembic revision --autogenerate -m "msg"  # Nueva migración
python seed_db.py                       # Cargar datos de prueba
uvicorn app.main:app --reload           # Desarrollo
pytest -q                               # Tests
```

## 9. Flujo Principal del Dominio

```
expense.created → balances recalculados → WebSocket broadcast + FCM notification
```

Cuando un miembro registra un gasto:
1. El backend valida el payload (Pydantic) y la suma cero (splits = total).
2. Persiste el gasto y sus divisiones.
3. Recalcula los balances netos del grupo.
4. Emite un evento por WebSocket a los miembros conectados.
5. Envía una notificación push vía FCM.

## 10. Referencias

- **Plan completo**: 15 tareas en 4 semanas (Foundations → Core Logic → Integration → Polish)
- **Arquitectura objetivo**: modular monolith con 4 capas (Cliente, App, Datos, Plataforma)
- **Documentos de negocio**:
  - Especificaciones de Datos y Reglas de Negocio (v1.0) — Data Analyst
  - Arquitectura propuesta — Diagrama modular monolith
- **Semana 1**: Docker, modelos, JWT, CRUD básico ✅
- **Semana 2**: WebSocket, splits, min-cash-flow (parcial)
- **Semana 3**: FCM, tests, integración Flutter
- **Semana 4**: Bug fixes, CI/CD, performance, demo

## 11. WebSocket en tiempo real

El endpoint `WS /ws/groups/{group_id}?token=<JWT>` autentica al usuario y valida
su membresía antes de aceptar la conexión. Los eventos se publican por Redis
Pub/Sub y el contrato para Flutter está en `docs/websocket.md`.