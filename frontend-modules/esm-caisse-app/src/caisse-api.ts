/**
 * Client HTTP pour l'API du module Caisse (microservice Python séparé,
 * avec sa propre authentification JWT - indépendante de la session OpenMRS).
 */
const TOKEN_STORAGE_KEY = 'face-caisse-token';
const USER_STORAGE_KEY = 'face-caisse-user';

export interface CaisseUser {
  role: 'ADMIN' | 'PROMOTRICE' | 'DAF' | 'CAISSIER' | 'SECRETAIRE';
  full_name: string;
}

export interface PatientSearchResult {
  uuid: string;
  display: string;
}

export interface InvoiceLine {
  id?: number;
  category: string;
  description: string;
  unit_price: number;
  quantity: number;
  line_total?: number;
}

export interface Invoice {
  id: number;
  invoice_number: string;
  patient_uuid: string;
  patient_display: string;
  status: 'OPEN' | 'PARTIALLY_PAID' | 'PAID' | 'CANCELLED';
  currency: string;
  discount_amount: number;
  insurance_covered_amount: number;
  total_amount: number;
  amount_paid: number;
  balance_due: number;
  created_at: string;
  lines: InvoiceLine[];
}

export interface CashSession {
  id: number;
  status: 'OPEN' | 'CLOSED';
  opening_float: number;
  opened_at: string;
  closed_at: string | null;
  counted_cash: number | null;
  counted_mobile_money: number | null;
  counted_other: number | null;
  variance: number | null;
  expected_amount: number;
}

export interface DailySummary {
  date: string;
  invoices_count: number;
  total_billed: number;
  total_collected: number;
  unpaid_invoices_count: number;
  unpaid_amount: number;
  by_payment_method: Record<string, number>;
  by_category: Record<string, number>;
}

export function getStoredToken(): string | null {
  return sessionStorage.getItem(TOKEN_STORAGE_KEY);
}

export function getStoredUser(): CaisseUser | null {
  const raw = sessionStorage.getItem(USER_STORAGE_KEY);
  return raw ? JSON.parse(raw) : null;
}

export function clearSession(): void {
  sessionStorage.removeItem(TOKEN_STORAGE_KEY);
  sessionStorage.removeItem(USER_STORAGE_KEY);
}

export class CaisseApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}

export class CaisseApi {
  constructor(private basePath: string) {}

  async login(username: string, password: string): Promise<CaisseUser> {
    const response = await fetch(`${this.basePath}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    });
    if (!response.ok) {
      throw new CaisseApiError('Identifiant ou mot de passe incorrect', response.status);
    }
    return this.storeSession(await response.json());
  }

  /**
   * Connexion silencieuse à partir de la session OpenMRS déjà ouverte
   * (cookie transmis par le gateway) : pas de formulaire si elle réussit.
   */
  async ssoLogin(): Promise<CaisseUser> {
    const response = await fetch(`${this.basePath}/auth/sso`, {
      method: 'POST',
      credentials: 'include',
    });
    if (!response.ok) {
      throw new CaisseApiError('Session OpenMRS non valide pour la Caisse', response.status);
    }
    return this.storeSession(await response.json());
  }

  private storeSession(data: { access_token: string; role: CaisseUser['role']; full_name: string }): CaisseUser {
    sessionStorage.setItem(TOKEN_STORAGE_KEY, data.access_token);
    const user: CaisseUser = { role: data.role, full_name: data.full_name };
    sessionStorage.setItem(USER_STORAGE_KEY, JSON.stringify(user));
    return user;
  }

  logout(): void {
    clearSession();
  }

  private async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const token = getStoredToken();
    const response = await fetch(`${this.basePath}${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
      },
    });

    if (response.status === 401) {
      clearSession();
      throw new CaisseApiError("Session expirée, merci de vous reconnecter.", 401);
    }

    if (!response.ok) {
      let detail = `Erreur ${response.status}`;
      try {
        const body = await response.json();
        detail = typeof body.detail === 'string' ? body.detail : JSON.stringify(body.detail ?? body);
      } catch {
        /* réponse non-JSON, on garde le message générique */
      }
      throw new CaisseApiError(detail, response.status);
    }

    if (response.status === 204) {
      return undefined as T;
    }
    return response.json();
  }

  searchPatients(query: string): Promise<PatientSearchResult[]> {
    return this.request(`/patients/search?q=${encodeURIComponent(query)}`);
  }

  createInvoice(payload: {
    patient_uuid: string;
    patient_display: string;
    lines: InvoiceLine[];
    discount_amount?: number;
    insurance_covered_amount?: number;
  }): Promise<Invoice> {
    return this.request('/invoices', { method: 'POST', body: JSON.stringify(payload) });
  }

  listInvoices(params: { date_from?: string; date_to?: string; status?: string } = {}): Promise<Invoice[]> {
    const qs = new URLSearchParams(params as Record<string, string>).toString();
    return this.request(`/invoices${qs ? `?${qs}` : ''}`);
  }

  getInvoice(id: number): Promise<Invoice> {
    return this.request(`/invoices/${id}`);
  }

  recordPayment(invoiceId: number, payload: { amount: number; method: string; reference?: string }): Promise<Invoice> {
    return this.request(`/invoices/${invoiceId}/payments`, { method: 'POST', body: JSON.stringify(payload) });
  }

  getCurrentCashSession(): Promise<CashSession | null> {
    return this.request('/cash-sessions/current');
  }

  openCashSession(openingFloat: number): Promise<CashSession> {
    return this.request('/cash-sessions/open', {
      method: 'POST',
      body: JSON.stringify({ opening_float: openingFloat }),
    });
  }

  closeCashSession(
    sessionId: number,
    payload: { counted_cash: number; counted_mobile_money: number; counted_other: number; notes?: string },
  ): Promise<CashSession> {
    return this.request(`/cash-sessions/${sessionId}/close`, { method: 'POST', body: JSON.stringify(payload) });
  }

  getDailySummary(day?: string): Promise<DailySummary> {
    return this.request(`/reports/daily-summary${day ? `?day=${day}` : ''}`);
  }
}
