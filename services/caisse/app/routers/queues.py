from fastapi import APIRouter, Depends, HTTPException, status

from .. import models, openmrs_client, schemas
from ..security import get_current_user

router = APIRouter(prefix="/queues", tags=["Files d'attente"])


def _to_queue_entry_out(raw: dict) -> schemas.QueueEntryOut:
    patient = raw.get("patient") or {}
    queue = raw.get("queue") or {}
    status_ = raw.get("status") or {}
    priority = raw.get("priority") or {}
    return schemas.QueueEntryOut(
        uuid=raw.get("uuid"),
        patient_uuid=patient.get("uuid"),
        patient_display=patient.get("display"),
        queue_display=queue.get("display"),
        status=status_.get("display"),
        priority=priority.get("display"),
        started_at=raw.get("startedAt"),
        ended_at=raw.get("endedAt"),
    )


@router.get("/metadata", response_model=schemas.QueueMetadata)
async def get_metadata(current_user: models.User = Depends(get_current_user)):
    """Files, statuts et priorités configurés côté OpenMRS - à utiliser
    pour peupler les listes déroulantes du formulaire d'accueil."""
    try:
        return await openmrs_client.get_queue_metadata()
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc


@router.get("/entries", response_model=list[schemas.QueueEntryOut])
async def list_entries(current_user: models.User = Depends(get_current_user)):
    """Toutes les entrées de file (statut EN ATTENTE, EN CONSULTATION ou TERMINÉ)."""
    try:
        raw_entries = await openmrs_client.list_queue_entries()
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    return [_to_queue_entry_out(e) for e in raw_entries]


@router.post("/entries", response_model=schemas.QueueEntryOut, status_code=status.HTTP_201_CREATED)
async def add_entry(
    payload: schemas.QueueEntryCreate,
    current_user: models.User = Depends(get_current_user),
):
    """Inscrit un patient dans la salle d'attente (module Accueil, §4-6)."""
    try:
        raw = await openmrs_client.create_queue_entry(
            patient_uuid=payload.patient_uuid,
            queue_uuid=payload.queue_uuid,
            priority_name=payload.priority,
        )
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    return _to_queue_entry_out(raw)


@router.patch("/entries/{entry_uuid}/status", response_model=schemas.QueueEntryOut)
async def change_status(
    entry_uuid: str,
    payload: schemas.QueueEntryStatusUpdate,
    current_user: models.User = Depends(get_current_user),
):
    """Change le statut d'une entrée : « Prendre en charge » (-> In Service)
    ou « Terminé » (-> Finished Service), cf. §6 du protocole."""
    try:
        raw = await openmrs_client.update_queue_entry_status(entry_uuid, payload.status)
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=str(exc)) from exc
    return _to_queue_entry_out(raw)
