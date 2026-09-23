# 🐳 SplitFlow — Entorno de desarrollo con Docker

Este documento explica cómo levantar el stack completo de SplitFlow
(API + PostgreSQL 15 + Redis 7) usando Docker Compose.

## ✅ Requisitos previos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y corriendo.
  - No es necesario iniciar sesión en Docker Hub para desarrollo local.
- Git.
- (Opcional) `make` si quieres usar los atajos del `Makefile`.

## 🚀 Quickstart (menos de 5 minutos)

```bash
# 1. Clonar el repo
git clone https://github.com/No-Country-simulation/S08-26-equipo-35.git
cd S08-26-equipo-35

# 2. Crear el archivo .env a partir del ejemplo
cp .env.example .env
# (Edita .env si necesitas cambiar algo; los valores por defecto funcionan)

# 3. Levantar el stack
docker compose up --build

# 4. En otra terminal, verificar que la API responde
curl http://localhost:8000/docs
```

La API estará disponible en:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

PostgreSQL estará disponible en `localhost:5432` y Redis en `localhost:6379`.

## 🛠️ Comandos útiles

### Levantar el stack en segundo plano

```bash
docker compose up -d --build
```

### Ver logs

```bash
# Todos los servicios
docker compose logs -f

# Solo la API
docker compose logs -f api
```

### Detener el stack

```bash
# Detener sin borrar datos
docker compose down

# Detener y borrar volúmenes (⚠️ borra la DB)
docker compose down -v
```

### Correr migraciones de Alembic

```bash
docker compose exec api alembic upgrade head
```

### Crear una nueva migración

```bash
docker compose exec api alembic revision --autogenerate -m "descripcion"
```

### Cargar datos de prueba

```bash
docker compose exec api python seed_db.py
```

### Correr los tests

```bash
docker compose exec api pytest -v
```

### Abrir una shell dentro del contenedor de la API

```bash
docker compose exec api bash
```

### Conectarse a PostgreSQL desde fuera

```bash
# Con psql local
psql -h localhost -p 5432 -U splitflow -d splitflow

# O dentro del contenedor
docker compose exec db psql -U splitflow -d splitflow
```

### Conectarse a Redis desde fuera

```bash
redis-cli -h localhost -p 6379
# o
docker compose exec redis redis-cli
```

## 📂 Estructura del stack

| Servicio | Imagen | Puerto host | Puerto interno | Volumen |
|---|---|---|---|---|
| `api` | `Dockerfile` local | 8000 | 8000 | `.:/app` (hot reload) |
| `db` | `postgres:15-alpine` | 5432 | 5432 | `postgres_data` |
| `redis` | `redis:7-alpine` | 6379 | 6379 | `redis_data` |

## 🔄 Flujo de trabajo recomendado

### Día a día

```bash
# Al empezar a trabajar
docker compose up -d

# Al terminar
docker compose down
```

### Cuando cambias `requirements.txt`

```bash
docker compose up -d --build
```

### Cuando cambias modelos y necesitas migración

```bash
docker compose exec api alembic revision --autogenerate -m "add campo X"
docker compose exec api alembic upgrade head
```

## 🐛 Troubleshooting

### El puerto 5432 ya está en uso

Tienes un PostgreSQL local corriendo. Opciones:
- Detén el PostgreSQL local.
- O cambia el puerto en `docker-compose.yml`: `"5433:5432"`.

### El puerto 8000 ya está en uso

Igual: cambia a `"8001:8000"` o detén lo que esté usando el 8000.

### `alembic upgrade head` falla con error de conexión

Verifica que el servicio `db` esté healthy:

```bash
docker compose ps
```

Si `db` no está healthy, revisa logs:

```bash
docker compose logs db
```

### Quiero empezar de cero (borrar la DB)

```bash
docker compose down -v
docker compose up --build
```

## 🔐 Seguridad

- **Nunca** commitees el archivo `.env` real. Solo `.env.example`.
- Si compartes credenciales con el equipo, usa un gestor de secretos
  (1Password, Bitwarden, Doppler), **nunca** PDFs, capturas o chats.
- Para producción, `SECRET_KEY` debe ser un string aleatorio largo
  (`python -c "import secrets; print(secrets.token_urlsafe(64))"`).

## 🔗 Referencias

- Plan de desarrollo: Semana 1 — Foundations
- Arquitectura objetivo: `Docker Compose — API + PostgreSQL + Redis (DEV ENV)`
- Issue relacionado: `#<ISSUE_NUMBER>`