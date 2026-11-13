import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { Button, InlineLoading, InlineNotification, Tag } from '@carbon/react';
import { ArrowLeft, Edit, Renew } from '@carbon/react/icons';
import { DATASETS, formatDay, num, postRest, text, useDataSet, errorMessage, type Row } from '../api';
import DataTable, { type Column } from '../data-table.component';
import ModifierMedicament from './modifier-medicament.component';
import AjusterStock from './ajuster-stock.component';
import styles from './fiche-medicament.scss';

const qte = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 2 });

/** Noms français des opérations du module Stock */
const OPERATIONS: Record<string, string> = {
  Adjustment: 'Ajustement',
  Disposal: 'Mise au rebut',
  'Transfer Out': 'Transfert',
  Receipt: 'Réception',
  Return: 'Retour',
  'Stock Issue': 'Sortie',
  Requisition: 'Demande',
  'Stock Take': 'Inventaire',
  'Opening Stock': "Stock d'ouverture",
  Dispensation: 'Dispensation',
  Mouvement: 'Mouvement',
};

/** Fiche d'un médicament, à la manière de Dolibarr : infos modifiables, stock par lot, historique */
const FicheMedicament: React.FC = () => {
  const { uuid = '' } = useParams();
  const goTo = useNavigate();
  const params = { drugUuid: uuid };
  const info = useDataSet(DATASETS.ficheInfo, params);
  const stock = useDataSet(DATASETS.ficheStock, params);
  const historique = useDataSet(DATASETS.ficheHistorique, params);
  const [modifier, setModifier] = useState(false);
  const [ajuster, setAjuster] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [erreur, setErreur] = useState<string | null>(null);
  const [suiviEnCours, setSuiviEnCours] = useState(false);

  const d: Row = info.rows[0] ?? {};
  const suivi = !!d.stock_item_uuid;

  const reloadAll = (msg: string) => {
    setMessage(msg);
    info.reload();
    stock.reload();
    historique.reload();
  };

  // Crée la fiche de stock d'un médicament qui n'en a pas encore
  const suivreEnStock = async () => {
    setSuiviEnCours(true);
    setErreur(null);
    try {
      await postRest('stockmanagement/stockitem', {
        drugUuid: uuid,
        hasExpiration: true,
        commonName: text(d.nom),
      });
      reloadAll('Le médicament est maintenant suivi en stock.');
    } catch (err) {
      setErreur(errorMessage(err));
    } finally {
      setSuiviEnCours(false);
    }
  };

  if (info.loading) return <InlineLoading description="Chargement..." />;
  if (info.error) return <InlineNotification kind="error" title={info.error} lowContrast hideCloseButton />;
  if (!info.rows.length) return <p>Médicament introuvable.</p>;

  const stockColumns: Array<Column> = [
    { key: 'magasin', header: 'Magasin' },
    { key: 'lot', header: 'Lot' },
    { key: 'peremption', header: 'Péremption', render: (r) => formatDay(r.peremption) },
    { key: 'quantite', header: 'Quantité', numeric: true, render: (r) => qte.format(num(r.quantite)) },
  ];

  const historiqueColumns: Array<Column> = [
    { key: 'date', header: 'Date', render: (r) => `${formatDay(r.date)} ${text(r.date).slice(11)}` },
    { key: 'operation', header: 'Opération', render: (r) => OPERATIONS[text(r.operation)] ?? text(r.operation) },
    { key: 'numero', header: 'N°' },
    { key: 'magasin', header: 'Magasin' },
    { key: 'lot', header: 'Lot' },
    {
      key: 'quantite',
      header: 'Quantité',
      numeric: true,
      render: (r) => {
        const q = num(r.quantite);
        return <span className={q < 0 ? styles.negatif : styles.positif}>{(q > 0 ? '+' : '') + qte.format(q)}</span>;
      },
    },
    { key: 'motif', header: 'Motif' },
    { key: 'par', header: 'Par' },
  ];

  return (
    <div className={styles.fiche}>
      <Button kind="ghost" size="sm" renderIcon={ArrowLeft} onClick={() => goTo('/')}>
        Retour au catalogue
      </Button>

      {message && (
        <InlineNotification kind="success" title={message} lowContrast onClose={() => setMessage(null)} />
      )}
      {erreur && <InlineNotification kind="error" title={erreur} lowContrast onClose={() => setErreur(null)} />}

      <section className={styles.carte}>
        <div className={styles.carteEntete}>
          <h2 className={styles.nom}>{text(d.nom)}</h2>
          <Button kind="tertiary" size="md" renderIcon={Edit} onClick={() => setModifier(true)}>
            Modifier
          </Button>
        </div>
        <dl className={styles.infos}>
          <div>
            <dt>Principe actif (DCI)</dt>
            <dd>{text(d.dci) || '—'}</dd>
          </div>
          <div>
            <dt>Dosage</dt>
            <dd>{text(d.dosage) || '—'}</dd>
          </div>
          <div>
            <dt>Forme</dt>
            <dd>{text(d.forme) || '—'}</dd>
          </div>
          <div>
            <dt>Stock total</dt>
            <dd className={styles.gros}>
              {suivi ? `${qte.format(num(d.quantite))} ${text(d.unite)}` : <Tag type="gray">Non suivi en stock</Tag>}
            </dd>
          </div>
          <div>
            <dt>Seuil d'alerte</dt>
            <dd>{d.seuil === null || d.seuil === undefined ? '—' : qte.format(num(d.seuil))}</dd>
          </div>
        </dl>
      </section>

      <section className={styles.carte}>
        <div className={styles.carteEntete}>
          <h3 className={styles.titreSection}>Stock par magasin et par lot</h3>
          {suivi ? (
            <Button size="md" renderIcon={Renew} onClick={() => setAjuster(true)}>
              Ajuster le stock
            </Button>
          ) : (
            <Button size="md" onClick={suivreEnStock} disabled={suiviEnCours}>
              {suiviEnCours ? 'Création...' : 'Suivre en stock'}
            </Button>
          )}
        </div>
        <DataTable
          columns={stockColumns}
          rows={stock.rows}
          loading={stock.loading}
          error={stock.error}
          emptyText={suivi ? 'Aucun stock enregistré pour ce médicament.' : "Ce médicament n'est pas suivi en stock."}
        />
      </section>

      <section className={styles.carte}>
        <h3 className={styles.titreSection}>Historique des mouvements</h3>
        <DataTable
          columns={historiqueColumns}
          rows={historique.rows}
          loading={historique.loading}
          error={historique.error}
          emptyText="Aucun mouvement de stock."
        />
      </section>

      {modifier && (
        <ModifierMedicament
          fiche={d}
          onClose={() => setModifier(false)}
          onSaved={() => {
            setModifier(false);
            reloadAll('Fiche enregistrée.');
          }}
        />
      )}
      {ajuster && (
        <AjusterStock
          fiche={d}
          lots={stock.rows}
          onClose={() => setAjuster(false)}
          onSaved={() => {
            setAjuster(false);
            reloadAll('Stock ajusté.');
          }}
        />
      )}
    </div>
  );
};

export default FicheMedicament;
