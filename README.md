# [SPLITFLOW-BACKEND]

Backend desarrollado con **FastAPI** para la gestión de autenticación y usuarios, diseñado para integrarse con aplicaciones móviles en **Flutter**.

## 🚀 Tecnologías Utilizadas

*   **Framework:** FastAPI
*   **Base de Datos:** PostgreSQL (vía SQLAlchemy)
*   **Autenticación:** JWT (JSON Web Tokens) y Bcrypt
*   **Migraciones:** Alembic
*   **Contenerización:** Docker & Docker Compose

## 📂 Estructura del Proyecto
```
SplitFlow_Backend/
├── app/
│   ├── api/           # Endpoints y Rutas (Auth, Users, Groups)
│   ├── core/          # Configuración central (Seguridad, JWT, Bcrypt)
│   ├── db/            # Conexión y sesión de Base de Datos
│   ├── models/        # Modelos ORM (SQLAlchemy)
│   ├── schemas/       # Validación de datos (Pydantic)
│   ├── services/      # Lógica de negocio compleja
│   ├── ws/            # WebSockets (Comunicación en tiempo real)
│   └── main.py        # Punto de entrada de FastAPI
├── alembic/           # Migraciones de base de datos
│   └── versions/      # Historial de cambios en la BD           
├── requirements.txt   # Dependencias del proyecto
└── seed_db.py         # Script para poblar datos de prueba
└── .env               # Variables de entorno (Ignorado por Git)
```

## ⚙️ Instalación Local

1.  Clona el repositorio:
    ```bash
    git clone https://github.com/No-Country-simulation/S08-26-equipo-35.git
    ```

2.  Crea y activa el entorno virtual:
    ```bash
    python -m venv nombre_venv
    nombre_venv\Scripts\activate  # En Windows
    ```

3.  Instala las dependencias:
    ```bash
    pip install -r requirements.txt
    ```

4.  Configura las variables de entorno:
    Crea un archivo `.env` basado en el ejemplo ,  o configura las siguientes variables:
    *   `DATABASE_URL`
    *   `SECRET_KEY`
    *   `ALGORITHM`

5.  Ejecuta las migraciones y rellena fake la base de datos:
    ```bash
    alembic upgrade head
    python seed_db.py
    ```

6.  Inicia el servidor:
    ```bash
    uvicorn app.main:app --reload
    ```

## 🐳 Uso con Docker

Para levantar todo el entorno (Base de datos + Backend) de forma persistente:

```bash
docker-compose up --build
```