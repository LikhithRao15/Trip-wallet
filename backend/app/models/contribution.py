import uuid

from datetime import datetime

from sqlalchemy import (
    BigInteger,
    DateTime,
    ForeignKey,
    String,
    Text,
    UniqueConstraint
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.database import Base


class Contribution(Base):

    __tablename__ = "contributions"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
    )

    trip_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"),
        nullable=False,
    )

    member_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
    )

    amount_paise: Mapped[int] = mapped_column(
        BigInteger,
        nullable=False,
    )

    payment_method: Mapped[str] = mapped_column(
        String(30),
        default="CASH",
        nullable=False,
    )

    status: Mapped[str] = mapped_column(
        String(20),
        default="CONFIRMED",
        nullable=False,
    )

    transaction_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("wallet_transactions.id"),
        nullable=True,
    )

    note: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    idempotency_key: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )

    request_hash: Mapped[str] = mapped_column(
        String(64),
        nullable=False,
    )

    __table_args__ = (
        UniqueConstraint(
            "trip_id",
            "idempotency_key",
            name="uq_contribution_idempotency",
        ),
    )