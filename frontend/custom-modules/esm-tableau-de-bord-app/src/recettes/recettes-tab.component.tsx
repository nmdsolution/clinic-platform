import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { InlineLoading, InlineNotification, Tag } from '@carbon/react';
import { DATASETS, formatDay, formatFcfa, isoDay, num, useDataSet, type Row } from '../api';
import MonthCalendar, { monthRange } from '../calendar/month-calendar.component';
import DataTable, { type Column } from '../data-table.component';
import { openPatientChart } from '../patients/patients-tab.component';
import styles from '../root.scss';

const STATUTS: Record<string, { label: string; type: 'green' | 'red' | 'gray' | 'purple' }> = {
  PAID: { label: 'Payée', type: 'green' },
  PENDING: { label: 'En attente', type: 'red' },
  POSTED: { label: 'Validée', type: 'gray' },
  REFUND_REQUESTED: { label: 'Remboursement demandé', type: 'purple' },
};

const fcfaCourt = new Intl.NumberFormat('fr-FR', { notation: 'compact', maximumFractionDigits: 1 });

/** Recettes par jour : facturé (factures créées) et encaissé (paiements reçus), zéro compris */
const RecettesTab: React.FC = () => {
  const { t } = useTranslation();
  const [month, setMonth] = useState(() => new Date(new Date().getFullYear(), new Date().getMonth(), 1));
  const [day, setDay] = useState(() => isoDay(new Date()));

  const range = useMemo(() => monthRange(month), [month]);
  const parJour = useDataSet(DATASETS.recettesParJour, range);
  const detail = useDataSet(DATASETS.facturesDetail, { startDate: day, endDate: day });
  const ventes = useDataSet(DATASETS.ventesParActe, range);

  const byDay = useMemo(() => new Map<string, Row>(parJour.rows.map((r) => [String(r.jour), r])), [parJour.rows]);
  const totalMois = useMemo(
    () =>
      parJour.rows.reduce<{ facture: number; encaisse: number }>(
        (s, r) => ({ facture: s.facture + num(r.montant_facture), encaisse: s.encaisse + num(r.montant_encaisse) }),
        { facture: 0, encaisse: 0 },
      ),
    [parJour.rows],
  );
  const jour = byDay.get(day);

  const columns: Array<Column> = [
    { key: 'heure', header: t('heure', 'Heure') },
    { key: 'facture', header: t('facture', 'Facture') },
    { key: 'patient', header: t('patient', 'Patient') },
    {
      key: 'statut',
      header: t('statut', 'Statut'),
      render: (r) => {
        const s = STATUTS[String(r.statut)] ?? { label: String(r.statut ?? ''), type: 'gray' as const };
        return <Tag type={s.type}>{s.label}</Tag>;
      },
    },
    { key: 'total', header: t('total', 'Total'), numeric: true, render: (r) => formatFcfa(r.total) },
    { key: 'paye', header: t('paye', 'Payé'), numeric: true, render: (r) => formatFcfa(r.paye) },
  ];

  const ventesColumns: Array<Column> = [
    { key: 'acte', header: t('acte', 'Acte ou examen') },
    { key: 'quantite', header: t('quantite', 'Quantité'), numeric: true, render: (r) => num(r.quantite) },
    { key: 'montant', header: t('montantFacture', 'Montant facturé'), numeric: true, render: (r) => formatFcfa(r.montant) },
  ];

  return (
    <>
      <div className={styles.totals}>
        <div>
          <span className={styles.totalLabel}>{t('encaisseMois', 'Encaissé ce mois')}</span>
          <span className={styles.totalValue}>{parJour.loading ? '…' : formatFcfa(totalMois.encaisse)}</span>
        </div>
        <div>
          <span className={styles.totalLabel}>{t('factureMois', 'Facturé ce mois')}</span>
          <span className={styles.totalValue}>{parJour.loading ? '…' : formatFcfa(totalMois.facture)}</span>
        </div>
        <div>
          <span className={styles.totalLabel}>
            {t('encaisseLe', 'Encaissé le')} {formatDay(day)}
          </span>
          <span className={styles.totalValue}>{parJour.loading ? '…' : formatFcfa(jour?.montant_encaisse)}</span>
        </div>
        <div>
          <span className={styles.totalLabel}>
            {t('factureLe', 'Facturé le')} {formatDay(day)}
          </span>
          <span className={styles.totalValue}>{parJour.loading ? '…' : formatFcfa(jour?.montant_facture)}</span>
        </div>
      </div>
      {parJour.error && <InlineNotification kind="error" title={parJour.error} lowContrast hideCloseButton />}
      {parJour.loading && <InlineLoading description={t('chargement', 'Chargement...')} />}
      <MonthCalendar
        month={month}
        onMonthChange={setMonth}
        selectedDay={day}
        onSelectDay={setDay}
        isActive={(d) => {
          const r = byDay.get(d);
          return !!r && (num(r.montant_encaisse) > 0 || num(r.montant_facture) > 0);
        }}
        renderDay={(d) => {
          const r = byDay.get(d);
          return (
            <>
              {t('enc', 'Enc.')} {fcfaCourt.format(num(r?.montant_encaisse))}
              <br />
              {t('fact', 'Fact.')} {fcfaCourt.format(num(r?.montant_facture))}
            </>
          );
        }}
      />
      <h4 className={styles.sectionTitle}>
        {t('facturesDu', 'Factures du')} {formatDay(day)}
      </h4>
      <DataTable
        columns={columns}
        rows={detail.rows}
        loading={detail.loading}
        error={detail.error}
        emptyText={t('aucuneFacture', 'Aucune facture ce jour-là (0 FCFA).')}
        onRowClick={openPatientChart}
      />
      <h4 className={styles.sectionTitle}>{t('ventesParActe', 'Ventes du mois par acte')}</h4>
      <DataTable
        columns={ventesColumns}
        rows={ventes.rows}
        loading={ventes.loading}
        error={ventes.error}
        emptyText={t('aucuneVente', 'Aucune vente ce mois-ci (0 FCFA).')}
      />
    </>
  );
};

export default RecettesTab;
