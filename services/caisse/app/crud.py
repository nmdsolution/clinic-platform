"""Opérations métier : numérotation, création de factures/paiements, audit."""
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import models
from .database import now_utc


def next_sequence(db: Session, name: str) -> int:
    """Incrémente et retourne un compteur nommé, de façon atomique.

    Utilisé pour numéroter factures et reçus sans collision, même avec
    plusieurs caissiers connectés en même temps.
    """
    counter = db.get(models.Counter, name, with_for_update=True)
    if counter is None:
        counter = models.Counter(name=name, value=0)
        db.add(counter)
        db.flush()
        counter = db.get(models.Counter, name, with_for_update=True)
    counter.value += 1
    db.flush()
    return counter.value


def next_invoice_number(db: Session) -> str:
    year = now_utc().year
    seq = next_sequence(db, f"invoice-{year}")
    return f"FACE-{year}-{seq:06d}"


def next_receipt_number(db: Session) -> str:
    year = now_utc().year
    seq = next_sequence(db, f"receipt-{year}")
    return f"REC-{year}-{seq:06d}"


def log_action(
    db: Session,
    *,
    entity_type: str,
    entity_id: str,
    action: str,
    performed_by_id: int | None,
    details: dict | None = None,
) -> None:
    db.add(
        models.AuditLog(
            entity_type=entity_type,
            entity_id=entity_id,
            action=action,
            performed_by_id=performed_by_id,
            details=details or {},
        )
    )


def get_open_cash_session(db: Session) -> models.CashSession | None:
    stmt = select(models.CashSession).where(
        models.CashSession.status == models.CashSessionStatus.OPEN
    )
    return db.execute(stmt).scalars().first()


def refresh_invoice_status(invoice: models.Invoice) -> None:
    """Met à jour le statut d'une facture selon le solde restant dû."""
    if invoice.status == models.InvoiceStatus.CANCELLED:
        return
    if invoice.balance_due <= 0 and invoice.total_amount > 0:
        invoice.status = models.InvoiceStatus.PAID
    elif invoice.amount_paid > 0:
        invoice.status = models.InvoiceStatus.PARTIALLY_PAID
    else:
        invoice.status = models.InvoiceStatus.OPEN
