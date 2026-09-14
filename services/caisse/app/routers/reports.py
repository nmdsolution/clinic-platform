from collections import defaultdict
from datetime import date, datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import models, schemas
from ..database import get_db
from ..security import get_current_user, require_roles

router = APIRouter(prefix="/reports", tags=["Statistiques & tableau de bord"])


@router.get("/daily-summary", response_model=schemas.DailySummary)
def daily_summary(
    db: Session = Depends(get_db),
    day: date = Query(default_factory=date.today),
    current_user: models.User = Depends(
        require_roles(models.Role.DAF, models.Role.PROMOTRICE, models.Role.CAISSIER)
    ),
):
    day_start = datetime.combine(day, datetime.min.time())
    day_end = datetime.combine(day, datetime.max.time())

    invoices = db.execute(
        select(models.Invoice).where(
            models.Invoice.created_at >= day_start,
            models.Invoice.created_at <= day_end,
            models.Invoice.status != models.InvoiceStatus.CANCELLED,
        )
    ).scalars().all()

    payments = db.execute(
        select(models.Payment).where(
            models.Payment.received_at >= day_start,
            models.Payment.received_at <= day_end,
        )
    ).scalars().all()

    total_billed = sum(inv.total_amount for inv in invoices)
    total_collected = sum(p.amount for p in payments)
    unpaid = [inv for inv in invoices if inv.balance_due > 0]

    by_method: dict[str, int] = defaultdict(int)
    for p in payments:
        by_method[p.method.value] += p.amount

    by_category: dict[str, int] = defaultdict(int)
    for inv in invoices:
        for line in inv.lines:
            by_category[line.category.value] += line.line_total

    return schemas.DailySummary(
        date=day.isoformat(),
        invoices_count=len(invoices),
        total_billed=total_billed,
        total_collected=total_collected,
        unpaid_invoices_count=len(unpaid),
        unpaid_amount=sum(inv.balance_due for inv in unpaid),
        by_payment_method=dict(by_method),
        by_category=dict(by_category),
    )
