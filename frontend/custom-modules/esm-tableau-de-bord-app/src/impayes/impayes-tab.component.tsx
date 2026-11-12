import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Search, Tag } from '@carbon/react';
import { DATASETS, formatDay, formatFcfa, num, text, useDataSet } from '../api';
import DataTable, { type Column } from '../data-table.component';
import { openPatientChart } from '../patients/patients-tab.component';
import styles from '../root.scss';

/** Factures non soldées : qui doit combien, depuis quand, et comment le joindre */
const ImpayesTab: React.FC = () => {
  const { t } = useTranslation();
  const { rows, loading, error } = useDataSet(DATASETS.impayes);
  const [query, setQuery] = useState('');

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return q
      ? rows.filter((r) => [r.patient, r.dossier, r.facture, r.telephone].map(text).join(' ').toLowerCase().includes(q))
      : rows;
  }, [rows, query]);

  const reste = useMemo(() => filtered.reduce((s, r) => s + num(r.reste), 0), [filtered]);

  const columns: Array<Column> = [
    { key: 'date_facture', header: t('date', 'Date'), render: (r) => formatDay(r.date_facture) },
    {
      key: 'jours',
      header: t('anciennete', 'Ancienneté'),
      render: (r) => {
        const j = num(r.jours);
        return <Tag type={j > 30 ? 'red' : j > 7 ? 'magenta' : 'gray'}>{j} j</Tag>;
      },
    },
    { key: 'facture', header: t('facture', 'Facture') },
    { key: 'dossier', header: t('dossier', 'N° dossier') },
    { key: 'patient', header: t('patient', 'Patient') },
    { key: 'telephone', header: t('telephone', 'Téléphone') },
    { key: 'total', header: t('total', 'Total'), numeric: true, render: (r) => formatFcfa(r.total) },
    { key: 'paye', header: t('paye', 'Payé'), numeric: true, render: (r) => formatFcfa(r.paye) },
    { key: 'reste', header: t('reste', 'Reste à payer'), numeric: true, render: (r) => formatFcfa(r.reste) },
  ];

  return (
    <>
      <div className={styles.totals}>
        <div>
          <span className={styles.totalLabel}>{t('resteARecouvrer', 'Reste à recouvrer')}</span>
          <span className={styles.totalValue}>{loading ? '…' : formatFcfa(reste)}</span>
        </div>
        <div>
          <span className={styles.totalLabel}>{t('facturesImpayees', 'Factures impayées')}</span>
          <span className={styles.totalValue}>{loading ? '…' : filtered.length}</span>
        </div>
      </div>
      <div className={styles.toolbar}>
        <Search
          size="lg"
          labelText={t('rechercher', 'Rechercher')}
          placeholder={t('rechercherImpaye', 'Rechercher par patient, n° de dossier, facture ou téléphone')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>
      <DataTable
        columns={columns}
        rows={filtered}
        loading={loading}
        error={error}
        emptyText={t('aucunImpaye', 'Aucune facture impayée.')}
        onRowClick={openPatientChart}
      />
    </>
  );
};

export default ImpayesTab;
