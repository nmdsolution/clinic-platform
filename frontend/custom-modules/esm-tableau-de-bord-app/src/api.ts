import { useCallback, useEffect, useState } from 'react';
import { openmrsFetch } from '@openmrs/esm-framework';

/** UUID des datasets créés par grille/tableau_de_bord_datasets.sql */
export const DATASETS = {
  patients: '0f7a0000-c1c0-4000-8000-00000000b001',
  consultationsParJour: '0f7a0000-c1c0-4000-8000-00000000b002',
  consultationsDetail: '0f7a0000-c1c0-4000-8000-00000000b003',
  recettesParJour: '0f7a0000-c1c0-4000-8000-00000000b004',
  facturesDetail: '0f7a0000-c1c0-4000-8000-00000000b005',
  stock: '0f7a0000-c1c0-4000-8000-00000000b006',
  magasins: '0f7a0000-c1c0-4000-8000-00000000b007',
  indicateurs: '0f7a0000-c1c0-4000-8000-00000000b008',
  medicaments: '0f7a0000-c1c0-4000-8000-00000000b009',
  tarifs: '0f7a0000-c1c0-4000-8000-00000000b010',
  impayes: '0f7a0000-c1c0-4000-8000-00000000b011',
  ventesParActe: '0f7a0000-c1c0-4000-8000-00000000b012',
  formes: '0f7a0000-c1c0-4000-8000-00000000b013',
  ficheInfo: '0f7a0000-c1c0-4000-8000-00000000b014',
  ficheStock: '0f7a0000-c1c0-4000-8000-00000000b015',
  ficheHistorique: '0f7a0000-c1c0-4000-8000-00000000b016',
};

export type Row = Record<string, string | number | null>;

interface DataSetResponse {
  rows?: Array<Row>;
}

/** Évalue un dataset SQL côté serveur ; les paramètres deviennent ?startDate=...&endDate=... */
export async function fetchDataSet(uuid: string, params: Record<string, string> = {}): Promise<Array<Row>> {
  const query = new URLSearchParams(params).toString();
  const response = await openmrsFetch<DataSetResponse>(`/ws/rest/v1/reportingrest/dataSet/${uuid}?${query}`);
  return response.data?.rows ?? [];
}

export function useDataSet(uuid: string, params?: Record<string, string>) {
  const key = JSON.stringify(params ?? {});
  const [rows, setRows] = useState<Array<Row>>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [reloadKey, setReloadKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    fetchDataSet(uuid, JSON.parse(key))
      .then((data) => !cancelled && setRows(data))
      .catch((err) => !cancelled && setError(errorMessage(err)))
      .finally(() => !cancelled && setLoading(false));
    return () => {
      cancelled = true;
    };
  }, [uuid, key, reloadKey]);

  const reload = useCallback(() => setReloadKey((k) => k + 1), []);
  return { rows, loading, error, reload };
}

/** Envoie un objet JSON à l'API REST et renvoie la réponse (POST) */
export async function postRest<T = { uuid: string }>(path: string, body: unknown): Promise<T> {
  const response = await openmrsFetch<T>(`/ws/rest/v1/${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return response.data;
}

export async function getRest<T>(path: string): Promise<T> {
  const response = await openmrsFetch<T>(`/ws/rest/v1/${path}`);
  return response.data;
}

export function errorMessage(err: unknown): string {
  // openmrsFetch rejette avec { response, responseBody } quand le serveur répond en erreur
  const e = err as { response?: { status?: number }; responseBody?: { error?: { message?: string } } };
  if (e?.response?.status === 401 || e?.response?.status === 403) {
    return "Votre compte n'a pas le droit de consulter ces données (privilège « Run Reports » requis).";
  }
  return e?.responseBody?.error?.message ?? 'Chargement impossible. Réessayez dans un instant.';
}

/** Date locale au format AAAA-MM-JJ (sans décalage de fuseau) */
export function isoDay(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

export function num(value: string | number | null | undefined): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : 0;
}

const fcfa = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 });
export function formatFcfa(value: string | number | null | undefined): string {
  return `${fcfa.format(num(value))} FCFA`;
}

export function formatDay(iso: string | number | null | undefined): string {
  if (!iso) return '';
  const [y, m, d] = String(iso).slice(0, 10).split('-');
  return d && m && y ? `${d}/${m}/${y}` : String(iso);
}

export function text(value: string | number | null | undefined): string {
  return value === null || value === undefined ? '' : String(value);
}
