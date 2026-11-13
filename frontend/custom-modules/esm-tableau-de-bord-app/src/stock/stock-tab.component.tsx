import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Dropdown, Search, Tag } from '@carbon/react';
import { DATASETS, formatDay, num, text, useDataSet } from '../api';
import DataTable, { type Column } from '../data-table.component';
import styles from '../root.scss';

const ETATS: Record<string, 'green' | 'red' | 'magenta' | 'warm-gray' | 'purple'> = {
  OK: 'green',
  Rupture: 'red',
  Périmé: 'magenta',
  'Périme sous 90 jours': 'purple',
  'Sous le seuil': 'warm-gray',
};

const TOUS = 'Tous les magasins';
const qte = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 2 });

/** État du stock par magasin (pharmacie, laboratoire, ...), avec recherche par article */
const StockTab: React.FC = () => {
  const { t } = useTranslation();
  const stock = useDataSet(DATASETS.stock);
  const magasins = useDataSet(DATASETS.magasins);
  const [magasin, setMagasin] = useState('Pharmacie principale');
  const [query, setQuery] = useState('');

  // Magasins déclarés + magasins ayant des mouvements (au cas où un lieu n'a pas le tag)
  const options = useMemo(() => {
    const names = new Set<string>([...magasins.rows, ...stock.rows].map((r) => text(r.magasin)).filter(Boolean));
    return [TOUS, ...Array.from(names).sort((a, b) => a.localeCompare(b, 'fr'))];
  }, [magasins.rows, stock.rows]);

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return stock.rows.filter(
      (r) => (magasin === TOUS || r.magasin === magasin) && (!q || text(r.article).toLowerCase().includes(q)),
    );
  }, [stock.rows, magasin, query]);

  const alertes = filtered.filter((r) => r.etat !== 'OK').length;

  const columns: Array<Column> = [
    ...(magasin === TOUS ? [{ key: 'magasin', header: t('magasin', 'Magasin') }] : []),
    { key: 'article', header: t('article', 'Article') },
    { key: 'lot', header: t('lot', 'Lot') },
    { key: 'peremption', header: t('peremption', 'Péremption'), render: (r) => formatDay(r.peremption) },
    { key: 'quantite', header: t('quantite', 'Quantité'), numeric: true, render: (r) => qte.format(num(r.quantite)) },
    { key: 'unite', header: t('unite', 'Unité') },
    { key: 'seuil', header: t('seuil', "Seuil d'alerte"), numeric: true },
    {
      key: 'etat',
      header: t('etat', 'État'),
      render: (r) => <Tag type={ETATS[text(r.etat)] ?? 'gray'}>{text(r.etat)}</Tag>,
    },
  ];

  return (
    <>
      <div className={styles.toolbar}>
        <Dropdown
          id="magasin"
          titleText={t('magasin', 'Magasin')}
          label={magasin}
          items={options}
          selectedItem={magasin}
          onChange={({ selectedItem }) => setMagasin(selectedItem ?? TOUS)}
        />
        <Search
          size="lg"
          labelText={t('rechercher', 'Rechercher')}
          placeholder={t('rechercherArticle', 'Rechercher un article')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        {!stock.loading && !stock.error && (
          <span className={styles.count}>
            {filtered.length} {t('lignes', 'lignes')} — {alertes} {t('enAlerte', 'en alerte')}
          </span>
        )}
      </div>
      <DataTable
        columns={columns}
        rows={filtered}
        loading={stock.loading}
        error={stock.error}
        emptyText={t(
          'aucunArticle',
          "Aucun article enregistré dans ce magasin. Les réceptions saisies dans « Stock » apparaîtront ici.",
        )}
      />
      <p className={styles.note}>
        {t('ajusterDepuisFiche', 'Pour une entrée ou une sortie, ouvrez le médicament dans le Catalogue puis « Ajuster le stock ».')}{' '}
        {t('operationsAvancees', 'Réceptions fournisseur, transferts et inventaires :')}{' '}
        <a href={`${window.getOpenmrsSpaBase()}stock-management`}>{t('gestionAvancee', 'gestion avancée du stock')}</a>
      </p>
    </>
  );
};

export default StockTab;
