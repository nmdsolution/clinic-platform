from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .. import crud, models, schemas
from ..database import get_db, now_utc
from ..security import get_current_user, require_roles

router = APIRouter(prefix="/cash-sessions", tags=["Caisse"])


@router.post("/open", response_model=schemas.CashSessionOut, status_code=status.HTTP_201_CREATED)
def open_cash_session(
    payload: schemas.CashSessionOpenRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(
        require_roles(models.Role.CAISSIER, models.Role.DAF, models.Role.PROMOTRICE)
    ),
):
    if crud.get_open_cash_session(db) is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Une session de caisse est déjà ouverte. Fermez-la avant d'en ouvrir une nouvelle.",
        )

    session_ = models.CashSession(opened_by_id=current_user.id, opening_float=payload.opening_float)
    db.add(session_)
    db.flush()
    crud.log_action(
        db,
        entity_type="CashSession",
        entity_id=str(session_.id),
        action="OPEN",
        performed_by_id=current_user.id,
        details={"opening_float": payload.opening_float},
    )
    db.commit()
    db.refresh(session_)
    return session_


@router.get("/current", response_model=schemas.CashSessionOut | None)
def get_current_session(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    return crud.get_open_cash_session(db)


@router.post("/{session_id}/close", response_model=schemas.CashSessionOut)
def close_cash_session(
    session_id: int,
    payload: schemas.CashSessionCloseRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(
        require_roles(models.Role.CAISSIER, models.Role.DAF, models.Role.PROMOTRICE)
    ),
):
    session_ = db.get(models.CashSession, session_id)
    if session_ is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session de caisse introuvable")
    if session_.status == models.CashSessionStatus.CLOSED:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Session déjà fermée")

    session_.counted_cash = payload.counted_cash
    session_.counted_mobile_money = payload.counted_mobile_money
    session_.counted_other = payload.counted_other
    session_.notes = payload.notes
    session_.closed_by_id = current_user.id
    session_.closed_at = now_utc()
    session_.variance = payload.counted_cash - session_.expected_amount
    session_.status = models.CashSessionStatus.CLOSED

    crud.log_action(
        db,
        entity_type="CashSession",
        entity_id=str(session_.id),
        action="CLOSE",
        performed_by_id=current_user.id,
        details={
            "expected_amount": session_.expected_amount,
            "counted_cash": payload.counted_cash,
            "variance": session_.variance,
        },
    )
    db.commit()
    db.refresh(session_)
    return session_


@router.get("/{session_id}", response_model=schemas.CashSessionOut)
def get_cash_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user),
):
    session_ = db.get(models.CashSession, session_id)
    if session_ is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session de caisse introuvable")
    return session_
