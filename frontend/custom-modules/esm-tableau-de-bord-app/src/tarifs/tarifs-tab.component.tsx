import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Search } from '@carbon/react';
import { navigate } from '@openmrs/esm-framework';
import { DATASETS, formatFcfa, text, useDataSet } from '../api';
import DataTable, { type Column } from '../data-table.component';
import styles from '../root.scss';

/** Prix de tous les actes et examens facturables */
const TarifsTab: React.FC = () => {
  const { t } = useTranslation();
  const { rows, loading, error } = useDataSet(DATASETS.tarifs);
  const [query, setQuery] = useState('');

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return q ? rows.filter((r) => `${text(r.acte)} ${text(r.code)}`.toLowerCase().includes(q)) : rows;
  }, [rows, query]);

  const columns: Array<Column> = [
    { key: 'acte', header: t('acte', 'Acte ou examen') },
    { key: 'code', header: t('code', 'Nom court') },
    { key: 'tarif', header: t('tarif', 'Tarif') },
    { key: 'prix', header: t('prix', 'Prix'), numeric: true, render: (r) => formatFcfa(r.prix) },
  ];

  return (
    <>
      <div className={styles.toolbar}>
        <Search
          size="lg"
          labelText={t('rechercher', 'Rechercher')}
          placeholder={t('rechercherActe', 'Rechercher un acte ou un examen')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        {!loading && !error && (
          <span className={styles.count}>
            {filtered.length} / {rows.length} {t('tarifsLower', 'tarifs')}
          </span>
        )}
      </div>
      <DataTable
        columns={columns}
        rows={filtered}
        loading={loading}
        error={error}
        emptyText={t('aucunTarif', 'Aucun acte ne correspond à la recherche.')}
      />
      <p className={styles.note}>
        {t('modifierTarif', 'Pour ajouter un acte ou changer un prix (administrateur) :')}{' '}
        <a
          href="#"
          onClick={(e) => {
            e.preventDefault();
            navigate({ to: '${openmrsSpaBase}/billable-services' });
          }}>
          {t('gererTarifs', 'gérer les services facturables')}
        </a>
      </p>
    </>
  );
};

export default TarifsTab;
