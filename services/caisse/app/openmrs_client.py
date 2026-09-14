"""Client HTTP minimal vers l'API REST d'OpenMRS.

Objectif : ne jamais dupliquer le dossier patient. Le module Caisse se
contente d'aller chercher (uuid, nom affiché) dans OpenMRS, qui reste la
seule source de vérité pour l'identité et le dossier médical du patient.
"""
from datetime import datetime, timezone

import httpx

from .config import get_settings

settings = get_settings()


class OpenMRSError(RuntimeError):
    pass


def _openmrs_client() -> httpx.AsyncClient:
    return httpx.AsyncClient(auth=(settings.openmrs_username, settings.openmrs_password), timeout=10.0)


async def search_patients(query: str, limit: int = 15) -> list[dict]:
    """Recherche des patients par nom ou numéro de dossier dans OpenMRS."""
    url = f"{settings.openmrs_base_url}/ws/rest/v1/patient"
    params = {"q": query, "v": "default", "limit": str(limit)}

    async with httpx.AsyncClient(
        auth=(settings.openmrs_username, settings.openmrs_password), timeout=10.0
    ) as client:
        try:
            response = await client.get(url, params=params)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Recherche patient OpenMRS impossible : {exc}") from exc

    data = response.json()
    results = []
    for entry in data.get("results", []):
        display = entry.get("person", {}).get("display") or entry.get("display")
        results.append({"uuid": entry.get("uuid"), "display": display})
    return results


def _parse_session(data: dict, fallback_username: str | None = None) -> dict | None:
    if not data.get("authenticated"):
        return None

    user = data.get("user") or {}
    roles = [r.get("display") or r.get("name") for r in user.get("roles", []) if r]
    privileges = [p.get("display") or p.get("name") for p in user.get("privileges", []) if p]
    provider = data.get("currentProvider") or {}
    # `user.username` est `null` dans la représentation REST par défaut de ce
    # distro : `systemId` est le véritable identifiant de connexion.
    username = user.get("username") or user.get("systemId") or fallback_username

    return {
        "uuid": user.get("uuid"),
        "username": username,
        "display": user.get("display") or username,
        "roles": [r for r in roles if r],
        "privileges": [p for p in privileges if p],
        "locale": data.get("locale"),
        "session_location": (data.get("sessionLocation") or {}).get("display"),
        "provider_display": provider.get("display"),
    }


async def authenticate(username: str, password: str) -> dict | None:
    """Vérifie des identifiants auprès d'OpenMRS via sa session PRINCIPALE,
    en représentation complète (exactement l'appel que fait l'interface
    officielle, avec tous les détails - rôles, privilèges, provider,
    localisation courante) :

        GET /openmrs/ws/rest/v1/session?v=full
        Authorization: Basic base64(username:password)

    Retourne les informations complètes de session si authentifié, sinon
    None. N'utilise jamais les identifiants techniques du module
    (CAISSE_OPENMRS_*) : ce sont ceux saisis par la personne qui se
    connecte qui sont vérifiés.
    """
    url = f"{settings.openmrs_base_url}/ws/rest/v1/session"

    async with httpx.AsyncClient(auth=(username, password), timeout=10.0) as client:
        try:
            response = await client.get(url, params={"v": "full"})
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Impossible de joindre OpenMRS pour l'authentification : {exc}") from exc

    if response.status_code == 401:
        return None
    response.raise_for_status()
    return _parse_session(response.json(), fallback_username=username)


async def authenticate_with_cookie(session_cookie: str) -> dict | None:
    """Vérifie qu'une session OpenMRS est active à partir du cookie JSESSIONID
    du navigateur, sans jamais voir de mot de passe. Utilisé pour la connexion
    automatique (SSO) du module Caisse depuis l'App Shell O3, qui tourne déjà
    dans une session OpenMRS ouverte.
    """
    url = f"{settings.openmrs_base_url}/ws/rest/v1/session"

    async with httpx.AsyncClient(cookies={"JSESSIONID": session_cookie}, timeout=10.0) as client:
        try:
            response = await client.get(url, params={"v": "full"})
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Impossible de joindre OpenMRS pour la vérification SSO : {exc}") from exc

    if response.status_code == 401:
        return None
    response.raise_for_status()
    return _parse_session(response.json())


