import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, Checkbox, InlineNotification, Search, Tag } from '@carbon/react';
import { Add } from '@carbon/react/icons';
import { useNavigate } from 'react-router-dom';
import { DATASETS, num, text, useDataSet } from '../api';
import DataTable, { type Column } from '../data-table.component';
import AjoutMedicament from './ajout-medicament.component';
import styles from '../root.scss';

const ETATS: Record<string, 'green' | 'red' | 'gray'> = {
  'En stock': 'green',
  Rupture: 'red',
  'Non suivi en stock': 'gray',
};

const qte = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 2 });

/** Médicaments prescriptibles et leur stock : remplace la lecture de l'écran d'administration */
interface Props {
  /** Ouvre directement le formulaire (entrée « Ajouter un médicament » du menu) */
  ouvrirAjout?: boolean;
}

const MedicamentsTab: React.FC<Props> = ({ ouvrirAjout = false }) => {
  const { t } = useTranslation();
  const goTo = useNavigate();
  const { rows, loading, error, reload } = useDataSet(DATASETS.medicaments);
  const [ajoutOuvert, setAjoutOuvert] = useState(ouvrirAjout);
  const [cree, setCree] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [suivisSeulement, setSuivisSeulement] = useState(false);

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return rows.filter(
      (r) =>
        (!suivisSeulement || r.etat !== 'Non suivi en stock') && (!q || text(r.medicament).toLowerCase().includes(q)),
    );
  }, [rows, query, suivisSeulement]);

  const columns: Array<Column> = [
    { key: 'medicament', header: t('medicament', 'Médicament') },
    { key: 'dosage', header: t('dosage', 'Dosage') },
    { key: 'forme', header: t('forme', 'Forme') },
    {
      key: 'quantite',
      header: t('quantiteStock', 'Quantité en stock'),
      numeric: true,
      render: (r) => (r.etat === 'Non suivi en stock' ? '—' : qte.format(num(r.quantite))),
    },
    {
      key: 'etat',
      header: t('etat', 'État'),
      render: (r) => <Tag type={ETATS[text(r.etat)] ?? 'gray'}>{text(r.etat)}</Tag>,
    },
  ];

  return (
    <>
      {cree && (
        <InlineNotification
          kind="success"
          title={t('medicamentCree', 'Médicament ajouté :')}
          subtitle={cree}
          lowContrast
          onClose={() => setCree(null)}
        />
      )}
      <div className={styles.toolbar}>
        <Button renderIcon={Add} size="lg" onClick={() => setAjoutOuvert(true)}>
          {t('ajouterMedicament', 'Ajouter un médicament')}
        </Button>
        <Search
          size="lg"
          labelText={t('rechercher', 'Rechercher')}
          placeholder={t('rechercherMedicament', 'Rechercher un médicament')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <Checkbox
          id="suivis-seulement"
          labelText={t('suivisSeulement', 'Seulement les médicaments suivis en stock')}
          checked={suivisSeulement}
          onChange={(_, { checked }) => setSuivisSeulement(checked)}
        />
        {!loading && !error && (
          <span className={styles.count}>
            {filtered.length} / {rows.length} {t('medicamentsLower', 'médicaments')}
          </span>
        )}
      </div>
      <DataTable
        columns={columns}
        rows={filtered}
        loading={loading}
        error={error}
        emptyText={t('aucunMedicament', 'Aucun médicament ne correspond à la recherche.')}
      />
      <AjoutMedicament
        open={ajoutOuvert}
        onClose={() => {
          setAjoutOuvert(false);
          if (ouvrirAjout) goTo('/');
        }}
        onCreated={(nom) => {
          setAjoutOuvert(false);
          if (ouvrirAjout) goTo('/');
          setCree(nom);
          setQuery(nom);
          reload();
        }}
      />
      <p className={styles.note}>
        {t('corrigerMedicament', 'Pour corriger ou retirer un médicament (administrateur) :')}{' '}
        <a href="/openmrs/admin/concepts/conceptDrug.list">{t('gererMedicaments', 'gérer le dictionnaire des médicaments')}</a>
      </p>
    </>
  );
};

export default MedicamentsTab;
