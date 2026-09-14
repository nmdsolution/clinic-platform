"""Schémas Pydantic (requêtes / réponses de l'API)."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from .models import CashSessionStatus, InvoiceStatus, LineCategory, PaymentMethod, Role

# ---------------------------------------------------------------- Auth ----

class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: Role
    full_name: str
    # Détails de la session OpenMRS principale (v=full), présents
    # uniquement quand la connexion est passée par OpenMRS.
    openmrs_roles: list[str] = Field(default_factory=list)
    openmrs_privileges: list[str] = Field(default_factory=list)
    openmrs_session_location: str | None = None


class UserCreate(BaseModel):
    username: str
    full_name: str
    password: str = Field(min_length=6)
    role: Role = Role.CAISSIER


class UserRoleUpdate(BaseModel):
    role: Role


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    full_name: str
    role: Role
    is_active: bool


# ----------------------------------------------------------- Patients ----

class PatientSearchResult(BaseModel):
    uuid: str
    display: str


# ------------------------------------------------------ Files d'attente ----

class QueueMetadata(BaseModel):
    statuses: list[dict[str, str]]
    priorities: list[dict[str, str]]
    services: list[dict[str, str]]
    queues: list[dict]


class QueueEntryCreate(BaseModel):
    patient_uuid: str
    queue_uuid: str
    priority: str = "Not Urgent"


class QueueEntryStatusUpdate(BaseModel):
    status: str = Field(description="Waiting | In Service | Finished Service")


class QueueEntryOut(BaseModel):
    uuid: str
    patient_uuid: str
    patient_display: str
    queue_display: str
    status: str
    priority: str
    started_at: str
    ended_at: str | None = None


# ----------------------------------------------------------- Rendez-vous ----

class AppointmentServiceOut(BaseModel):
    uuid: str
    name: str
    color: str | None = None
    service_types: list[dict[str, str | int]] = Field(default_factory=list)


class AppointmentCreate(BaseModel):
    patient_uuid: str
    service_uuid: str
    start_datetime: datetime
    end_datetime: datetime
    comments: str | None = None


class AppointmentStatusUpdate(BaseModel):
    status: str = Field(description="Scheduled | CheckedIn | Completed | Cancelled | Missed")


class AppointmentOut(BaseModel):
    uuid: str
    appointment_number: str
    patient_uuid: str
    patient_display: str
    service_name: str
    service_color: str | None = None
    start_datetime: str
    end_datetime: str
    status: str
    comments: str | None = None


# ------------------------------------------------------------ Invoice ----

class InvoiceLineCreate(BaseModel):
    category: LineCategory
    description: str
    unit_price: int = Field(ge=0)
    quantity: int = Field(default=1, ge=1)
    source_reference: str | None = None


class InvoiceLineOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category: LineCategory
    description: str
    unit_price: int
    quantity: int
    line_total: int
    source_reference: str | None = None
    created_at: datetime


class InvoiceCreate(BaseModel):
    patient_uuid: str
    patient_display: str
    lines: list[InvoiceLineCreate] = Field(default_factory=list)
    discount_amount: int = Field(default=0, ge=0)
    insurance_covered_amount: int = Field(default=0, ge=0)


class InvoiceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    invoice_number: str
    patient_uuid: str
    patient_display: str
    status: InvoiceStatus
    currency: str
    discount_amount: int
    insurance_covered_amount: int
    total_amount: int
    amount_paid: int
    balance_due: int
    created_at: datetime
    updated_at: datetime
    lines: list[InvoiceLineOut] = Field(default_factory=list)


class InvoiceCancelRequest(BaseModel):
    reason: str = Field(min_length=3)


# ------------------------------------------------------------ Payment ----

class PaymentCreate(BaseModel):
    amount: int = Field(gt=0)
    method: PaymentMethod
    reference: str | None = None


class PaymentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    receipt_number: str
    invoice_id: int
    amount: int
    method: PaymentMethod
    reference: str | None = None
    received_at: datetime
    received_by_id: int


class ReceiptOut(BaseModel):
    receipt_number: str
    invoice_number: str
    patient_display: str
    amount: int
    method: PaymentMethod
    currency: str
    received_at: datetime
    received_by: str
    invoice_total: int
    invoice_balance_due: int


# -------------------------------------------------------- Cash session ----

class CashSessionOpenRequest(BaseModel):
    opening_float: int = Field(default=0, ge=0)


class CashSessionCloseRequest(BaseModel):
    counted_cash: int = Field(ge=0)
    counted_mobile_money: int = Field(default=0, ge=0)
    counted_other: int = Field(default=0, ge=0)
    notes: str | None = None


class CashSessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    status: CashSessionStatus
    opened_by_id: int
    opened_at: datetime
    opening_float: int
    closed_by_id: int | None = None
    closed_at: datetime | None = None
    counted_cash: int | None = None
    counted_mobile_money: int | None = None
    counted_other: int | None = None
    variance: int | None = None
    notes: str | None = None
    expected_amount: int


# ----------------------------------------------------------- Reporting ----

class DailySummary(BaseModel):
    date: str
    invoices_count: int
    total_billed: int
    total_collected: int
    unpaid_invoices_count: int
    unpaid_amount: int
    by_payment_method: dict[str, int]
    by_category: dict[str, int]
