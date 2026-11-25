import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, InlineNotification, Search, Tag } from '@carbon/react';
import { DATASETS, errorMessage, formatFcfa, num, postRest, text, useDataSet, type Row } from '../api';
import DataTable, { type Column } from '../data-table.component';
import { openPatientChart } from '../patients/patients-tab.component';
import styles from '../root.scss';

const TYPE_HOSPITALISATION = 'Hospitalisation';
const SEUIL_HEURES = 24;

/** Une visite est « oubliée » si elle dure depuis plus de 24 h et n'est pas une hospitalisation */
export function estOubliee(row: Row): boolean {
  return text(row.type_visite) !== TYPE_HOSPITALISATION && num(row.heures) > SEUIL_HEURES;
}

/** Libellé de durée lisible : « 5 h » ou « 3 j » */
export function duree(heures: number): string {
  return heures < 48 ? `${heures} h` : `${Math.floor(heures / 24)} j`;
}

/**
 * Visites non clôturées (Phase 0, lot 3) : la clôture automatique tourne chaque soir,
 * cet écran sert à repérer et régulariser ce qui reste ouvert.
 */
const VisitesOuvertesTab: React.FC = () => {
  const { t } = useTranslation();
  const { rows, loading, error, reload } = useDataSet(DATASETS.visitesOuvertes);
  const [query, setQuery] = useState('');
  const [enCours, setEnCours] = useState<string | null>(null);
  const [erreurCloture, setErreurCloture] = useState<string | null>(null);

  const filtered = useMemo(() => {
    const q = query.toLowerCase().trim();
    return q
      ? rows.filter((r) => [r.patient, r.dossier, r.type_visite, r.lieu].map(text).join(' ').toLowerCase().includes(q))
      : rows;
  }, [rows, query]);

  const oubliees = useMemo(() => filtered.filter(estOubliee).length, [filtered]);

  const cloturer = async (row: Row) => {
    const uuid = text(row.visite_uuid);
    if (!uuid || !window.confirm(t('confirmerCloture', 'Clôturer la visite de {{patient}} maintenant ?', { patient: text(row.patient) }))) {
      return;
    }
    setEnCours(uuid);
    setErreurCloture(null);
    try {
      await postRest(`visit/${uuid}`, { stopDatetime: new Date().toISOString() });
      reload();
    } catch (err) {
      setErreurCloture(errorMessage(err));
    } finally {
      setEnCours(null);
    }
  };

  const columns: Array<Column> = [
    { key: 'debut', header: t('debut', 'Début') },
    {
      key: 'heures',
      header: t('duree', 'Durée'),
      render: (r) => <Tag type={estOubliee(r) ? 'red' : 'gray'}>{duree(num(r.heures))}</Tag>,
    },
    { key: 'type_visite', header: t('typeVisite', 'Type de visite') },
    { key: 'dossier', header: t('dossier', 'N° dossier') },
    { key: 'patient', header: t('patient', 'Patient') },
    { key: 'lieu', header: t('lieu', 'Lieu') },
    {
      key: 'impaye',
      header: t('impaye', 'Impayé'),
      numeric: true,
      render: (r) => (num(r.impaye) > 0 ? <Tag type="magenta">{formatFcfa(r.impaye)}</Tag> : '—'),
    },
    {
      key: 'action',
      header: '',
      render: (r) =>
        text(r.type_visite) === TYPE_HOSPITALISATION ? (
          <span>{t('sortieDepuisDossier', 'Sortie depuis le dossier')}</span>
        ) : (
          <Button
            kind="ghost"
            size="sm"
            disabled={enCours === text(r.visite_uuid)}
            onClick={(e: React.MouseEvent) => {
              e.stopPropagation();
              cloturer(r);
            }}>
            {enCours === text(r.visite_uuid) ? t('clotureEnCours', 'Clôture…') : t('cloturer', 'Clôturer')}
          </Button>
        ),
    },
  ];

  return (
    <>
      <div className={styles.totals}>
        <div>
          <span className={styles.totalLabel}>{t('visitesOuvertes', 'Visites ouvertes')}</span>
          <span className={styles.totalValue}>{loading ? '…' : filtered.length}</span>
        </div>
        <div>
          <span className={styles.totalLabel}>{t('visitesOubliees', 'Ouvertes depuis plus de 24 h')}</span>
          <span className={styles.totalValue}>{loading ? '…' : oubliees}</span>
        </div>
      </div>
      <p>
        {t(
          'aideVisitesOuvertes',
          'Les consultations sont clôturées automatiquement chaque soir à 23 h 59. Les hospitalisations restent ouvertes jusqu’à la sortie du patient.',
        )}
      </p>
      {erreurCloture && (
        <InlineNotification
          kind="error"
          lowContrast
          title={t('clotureImpossible', 'Clôture impossible')}
          subtitle={erreurCloture}
          onClose={() => setErreurCloture(null)}
        />
      )}
      <div className={styles.toolbar}>
        <Search
          size="lg"
          labelText={t('rechercher', 'Rechercher')}
          placeholder={t('rechercherVisite', 'Rechercher par patient, n° de dossier, type de visite ou lieu')}
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>
      <DataTable
        columns={columns}
        rows={filtered}
        loading={loading}
        error={error}
        emptyText={t('aucuneVisiteOuverte', 'Aucune visite ouverte.')}
        onRowClick={openPatientChart}
      />
    </>
  );
};

export default VisitesOuvertesTab;
