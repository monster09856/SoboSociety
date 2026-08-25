"""credit_ledger.booking_id foreign key

`bookings` tablosu Task 7'de geldi; bu sütunun başta FK'siz bırakılma sebebi
ortadan kalktı. FK olmadan `booking_id=999999` ile hayalet satır yazılabiliyor
ve aynı tablodaki `member_id` FK'li olduğu için bütünlük tutarsız kalıyordu.

Revision ID: e2f1d390ecf8
Revises: cef9c48efd75
Create Date: 2026-08-25 09:22:11.762763

"""
from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = 'e2f1d390ecf8'
down_revision: Union[str, Sequence[str], None] = 'cef9c48efd75'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Kısıt adı AÇIKÇA veriliyor: autogenerate `None` üretiyor ve o hâliyle
# downgrade `drop_constraint(None, ...)` ile patlar. Ad, PostgreSQL'in
# diğer FK'ler için ürettiği varsayılan kalıpla aynı.
KISIT_ADI = "credit_ledger_booking_id_fkey"


def upgrade() -> None:
    """Upgrade schema."""
    op.create_foreign_key(
        KISIT_ADI, "credit_ledger", "bookings", ["booking_id"], ["id"]
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint(KISIT_ADI, "credit_ledger", type_="foreignkey")
