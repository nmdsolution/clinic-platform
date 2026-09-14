"""
Modèles ORM du module Caisse & Facturation.

Principe (cahier des charges §17-18-29) :
  - un acte réalisé => une ligne de facture ;
  - un encaissement => un reçu numéroté, rattaché à une session de caisse ;
  - toute action sensible est tracée dans AuditLog (traçabilité, pas de
    suppression silencieuse).
"""
import enum
from datetime import datetime

from sqlalchemy import (
    JSON,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base, now_utc


class Role(str, enum.Enum):
    ADMIN = "ADMIN"
    PROMOTRICE = "PROMOTRICE"
    DAF = "DAF"
    CAISSIER = "CAISSIER"
    SECRETAIRE = "SECRETAIRE"


class InvoiceStatus(str, enum.Enum):
    OPEN = "OPEN"                    # créée, aucun paiement
    PARTIALLY_PAID = "PARTIALLY_PAID"
    PAID = "PAID"
    CANCELLED = "CANCELLED"


class LineCategory(str, enum.Enum):
    CONSULTATION = "CONSULTATION"
    LABORATOIRE = "LABORATOIRE"
    IMAGERIE = "IMAGERIE"
    EXAMEN_FONCTIONNEL = "EXAMEN_FONCTIONNEL"
    MEDICAMENT = "MEDICAMENT"
    KINESITHERAPIE = "KINESITHERAPIE"
    DENTAIRE = "DENTAIRE"
    OPHTALMOLOGIE = "OPHTALMOLOGIE"
    SOINS = "SOINS"
    AUTRE = "AUTRE"


class PaymentMethod(str, enum.Enum):
    ESPECES = "ESPECES"
    MOBILE_MONEY = "MOBILE_MONEY"
    ORANGE_MONEY = "ORANGE_MONEY"
    VIREMENT = "VIREMENT"
    ASSURANCE = "ASSURANCE"
    GRATUITE = "GRATUITE"


class CashSessionStatus(str, enum.Enum):
    OPEN = "OPEN"
    CLOSED = "CLOSED"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    username: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(128))
    hashed_password: Mapped[str] = mapped_column(String(255))
    role: Mapped[Role] = mapped_column(Enum(Role), default=Role.CAISSIER)
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now_utc)


class Counter(Base):
    """Compteurs atomiques pour la numérotation (factures, reçus, ...)."""

    __tablename__ = "counters"

    name: Mapped[str] = mapped_column(String(64), primary_key=True)
    value: Mapped[int] = mapped_column(Integer, default=0)


class Invoice(Base):
    __tablename__ = "invoices"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    invoice_number: Mapped[str] = mapped_column(String(32), unique=True, index=True)

    # Référence légère vers OpenMRS : on ne duplique pas le dossier patient,
    # seulement l'identifiant (uuid) et un libellé d'affichage pratique.
    patient_uuid: Mapped[str] = mapped_column(String(64), index=True)
    patient_display: Mapped[str] = mapped_column(String(255))

    status: Mapped[InvoiceStatus] = mapped_column(Enum(InvoiceStatus), default=InvoiceStatus.OPEN)
    currency: Mapped[str] = mapped_column(String(8), default="FCFA")

    discount_amount: Mapped[int] = mapped_column(Integer, default=0)
    insurance_covered_amount: Mapped[int] = mapped_column(Integer, default=0)

    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=now_utc, onupdate=now_utc
    )

    cancelled_reason: Mapped[str | None] = mapped_column(String(255), nullable=True)

    lines: Mapped[list["InvoiceLine"]] = relationship(
        back_populates="invoice", cascade="all, delete-orphan"
    )
    payments: Mapped[list["Payment"]] = relationship(back_populates="invoice")
    created_by: Mapped["User"] = relationship()

    @property
    def total_amount(self) -> int:
        gross = sum(line.line_total for line in self.lines)
        return max(gross - self.discount_amount - self.insurance_covered_amount, 0)

    @property
    def amount_paid(self) -> int:
        return sum(p.amount for p in self.payments)

    @property
    def balance_due(self) -> int:
        return max(self.total_amount - self.amount_paid, 0)


