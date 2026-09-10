from logging.config import fileConfig

from sqlalchemy import engine_from_config
from sqlalchemy import pool

from alembic import context

# --- CONFIGURACIÓN PROFESIONAL (INICIO) ---
import sys
from pathlib import Path

# Asegura que Python encuentre la carpeta 'app' que está un nivel arriba
sys.path.append(str(Path(__file__).resolve().parent.parent))

from app.core.config import settings
from app.db.base import Base
from app.models.users import User  # Importamos la CLASE User del archivo users.py
#----------------------------------------------------------------------------------------

from app.models.groups import Group
from app.models.group_members import GroupMember
from app.models.expenses import Expense
from app.models.expense_splits import ExpenseSplit
from app.models.settlements import Settlement

# -------------------------------------------

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# add your model's MetaData object here
# for 'autogenerate' support
# target_metadata = mymodel.Base.metadata
target_metadata = Base.metadata  # <--- AQUÍ ESTÁ LA CLAVE: Conectamos con tu Base

# Sobrescribimos la URL de la BD con la variable de entorno segura
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

# other values from the config, defined by the needs of env.py,
# can be acquired:
# my_important_option = config.get_main_option("my_important_option")
# ... etc.


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    # Forzamos la URL desde nuestra config segura
    connectable.url = settings.DATABASE_URL

    with connectable.connect() as connection:
        context.configure(
            connection=connection, target_metadata=target_metadata
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()