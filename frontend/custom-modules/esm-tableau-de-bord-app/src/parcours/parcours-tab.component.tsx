import React from 'react';
import { useTranslation } from 'react-i18next';
import { InlineNotification } from '@carbon/react';
import { ArrowRight } from '@carbon/react/icons';
import { navigate } from '@openmrs/esm-framework';
import { DATASETS, formatFcfa, num, useDataSet } from '../api';
import styles from './parcours.scss';

interface Etape {
  titre: string;
  qui: string;
  quoi: string;
  action: string;
  /** Chemin dans l'application, ou nom d'un onglet de ce tableau de bord */
  to?: string;
  onglet?: string;
  chiffre?: string;
}

interface Props {
  onOpenTab: (onglet: string) => void;
}

/**
 * Parcours du patient tel qu'il se déroule dans une clinique camerounaise :
 * on enregistre, on paie à la caisse, puis on est reçu ; les examens et les
 * médicaments se paient avant d'être réalisés ou remis.
 */
const ParcoursTab: React.FC<Props> = ({ onOpenTab }) => {
  const { t } = useTranslation();
  const { rows, loading, error } = useDataSet(DATASETS.indicateurs);
  const k = rows[0] ?? {};
  const n = (key: string) => (loading ? '…' : String(num(k[key])));

  const etapes: Array<Etape> = [
    {
      titre: 'Accueil',
      qui: "Agent d'accueil",
      quoi: "Rechercher le patient ; s'il est nouveau, créer son dossier, puis ouvrir sa visite.",
      action: 'Enregistrer un patient',
      to: 'patient-registration',
      chiffre: `${n('patients_jour')} nouveau(x) patient(s) aujourd'hui`,
    },
    {
      titre: 'Caisse',
      qui: 'Caissier',
      quoi: 'Facturer la consultation et encaisser (espèces, Orange Money, MTN MoMo) avant le passage chez le médecin.',
      action: 'Ouvrir la facturation',
      to: 'home/billing',
      chiffre: `${n('factures_jour')} facture(s), ${loading ? '…' : formatFcfa(k.encaisse_jour)} encaissés aujourd'hui`,
    },
    {
      titre: 'Paramètres et attente',
      qui: 'Infirmier',
      quoi: "Prendre les signes vitaux (tension, température, poids) et placer le patient dans la file d'attente.",
      action: "Ouvrir les files d'attente",
      to: 'home/service-queues',
      chiffre: `${n('visites_jour')} visite(s) ouverte(s) aujourd'hui`,
    },
    {
      titre: 'Consultation',
      qui: 'Médecin',
      quoi: 'Ouvrir le dossier, saisir la consultation, prescrire les examens et les médicaments.',
      action: 'Voir les patients présents',
      to: 'home',
      chiffre: `${n('visites_ouvertes')} visite(s) non clôturée(s)`,
    },
    {
      titre: 'Laboratoire',
      qui: 'Technicien de laboratoire',
      quoi: 'Après paiement des examens à la caisse : prélever, saisir et valider les résultats.',
      action: 'Ouvrir le laboratoire',
      to: 'home/laboratory',
      chiffre: `${n('examens_en_attente')} examen(s) en attente (7 derniers jours)`,
    },
    {
      titre: 'Pharmacie',
      qui: 'Pharmacien',
      quoi: "Après paiement de l'ordonnance : délivrer les médicaments. Le stock diminue automatiquement.",
      action: 'Ouvrir la dispensation',
      to: 'dispensing',
    },
    {
      titre: 'Sortie et impayés',
      qui: 'Caissier',
      quoi: 'Vérifier que tout est soldé avant le départ du patient et suivre les factures restées impayées.',
      action: 'Voir les impayés',
      onglet: 'impayes',
      chiffre: `${n('impayes_nb')} facture(s) impayée(s), ${loading ? '…' : formatFcfa(k.impayes_montant)} à recouvrer`,
    },
  ];

  const gestion: Array<Etape> = [
    { titre: 'Recettes', qui: '', quoi: 'Encaissé et facturé par jour, ventes par acte.', action: 'Voir les recettes', onglet: 'recettes' },
    { titre: 'Tarifs', qui: '', quoi: 'Prix de tous les actes et examens.', action: 'Voir les tarifs', onglet: 'tarifs' },
    { titre: 'Médicaments', qui: '', quoi: 'Liste des médicaments et quantité en stock.', action: 'Voir les médicaments', onglet: 'medicaments' },
    { titre: 'Stock', qui: '', quoi: 'Réceptions, sorties et inventaires par magasin.', action: 'Gérer le stock', to: 'stock-management' },
    { titre: 'Rendez-vous', qui: '', quoi: 'Planifier et suivre les rendez-vous.', action: 'Ouvrir les rendez-vous', to: 'home/appointments' },
    { titre: 'Rapports', qui: '', quoi: 'Rapports à exporter (Excel).', action: 'Ouvrir les rapports', to: 'reports' },
  ];

  const open = (e: Etape) => {
    if (e.onglet) {
      onOpenTab(e.onglet);
    } else if (e.to !== undefined) {
      navigate({ to: `\${openmrsSpaBase}/${e.to}` });
    }
  };

  return (
    <>
      {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}
      <p className={styles.intro}>
        {t('parcoursIntro', "Le chemin d'un patient dans la clinique, étape par étape. Cliquez sur une étape pour ouvrir l'écran correspondant.")}
      </p>
      <ol className={styles.steps}>
        {etapes.map((e, i) => (
          <li key={e.titre}>
            <button type="button" className={styles.step} onClick={() => open(e)}>
              <span className={styles.stepNumber}>{i + 1}</span>
              <span className={styles.stepBody}>
                <span className={styles.stepTitle}>{e.titre}</span>
                <span className={styles.stepWho}>{e.qui}</span>
                <span className={styles.stepWhat}>{e.quoi}</span>
                {e.chiffre && <span className={styles.stepFigure}>{e.chiffre}</span>}
                <span className={styles.stepAction}>
                  {e.action} <ArrowRight size={16} />
                </span>
              </span>
            </button>
          </li>
        ))}
      </ol>
      <h4 className={styles.gestionTitle}>{t('gestion', 'Gestion de la clinique')}</h4>
      <div className={styles.gestion}>
        {gestion.map((e) => (
          <button key={e.titre} type="button" className={styles.gestionCard} onClick={() => open(e)}>
            <span className={styles.stepTitle}>{e.titre}</span>
            <span className={styles.stepWhat}>{e.quoi}</span>
            <span className={styles.stepAction}>
              {e.action} <ArrowRight size={16} />
            </span>
          </button>
        ))}
      </div>
    </>
  );
};

export default ParcoursTab;