async def get_patient(patient_uuid: str) -> dict | None:
    url = f"{settings.openmrs_base_url}/ws/rest/v1/patient/{patient_uuid}"

    async with httpx.AsyncClient(
        auth=(settings.openmrs_username, settings.openmrs_password), timeout=10.0
    ) as client:
        try:
            response = await client.get(url, params={"v": "default"})
            if response.status_code == 404:
                return None
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Lecture patient OpenMRS impossible : {exc}") from exc

    data = response.json()
    display = data.get("person", {}).get("display") or data.get("display")
    return {"uuid": data.get("uuid"), "display": display}


# ---------------------------------------------------------- Files d'attente ----

_queue_metadata_cache: dict | None = None


def _find_by_display(items: list[dict], name: str) -> str:
    for item in items:
        if item["display"].lower() == name.lower():
            return item["uuid"]
    raise OpenMRSError(f"Concept introuvable dans la configuration des files d'attente : {name}")


async def get_queue_metadata(force_refresh: bool = False) -> dict:
    """Récupère (et met en cache en mémoire) les files, statuts, priorités
    et services configurés dans OpenMRS pour le module de files d'attente,
    à partir des propriétés système `queue.*ConceptSetName` et de la
    liste des files (`/ws/rest/v1/queue`).
    """
    global _queue_metadata_cache
    if _queue_metadata_cache is not None and not force_refresh:
        return _queue_metadata_cache

    async with _openmrs_client() as client:
        try:
            settings_resp = await client.get(
                f"{settings.openmrs_base_url}/ws/rest/v1/systemsetting",
                params={"q": "queue", "v": "custom:(property,value)"},
            )
            settings_resp.raise_for_status()
            props = {s["property"]: s["value"] for s in settings_resp.json().get("results", [])}

            async def _set_members(concept_uuid: str) -> list[dict]:
                resp = await client.get(
                    f"{settings.openmrs_base_url}/ws/rest/v1/concept/{concept_uuid}",
                    params={"v": "custom:(setMembers:(uuid,display))"},
                )
                resp.raise_for_status()
                return [{"uuid": m["uuid"], "display": m["display"]} for m in resp.json().get("setMembers", [])]

            statuses = await _set_members(props["queue.statusConceptSetName"])
            priorities = await _set_members(props["queue.priorityConceptSetName"])
            services = await _set_members(props["queue.serviceConceptSetName"])

            queues_resp = await client.get(
                f"{settings.openmrs_base_url}/ws/rest/v1/queue",
                params={"v": "custom:(uuid,display,name,location:(uuid,display))"},
            )
            queues_resp.raise_for_status()
            queues = queues_resp.json().get("results", [])
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Lecture de la configuration des files d'attente impossible : {exc}") from exc
        except KeyError as exc:
            raise OpenMRSError(
                f"Propriété système manquante pour configurer les files d'attente : {exc}"
            ) from exc

    _queue_metadata_cache = {
        "statuses": statuses,
        "priorities": priorities,
        "services": services,
        "queues": queues,
    }
    return _queue_metadata_cache


async def list_queue_entries() -> list[dict]:
    """Liste toutes les entrées de file (en attente, en cours, terminées)."""
    url = f"{settings.openmrs_base_url}/ws/rest/v1/queue-entry"
    params = {
        "v": (
            "custom:(uuid,display,startedAt,endedAt,priorityComment,"
            "status:(uuid,display),priority:(uuid,display),"
            "queue:(uuid,display,location:(uuid,display)),"
            "patient:(uuid,display))"
        ),
    }
    async with _openmrs_client() as client:
        try:
            response = await client.get(url, params=params)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Liste des files d'attente impossible : {exc}") from exc
    return response.json().get("results", [])


