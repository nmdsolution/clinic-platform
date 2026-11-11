import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Search } from '@carbon/react';
import { navigate } from '@openmrs/esm-framework';
import { DATASETS, formatDay, text, useDataSet, type Row } from '../api';
import DataTable, { type Column } from '../data-table.component';
import styles from '../root.scss';

export function openPatientChart(row: Row) {
  if (row.uuid) {
    navigate({ to: `\${openmrsSpaBase}/patient/${row.uuid}/chart` });
  }
}

/** Tous les patients enregistrés, avec recherche ; un clic ouvre le dossier */
const PatientsTab: React.FC = () => {
  const { t } = useTranslation();
  const { rows, loading, error } = useDataSet(DATASETS.patients);
  const [query, setQuery] = useState('');

  const filtered = useMemo(() => {
    const words = query.toLowerCase().split(/\s+/).filter(Boolean);
    if (!words.length) return rows;
    return rows.filter((r) => {
      const hay = [r.dossier, r.nom, r.prenom, r.telephone].map(text).join(' ').toLowerCase();
      return words.every((w) => hay.includes(w));
    });
  }, [rows, query]);

  const columns: Array<Column> = [
    { key: 'dossier', header: t('dossier', 'N° dossier') },
    { key: 'nom', header: t('nom', 'Nom') },
    { key: 'prenom', header: t('prenom', 'Prénom') },
    { key: 'sexe', header: t('sexe', 'Sexe') },
    { key: 'age', header: t('age', 'Âge'), numeric: true },
    { key: 'telephone', header: t('telephone', 'Téléphone') },
    { key: 'enregistre', header: t('enregistre', 'Enregistré le'), render: (r) => formatDay(r.enregistre) },
    { key: 'derniere_visite', header: t('derniereVisite', 'Dernière visite'), render: (r) => formatDay(r.derniere_visite) },
  ];

  return (
    <>
      <div className={styles.toolbar}>
        <Search
          size="lg"
          labelText={t('rechercher', 'Rechercher')}
          placeholder={t('rechercherPatient', 'Rechercher par nom, prénom, n° de dossier ou téléphone')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        {!loading && !error && (
          <span className={styles.count}>
            {filtered.length} / {rows.length} {t('patientsLower', 'patients')}
          </span>
        )}
      </div>
      <DataTable
        columns={columns}
        rows={filtered}
        loading={loading}
        error={error}
        emptyText={t('aucunPatient', 'Aucun patient ne correspond à la recherche.')}
        onRowClick={openPatientChart}
      />
    </>
  );
};

export default PatientsTab;
