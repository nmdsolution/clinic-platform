from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status

from .. import models, openmrs_client, schemas
from ..security import get_current_user

router = APIRouter(prefix="/appointments", tags=["Rendez-vous"])


def _openmrs_datetime(value: datetime) -> str:
    """Formate une date Python vers le format attendu par OpenMRS
    (ISO avec millisecondes et offset, ex: 2026-09-14T09:00:00.000+0000)."""
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000+0000")


def _epoch_ms_to_iso(value) -> str:
    """OpenMRS renvoie les dates de rendez-vous en millisecondes epoch."""
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    return datetime.fromtimestamp(value / 1000, tz=timezone.utc).isoformat()


def _to_service_out(raw: dict) -> schemas.AppointmentServiceOut:
    return schemas.AppointmentServiceOut(
        uuid=raw.get("uuid"),
        name=raw.get("name"),
        color=raw.get("color"),
        service_types=[
            {"uuid": st.get("uuid"), "name": st.get("name"), "duration": st.get("duration")}
            for st in (raw.get("serviceTypes") or [])
        ],
    )


def _to_appointment_out(raw: dict) -> schemas.AppointmentOut:
    patient = raw.get("patient") or {}
    service = raw.get("service") or {}
    return schemas.AppointmentOut(
        uuid=raw.get("uuid"),
        appointment_number=raw.get("appointmentNumber") or "",
        patient_uuid=patient.get("uuid"),
        patient_display=patient.get("name") or patient.get("display") or "",
        service_name=service.get("name") or "",
        service_color=service.get("color"),
        start_datetime=_epoch_ms_to_iso(raw.get("startDateTime")),
        end_datetime=_epoch_ms_to_iso(raw.get("endDateTime")),
        status=raw.get("status") or "",
        comments=raw.get("comments"),
    )


@router.get("/services", response_model=list[schemas.AppointmentServiceOut])
async def list_services(current_user: models.User = Depends(get_current_user)):
    """Motifs de consultation disponibles (§5), pour peupler le formulaire de prise de rendez-vous."""
    try:
        raw_services = await openmrs_client.list_appointment_services()
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    return [_to_service_out(s) for s in raw_services]


@router.get("", response_model=list[schemas.AppointmentOut])
async def list_appointments(
    date: str = Query(description="Date au format AAAA-MM-JJ (ex: 2026-09-14)"),
    current_user: models.User = Depends(get_current_user),
):
    """Rendez-vous d'une journée donnée (§19 : agenda par jour)."""
    start = _openmrs_datetime(datetime.fromisoformat(f"{date}T00:00:00"))
    end = _openmrs_datetime(datetime.fromisoformat(f"{date}T23:59:59"))
    try:
        raw_appointments = await openmrs_client.search_appointments(start, end)
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    return [_to_appointment_out(a) for a in raw_appointments]


@router.post("", response_model=schemas.AppointmentOut, status_code=status.HTTP_201_CREATED)
async def create_appointment(
    payload: schemas.AppointmentCreate,
    current_user: models.User = Depends(get_current_user),
):
    """Prise de rendez-vous (§19-20)."""
    try:
        raw = await openmrs_client.create_appointment(
            patient_uuid=payload.patient_uuid,
            service_uuid=payload.service_uuid,
            start_datetime=_openmrs_datetime(payload.start_datetime),
            end_datetime=_openmrs_datetime(payload.end_datetime),
            comments=payload.comments,
        )
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    return _to_appointment_out(raw)


@router.patch("/{appointment_uuid}/status", response_model=schemas.AppointmentOut)
async def update_status(
    appointment_uuid: str,
    payload: schemas.AppointmentStatusUpdate,
    current_user: models.User = Depends(get_current_user),
):
    """Confirmé / arrivé / absent / annulé / terminé (§20)."""
    try:
        raw = await openmrs_client.change_appointment_status(appointment_uuid, payload.status)
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    return _to_appointment_out(raw)
