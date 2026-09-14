from fastapi import APIRouter, Depends, HTTPException, Query, status

from .. import models, openmrs_client, schemas
from ..security import get_current_user

router = APIRouter(prefix="/patients", tags=["Patients (via OpenMRS)"])


@router.get("/search", response_model=list[schemas.PatientSearchResult])
async def search_patients(
    q: str = Query(min_length=2, description="Nom ou numéro de dossier du patient"),
    current_user: models.User = Depends(get_current_user),
):
    try:
        results = await openmrs_client.search_patients(q)
    except openmrs_client.OpenMRSError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Impossible de joindre le dossier patient (OpenMRS) : {exc}",
        ) from exc
    return results
