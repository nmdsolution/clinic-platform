import secrets

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from .. import crud, models, openmrs_client, schemas
from ..database import get_db
from ..security import (
    create_access_token,
    get_current_user,
    hash_password,
    require_roles,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["Authentification"])


def _find_or_provision_user(db: Session, openmrs_session: dict, provision_action: str) -> models.User:
    """Retrouve le profil Caisse lié à ce compte OpenMRS, ou le provisionne
    automatiquement (rôle CAISSIER par défaut, ajustable ensuite par un
    administrateur) au premier succès pour un compte OpenMRS encore inconnu
    de la Caisse."""
    username = openmrs_session.get("username")
    if not username:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="OpenMRS n'a renvoyé aucun identifiant exploitable pour ce compte",
        )
    user = db.execute(select(models.User).where(models.User.username == username)).scalars().first()

    if user is None:
        user = models.User(
            username=username,
            full_name=openmrs_session.get("display") or username,
            # Mot de passe local jamais utilisable : ce compte s'authentifie
            # toujours via OpenMRS à partir de maintenant.
            hashed_password=hash_password(secrets.token_urlsafe(32)),
            role=models.Role.CAISSIER,
        )
        db.add(user)
        db.flush()
        crud.log_action(
            db,
            entity_type="User",
            entity_id=str(user.id),
            action=provision_action,
            performed_by_id=None,
            details={"username": user.username, "openmrs_uuid": openmrs_session.get("uuid")},
        )
        db.commit()
        db.refresh(user)
    elif not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Compte désactivé")

    return user


def _token_response(user: models.User, openmrs_session: dict) -> schemas.TokenResponse:
    token = create_access_token(user)
    return schemas.TokenResponse(
        access_token=token,
        role=user.role,
        full_name=user.full_name,
        openmrs_roles=openmrs_session.get("roles", []),
        openmrs_privileges=openmrs_session.get("privileges", []),
        openmrs_session_location=openmrs_session.get("session_location"),
    )


@router.post("/login", response_model=schemas.TokenResponse)
async def login(payload: schemas.LoginRequest, db: Session = Depends(get_db)):
    """Connexion au module Caisse.

    Deux chemins possibles, dans cet ordre :
      1. Compte local Caisse déjà connu avec ce mot de passe local (garde
         un accès de secours, par ex. le compte admin initial).
      2. Sinon, vérification directe auprès d'OpenMRS lui-même (mêmes
         comptes que pour l'interface clinique) via
         `GET /openmrs/ws/rest/v1/session`. Au premier succès pour un
         compte OpenMRS inconnu de la Caisse, un profil local est
         provisionné automatiquement.
    """
    user = db.execute(
        select(models.User).where(models.User.username == payload.username)
    ).scalars().first()

    if user is not None and user.is_active and verify_password(payload.password, user.hashed_password):
        token = create_access_token(user)
        return schemas.TokenResponse(access_token=token, role=user.role, full_name=user.full_name)

    try:
        openmrs_session = await openmrs_client.authenticate(payload.username, payload.password)
    except openmrs_client.OpenMRSError:
        openmrs_session = None

    if openmrs_session is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Identifiant ou mot de passe incorrect")

    user = _find_or_provision_user(db, openmrs_session, "AUTO_PROVISION_FROM_OPENMRS")
    return _token_response(user, openmrs_session)


@router.post("/sso", response_model=schemas.TokenResponse)
async def sso_login(request: Request, db: Session = Depends(get_db)):
    """Connexion automatique au module Caisse à partir de la session OpenMRS
    déjà ouverte dans le navigateur (cookie JSESSIONID transmis par le
    gateway), sans ressaisir d'identifiants. Répond 401 si aucune session
    OpenMRS active n'est trouvée ; le frontend retombe alors sur le
    formulaire de connexion classique (`/auth/login`)."""
    session_cookie = request.cookies.get("JSESSIONID")
    if session_cookie is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Aucune session OpenMRS active")

    try:
        openmrs_session = await openmrs_client.authenticate_with_cookie(session_cookie)
    except openmrs_client.OpenMRSError:
        openmrs_session = None

    if openmrs_session is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Session OpenMRS invalide ou expirée")

    user = _find_or_provision_user(db, openmrs_session, "AUTO_PROVISION_FROM_OPENMRS_SSO")
    return _token_response(user, openmrs_session)


@router.get("/me", response_model=schemas.UserOut)
def me(current_user: models.User = Depends(get_current_user)):
    return current_user


@router.post("/users", response_model=schemas.UserOut, status_code=status.HTTP_201_CREATED)
def create_user(
    payload: schemas.UserCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_roles(models.Role.ADMIN, models.Role.PROMOTRICE)),
):
    """Création de compte personnel — réservé à l'administrateur / la promotrice."""
    existing = db.execute(
        select(models.User).where(models.User.username == payload.username)
    ).scalars().first()
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Cet identifiant existe déjà")

    user = models.User(
        username=payload.username,
        full_name=payload.full_name,
        hashed_password=hash_password(payload.password),
        role=payload.role,
    )
    db.add(user)
    db.flush()
    crud.log_action(
        db,
        entity_type="User",
        entity_id=str(user.id),
        action="CREATE",
        performed_by_id=current_user.id,
        details={"username": user.username, "role": user.role.value},
    )
    db.commit()
    db.refresh(user)
    return user


@router.get("/users", response_model=list[schemas.UserOut])
def list_users(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_roles(models.Role.ADMIN, models.Role.PROMOTRICE, models.Role.DAF)),
):
    return db.execute(select(models.User)).scalars().all()


@router.patch("/users/{user_id}/role", response_model=schemas.UserOut)
def update_user_role(
    user_id: int,
    payload: schemas.UserRoleUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(require_roles(models.Role.ADMIN, models.Role.PROMOTRICE)),
):
    """Ajuste le rôle d'un compte - utile notamment pour les comptes
    auto-provisionnés depuis OpenMRS (créés avec le rôle CAISSIER par
    défaut au premier login)."""
    user = db.get(models.User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Utilisateur introuvable")

    previous_role = user.role
    user.role = payload.role
    crud.log_action(
        db,
        entity_type="User",
        entity_id=str(user.id),
        action="UPDATE_ROLE",
        performed_by_id=current_user.id,
        details={"from": previous_role.value, "to": payload.role.value},
    )
    db.commit()
    db.refresh(user)
    return user
