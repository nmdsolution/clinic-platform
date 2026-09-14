from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import crud, models, schemas
from ..database import get_db
from ..security import get_current_user, require_roles

router = APIRouter(prefix="/invoices", tags=["Facturation"])


@router.post("", response_model=schemas.InvoiceOut, status_code=status.HTTP_201_CREATED)
def create_invoice(
    payload: schemas.InvoiceCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    invoice = models.Invoice(
        invoice_number=crud.next_invoice_number(db),
        patient_uuid=payload.patient_uuid,
        patient_display=payload.patient_display,
        discount_amount=payload.discount_amount,
        insurance_covered_amount=payload.insurance_covered_amount,
        created_by_id=current_user.id,
    )
    for line in payload.lines:
        invoice.lines.append(
            models.InvoiceLine(
                category=line.category,
                description=line.description,
                unit_price=line.unit_price,
                quantity=line.quantity,
                source_reference=line.source_reference,
            )
        )

    db.add(invoice)
    db.flush()
    crud.log_action(
        db,
        entity_type="Invoice",
        entity_id=invoice.invoice_number,
        action="CREATE",
        performed_by_id=current_user.id,
        details={"patient": invoice.patient_display, "lines_count": len(invoice.lines)},
    )
    db.commit()
    db.refresh(invoice)
    return invoice


@router.get("", response_model=list[schemas.InvoiceOut])
def list_invoices(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
    patient_uuid: str | None = None,
    status_filter: models.InvoiceStatus | None = Query(default=None, alias="status"),
    date_from: date | None = None,
    date_to: date | None = None,
):
    stmt = select(models.Invoice)
    if patient_uuid:
        stmt = stmt.where(models.Invoice.patient_uuid == patient_uuid)
    if status_filter:
        stmt = stmt.where(models.Invoice.status == status_filter)
    if date_from:
        stmt = stmt.where(models.Invoice.created_at >= datetime.combine(date_from, datetime.min.time()))
    if date_to:
        stmt = stmt.where(models.Invoice.created_at <= datetime.combine(date_to, datetime.max.time()))
    stmt = stmt.order_by(models.Invoice.created_at.desc())
    return db.execute(stmt).scalars().all()


@router.get("/{invoice_id}", response_model=schemas.InvoiceOut)
def get_invoice(
    invoice_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    invoice = db.get(models.Invoice, invoice_id)
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Facture introuvable")
    return invoice


@router.post("/{invoice_id}/lines", response_model=schemas.InvoiceOut)
def add_invoice_line(
    invoice_id: int,
    payload: schemas.InvoiceLineCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    invoice = db.get(models.Invoice, invoice_id)
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Facture introuvable")
    if invoice.status == models.InvoiceStatus.CANCELLED:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Facture annulée : modification impossible")

    line = models.InvoiceLine(
        invoice_id=invoice.id,
        category=payload.category,
        description=payload.description,
        unit_price=payload.unit_price,
        quantity=payload.quantity,
        source_reference=payload.source_reference,
    )
    db.add(line)
    db.flush()
    crud.log_action(
        db,
        entity_type="Invoice",
        entity_id=invoice.invoice_number,
        action="ADD_LINE",
        performed_by_id=current_user.id,
        details={"description": line.description, "amount": line.line_total},
    )
    db.commit()
    db.refresh(invoice)
    return invoice


@router.post("/{invoice_id}/cancel", response_model=schemas.InvoiceOut)
def cancel_invoice(
    invoice_id: int,
    payload: schemas.InvoiceCancelRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_roles(models.Role.DAF, models.Role.PROMOTRICE)),
):
    """Annulation d'une facture — réservé DAF/Promotrice, avec motif obligatoire.

    La facture n'est jamais supprimée (traçabilité §29) : elle passe au statut
    CANCELLED et reste consultable.
    """
    invoice = db.get(models.Invoice, invoice_id)
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Facture introuvable")
    if invoice.amount_paid > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Facture déjà partiellement ou totalement payée : annulation impossible",
        )

    invoice.status = models.InvoiceStatus.CANCELLED
    invoice.cancelled_reason = payload.reason
    crud.log_action(
        db,
        entity_type="Invoice",
        entity_id=invoice.invoice_number,
        action="CANCEL",
        performed_by_id=current_user.id,
        details={"reason": payload.reason},
    )
    db.commit()
    db.refresh(invoice)
    return invoice
