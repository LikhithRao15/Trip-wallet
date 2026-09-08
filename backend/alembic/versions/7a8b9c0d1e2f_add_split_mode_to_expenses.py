"""add split_mode to expenses

Revision ID: 7a8b9c0d1e2f
Revises: 69a2886ae660
Create Date: 2026-09-08 15:53:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '7a8b9c0d1e2f'
down_revision: Union[str, Sequence[str], None] = '69a2886ae660'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        'expenses',
        sa.Column(
            'split_mode',
            sa.String(length=20),
            server_default='EQUAL',
            nullable=False,
        ),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('expenses', 'split_mode')
