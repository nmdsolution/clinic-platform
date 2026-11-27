import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, InlineNotification, Search, Tag } from '@carbon/react';
import { errorMessage, formatFcfa, getRest, postRest, text, type Row } from '../api';
import DataTable, { type Column } from '../data-table.component';
import { openPatientChart } from '../patients/patients-tab.component';
import styles from '../root.scss';

interface Reponse {
  results?: Array<Row>;
  peutDeroger?: boolean;
}

/** Message d'erreur du serveur (module HGest) ou message générique */
function messageServeur(err: unknown): string {
  const e = err as { response?: { status?: number }; responseBody?: { error?: { message?: string } } };
  if (e?.response?.status === 401 || e?.response?.status === 403) {
    return e?.responseBody?.error?.message ?? "Votre compte n'a pas le droit d'accorder une dérogation.";
  }
  return errorMessage(err);
}

/**
 * Point 6 : la pharmacie ne peut pas délivrer et le labo ne peut pas prélever un acte non payé.
 * Cet onglet liste ce qui est bloqué dans les visites ouvertes et permet, avec le droit
 * « HGest: Deroger au paiement », d'accorder une dérogation motivée (qui, quand, pourquoi sont conservés).
 */
const DerogationsTab: React.FC = () => {
  const { t } = useTranslation();
  const [bloques, setBloques] = useState<Array<Row>>([]);
  const [accordees, setAccordees] = useState<Array<Row>>([]);
  const [peutDeroger, setPeutDeroger] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [erreurAction, setErreurAction] = useState<string | null>(null);
  const [enCours, setEnCours] = useState<string | null>(null);
  const [query, setQuery] = useState('');

  const charger = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [b, d] = await Promise.all([
        getRest<Reponse>('hgest/paiement/bloques'),
        getRest<Reponse>('hgest/derogation?jours=30'),
      ]);
      setBloques(b?.results ?? []);
      setAccordees(d?.results ?? []);
      setPeutDeroger(Boolean(d?.peutDeroger));
    } catch (err) {
      setError(messageServeur(err));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    charger();
  }, [charger]);

  const filtrer = useCallback(
    (rows: Array<Row>) => {
      const q = query.toLowerCase().trim();
      return q
        ? rows.filter((r) => [r.patient, r.dossier, r.acte, r.facture, r.motif].map(text).join(' ').toLowerCase().includes(q))
        : rows;
    },
    [query],
  );
  const bloquesFiltres = useMemo(() => filtrer(bloques), [bloques, filtrer]);
  const accordeesFiltrees = useMemo(() => filtrer(accordees), [accordees, filtrer]);

  const deroger = async (row: Row) => {
    const motif = window.prompt(
      t('motifDerogation', 'Dérogation pour « {{acte}} » ({{montant}}) – {{patient}}.\nMotif (obligatoire) :', {
        acte: text(row.acte),
        montant: formatFcfa(row.montant),
        patient: text(row.patient),
      }),
    );
    if (motif === null) return;
    setEnCours(text(row.commande));
    setErreurAction(null);
    try {
      await postRest('hgest/derogation', { commande: text(row.commande), motif });
      await charger();
    } catch (err) {
      setErreurAction(messageServeur(err));
    } finally {
      setEnCours(null);
    }
  };

  const colonnesBloques: Array<Column> = [
    { key: 'debut_visite', header: t('visite', 'Visite') },
    { key: 'type', header: t('type', 'Type'), render: (r) => <Tag type={r.type === 'Examen' ? 'blue' : 'purple'}>{text(r.type)}</Tag> },
    { key: 'acte', header: t('acte', 'Acte') },
    { key: 'dossier', header: t('dossier', 'N° dossier') },
    { key: 'patient', header: t('patient', 'Patient') },
    { key: 'facture', header: t('facture', 'Facture') },
    { key: 'montant', header: t('montant', 'Montant'), numeric: true, render: (r) => formatFcfa(r.montant) },
    {
      key: 'action',
      header: '',
      render: (r) =>
        peutDeroger ? (
          <Button
            kind="ghost"
            size="sm"
            disabled={enCours === text(r.commande)}
            onClick={(e: React.MouseEvent) => {
              e.stopPropagation();
              deroger(r);
            }}>
            {enCours === text(r.commande) ? t('enregistrement', 'Enregistrement…') : t('accorderDerogation', 'Accorder une dérogation')}
          </Button>
        ) : null,
    },
  ];

  const colonnesAccordees: Array<Column> = [
    { key: 'date', header: t('date', 'Date') },
    { key: 'accordee_par', header: t('accordeePar', 'Accordée par') },
    { key: 'motif', header: t('motif', 'Motif') },
    { key: 'acte', header: t('acte', 'Acte') },
    { key: 'dossier', header: t('dossier', 'N° dossier') },
    { key: 'patient', header: t('patient', 'Patient') },
    { key: 'montant', header: t('montant', 'Montant'), numeric: true, render: (r) => formatFcfa(r.montant) },
    {
      key: 'statut_facture',
      header: t('reglement', 'Règlement'),
      render: (r) => (r.statut_facture === 'PAID' ? <Tag type="green">{t('payee', 'Payée')}</Tag> : <Tag type="magenta">{t('nonPayee', 'Non payée')}</Tag>),
    },
  ];

  return (
    <>
      <div className={styles.totals}>
        <div>
          <span className={styles.totalLabel}>{t('actesBloques', 'Actes bloqués (non payés)')}</span>
          <span className={styles.totalValue}>{loading ? '…' : bloquesFiltres.length}</span>
        </div>
        <div>
          <span className={styles.totalLabel}>{t('derogations30j', 'Dérogations sur 30 jours')}</span>
          <span className={styles.totalValue}>{loading ? '…' : accordeesFiltrees.length}</span>
        </div>
      </div>
      <p>
        {t(
          'aideDerogations',
          'La pharmacie ne peut pas délivrer et le laboratoire ne peut pas prélever un acte non payé. Les hospitalisations et les visites « non-paiement » ne sont pas concernées. En cas d’urgence, une personne habilitée accorde une dérogation motivée : elle reste enregistrée avec son auteur et sa date.',
        )}
      </p>
      {!loading && !peutDeroger && (
        <InlineNotification
          kind="info"
          lowContrast
          hideCloseButton
          title={t('pasDeDroitDerogation', 'Votre compte ne peut pas accorder de dérogation.')}
          subtitle={t('demanderResponsable', 'Demandez à un responsable habilité.')}
        />
      )}
      {erreurAction && (
        <InlineNotification
          kind="error"
          lowContrast
          title={t('derogationImpossible', 'Dérogation impossible')}
          subtitle={erreurAction}
          onClose={() => setErreurAction(null)}
        />
      )}
      <div className={styles.toolbar}>
        <Search
          size="lg"
          labelText={t('rechercher', 'Rechercher')}
          placeholder={t('rechercherDerogation', 'Rechercher par patient, n° de dossier, acte, facture ou motif')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>
      <h4>{t('actesBloquesTitre', 'Actes bloqués dans les visites ouvertes')}</h4>
      <DataTable
        columns={colonnesBloques}
        rows={bloquesFiltres}
        loading={loading}
        error={error}
        emptyText={t('aucunActeBloque', 'Aucun acte bloqué : tout ce qui est prescrit dans les visites ouvertes est payé.')}
        onRowClick={openPatientChart}
      />
      <h4>{t('derogationsAccordees', 'Dérogations accordées (30 derniers jours)')}</h4>
      <DataTable
        columns={colonnesAccordees}
        rows={accordeesFiltrees}
        loading={loading}
        error={error}
        emptyText={t('aucuneDerogation', 'Aucune dérogation sur la période.')}
        onRowClick={openPatientChart}
      />
    </>
  );
};

export default DerogationsTab;
