from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import crud, models, schemas
from ..database import get_db
from ..security import get_current_user, require_roles

router = APIRouter(tags=["Encaissements"])


@router.post(
    "/invoices/{invoice_id}/payments",
    response_model=schemas.InvoiceOut,
    status_code=status.HTTP_201_CREATED,
)
def record_payment(
    invoice_id: int,
    payload: schemas.PaymentCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(
        require_roles(models.Role.CAISSIER, models.Role.DAF, models.Role.PROMOTRICE)
    ),
):
    invoice = db.get(models.Invoice, invoice_id)
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Facture introuvable")
    if invoice.status == models.InvoiceStatus.CANCELLED:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Facture annulée")
    if invoice.status == models.InvoiceStatus.PAID:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Facture déjà soldée")

    if payload.amount > invoice.balance_due:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                f"Montant encaissé ({payload.amount}) supérieur au solde dû "
                f"({invoice.balance_due} {invoice.currency})"
            ),
        )

    cash_session = crud.get_open_cash_session(db)
    if cash_session is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Aucune session de caisse ouverte. Ouvrez la caisse avant d'encaisser.",
        )

    # Affectation via les relations (invoice=..., cash_session=...) plutôt que
    # via les colonnes *_id brutes : SQLAlchemy tient alors immédiatement à
    # jour les collections en mémoire (invoice.payments), ce qui est
    # indispensable pour que invoice.amount_paid / balance_due reflètent ce
    # paiement sans un aller-retour supplémentaire en base.
    payment = models.Payment(
        receipt_number=crud.next_receipt_number(db),
        invoice=invoice,
        cash_session=cash_session,
        amount=payload.amount,
        method=payload.method,
        reference=payload.reference,
        received_by_id=current_user.id,
    )
    db.add(payment)
    db.flush()

    crud.refresh_invoice_status(invoice)

    crud.log_action(
        db,
        entity_type="Invoice",
        entity_id=invoice.invoice_number,
        action="PAYMENT",
        performed_by_id=current_user.id,
        details={
            "receipt_number": payment.receipt_number,
            "amount": payment.amount,
            "method": payment.method.value,
        },
    )
    db.commit()
    db.refresh(invoice)
    return invoice


@router.get("/payments/{payment_id}/receipt", response_model=schemas.ReceiptOut)
def get_receipt(
    payment_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    payment = db.get(models.Payment, payment_id)
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Reçu introuvable")
    invoice = payment.invoice
    return schemas.ReceiptOut(
        receipt_number=payment.receipt_number,
        invoice_number=invoice.invoice_number,
        patient_display=invoice.patient_display,
        amount=payment.amount,
        method=payment.method,
        currency=invoice.currency,
        received_at=payment.received_at,
        received_by=payment.received_by.full_name,
        invoice_total=invoice.total_amount,
        invoice_balance_due=invoice.balance_due,
    )
