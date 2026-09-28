"""add PAID to settlement_status_enum

Revision ID: 9c2f1a4b7d3e
Revises: 5a7fb6d98b2f
Create Date: 2026-09-21

El modulo settlements usa estados PENDING / PAID.
CONFIRMED se conserva como valor legacy (se trata como PAID).
"""

from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = '9c2f1a4b7d3e'
down_revision: Union[str, Sequence[str], None] = '5a7fb6d98b2f'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Postgres: agregar el nuevo valor al enum existente.
    # En SQLite este ALTER no aplica; se ignora el error.
    try:
        op.execute("ALTER TYPE settlement_status_enum ADD VALUE IF NOT EXISTS 'PAID'")
    except Exception:
        pass


def downgrade() -> None:
    # Postgres no permite quitar un valor de un enum sin recrearlo;
    # no hacemos nada en downgrade para no perder datos.
    pass