class InvoiceLine(Base):
    __tablename__ = "invoice_lines"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    invoice_id: Mapped[int] = mapped_column(ForeignKey("invoices.id"))

    category: Mapped[LineCategory] = mapped_column(Enum(LineCategory))
    description: Mapped[str] = mapped_column(String(255))
    unit_price: Mapped[int] = mapped_column(Integer)
    quantity: Mapped[int] = mapped_column(Integer, default=1)

    # Référence vers l'objet source (ex: uuid d'un "order" OpenMRS) pour
    # respecter le principe "pas de double saisie" du cahier des charges.
    source_reference: Mapped[str | None] = mapped_column(String(128), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=now_utc)

    invoice: Mapped["Invoice"] = relationship(back_populates="lines")

    @property
    def line_total(self) -> int:
        return self.unit_price * self.quantity


class CashSession(Base):
    __tablename__ = "cash_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    opened_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    opened_at: Mapped[datetime] = mapped_column(DateTime, default=now_utc)
    opening_float: Mapped[int] = mapped_column(Integer, default=0)

    closed_by_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    closed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)

    counted_cash: Mapped[int | None] = mapped_column(Integer, nullable=True)
    counted_mobile_money: Mapped[int | None] = mapped_column(Integer, nullable=True)
    counted_other: Mapped[int | None] = mapped_column(Integer, nullable=True)
    variance: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notes: Mapped[str | None] = mapped_column(String(500), nullable=True)

    status: Mapped[CashSessionStatus] = mapped_column(
        Enum(CashSessionStatus), default=CashSessionStatus.OPEN
    )

    payments: Mapped[list["Payment"]] = relationship(back_populates="cash_session")
    opened_by: Mapped["User"] = relationship(foreign_keys=[opened_by_id])
    closed_by: Mapped["User | None"] = relationship(foreign_keys=[closed_by_id])

    @property
    def expected_amount(self) -> int:
        """Montant théorique en espèces : fonds de caisse + encaissements espèces."""
        cash_payments = sum(
            p.amount for p in self.payments if p.method == PaymentMethod.ESPECES
        )
        return self.opening_float + cash_payments


class Payment(Base):
    __tablename__ = "payments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    receipt_number: Mapped[str] = mapped_column(String(32), unique=True, index=True)

    invoice_id: Mapped[int] = mapped_column(ForeignKey("invoices.id"))
    cash_session_id: Mapped[int | None] = mapped_column(
        ForeignKey("cash_sessions.id"), nullable=True
    )

    amount: Mapped[int] = mapped_column(Integer)
    method: Mapped[PaymentMethod] = mapped_column(Enum(PaymentMethod))
    reference: Mapped[str | None] = mapped_column(String(128), nullable=True)

    received_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    received_at: Mapped[datetime] = mapped_column(DateTime, default=now_utc)

    invoice: Mapped["Invoice"] = relationship(back_populates="payments")
    cash_session: Mapped["CashSession | None"] = relationship(back_populates="payments")
    received_by: Mapped["User"] = relationship()


class AuditLog(Base):
    """Journal des modifications (cahier des charges §29)."""

    __tablename__ = "audit_logs"
    __table_args__ = (UniqueConstraint("entity_type", "entity_id", "performed_at", "action"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    entity_type: Mapped[str] = mapped_column(String(64))
    entity_id: Mapped[str] = mapped_column(String(64))
    action: Mapped[str] = mapped_column(String(64))
    performed_by_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    performed_at: Mapped[datetime] = mapped_column(DateTime, default=now_utc)
    details: Mapped[dict | None] = mapped_column(JSON, nullable=True)
