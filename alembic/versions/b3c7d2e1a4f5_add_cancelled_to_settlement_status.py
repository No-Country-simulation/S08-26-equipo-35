"""add CANCELLED to settlement_status_enum

Revision ID: b3c7d2e1a4f5
Revises: 9c2f1a4b7d3e
Create Date: 2026-09-29

Modulo Payments (CRUD completo): permite cancelar/rechazar pagos PENDING
sin borrar auditoria. CANCELLED no descuenta deuda (igual que PENDING).
"""

from typing import Sequence, Union

from alembic import op


# revision identifiers, used by Alembic.
revision: str = 'b3c7d2e1a4f5'
down_revision: Union[str, Sequence[str], None] = '9c2f1a4b7d3e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Postgres: agregar el nuevo valor al enum existente.
    # En SQLite este ALTER no aplica; se ignora el error.
    try:
        op.execute("ALTER TYPE settlement_status_enum ADD VALUE IF NOT EXISTS 'CANCELLED'")
    except Exception:
        pass


def downgrade() -> None:
    # Postgres no permite quitar un valor de un enum sin recrearlo;
    # no hacemos nada en downgrade para no perder datos.
    pass