async def create_queue_entry(*, patient_uuid: str, queue_uuid: str, priority_name: str = "Not Urgent") -> dict:
    """Inscrit un patient dans une file d'attente, au statut initial 'Waiting'."""
    metadata = await get_queue_metadata()
    status_uuid = _find_by_display(metadata["statuses"], "Waiting")
    priority_uuid = _find_by_display(metadata["priorities"], priority_name)

    payload = {
        "queue": queue_uuid,
        "patient": patient_uuid,
        "status": status_uuid,
        "priority": priority_uuid,
        "startedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000+0000"),
    }
    url = f"{settings.openmrs_base_url}/ws/rest/v1/queue-entry"

    async with _openmrs_client() as client:
        try:
            response = await client.post(url, json=payload)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Impossible d'ajouter le patient à la file d'attente : {exc}") from exc
    return response.json()


async def update_queue_entry_status(entry_uuid: str, status_name: str) -> dict:
    """Change le statut d'une entrée de file (ex: 'Waiting' -> 'In Service'
    lors de la prise en charge, ou -> 'Finished Service' à la fin)."""
    metadata = await get_queue_metadata()
    status_uuid = _find_by_display(metadata["statuses"], status_name)

    payload: dict = {"status": status_uuid}
    if status_name.lower() == "finished service":
        payload["endedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000+0000")

    url = f"{settings.openmrs_base_url}/ws/rest/v1/queue-entry/{entry_uuid}"

    async with _openmrs_client() as client:
        try:
            response = await client.post(url, json=payload)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Mise à jour du statut de la file d'attente impossible : {exc}") from exc
    return response.json()


# --------------------------------------------------------------- Rendez-vous ----

async def list_appointment_services() -> list[dict]:
    """Types de consultation disponibles (§5 du protocole : motif de
    consultation), avec leurs sous-types éventuels et leur durée."""
    url = f"{settings.openmrs_base_url}/ws/rest/v1/appointmentService/all/full"
    async with _openmrs_client() as client:
        try:
            response = await client.get(url)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Liste des types de consultation impossible : {exc}") from exc
    return response.json()


async def search_appointments(start_date: str, end_date: str) -> list[dict]:
    """Rendez-vous entre deux dates (ISO 8601, ex: 2026-09-14T00:00:00.000+0000)."""
    url = f"{settings.openmrs_base_url}/ws/rest/v1/appointments/search"
    payload = {"startDate": start_date, "endDate": end_date}
    async with _openmrs_client() as client:
        try:
            response = await client.post(url, json=payload)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Recherche des rendez-vous impossible : {exc}") from exc
    return response.json()


async def create_appointment(
    *,
    patient_uuid: str,
    service_uuid: str,
    start_datetime: str,
    end_datetime: str,
    comments: str | None = None,
) -> dict:
    """Crée un rendez-vous (§19-20 du protocole)."""
    url = f"{settings.openmrs_base_url}/ws/rest/v1/appointments"
    payload = {
        "patientUuid": patient_uuid,
        "serviceUuid": service_uuid,
        "startDateTime": start_datetime,
        "endDateTime": end_datetime,
        "appointmentKind": "Scheduled",
        "comments": comments,
    }
    async with _openmrs_client() as client:
        try:
            response = await client.post(url, json=payload)
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Création du rendez-vous impossible : {exc}") from exc
    return response.json()


async def change_appointment_status(appointment_uuid: str, to_status: str) -> dict:
    """Change le statut d'un rendez-vous : Scheduled | CheckedIn | Completed
    | Cancelled | Missed (cf. §20 : confirmé, arrivé, absent, annulé, terminé)."""
    url = f"{settings.openmrs_base_url}/ws/rest/v1/appointments/{appointment_uuid}/status-change"
    async with _openmrs_client() as client:
        try:
            response = await client.post(url, json={"toStatus": to_status})
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise OpenMRSError(f"Changement de statut du rendez-vous impossible : {exc}") from exc
    return response.json()
