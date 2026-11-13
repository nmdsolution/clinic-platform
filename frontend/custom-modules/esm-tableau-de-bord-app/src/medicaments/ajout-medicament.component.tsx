import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Button,
  Checkbox,
  ComposedModal,
  InlineNotification,
  ModalBody,
  ModalFooter,
  ModalHeader,
  Select,
  SelectItem,
  Stack,
  TextInput,
} from '@carbon/react';
import { DATASETS, errorMessage, getRest, postRest, text, useDataSet } from '../api';

/** Identifiants standard d'OpenMRS (vérifiés sur la base FASSE) */
const CLASSE_MEDICAMENT = '8d490dfc-c2cc-11de-8d13-0010c6dffd0f';
const TYPE_NA = '8d4a4c94-c2cc-11de-8d13-0010c6dffd0f';

interface Props {
  open: boolean;
  onClose: () => void;
  onCreated: (nom: string) => void;
}

interface ConceptSearch {
  results: Array<{ uuid: string; display: string; conceptClass?: { uuid: string } }>;
}

/**
 * Crée en une fois : le concept (s'il n'existe pas), le médicament et sa fiche de stock.
 * Remplace l'enchaînement Concepts > Médicaments > Stock de l'administration.
 */
const AjoutMedicament: React.FC<Props> = ({ open, onClose, onCreated }) => {
  const { t } = useTranslation();
  const formes = useDataSet(DATASETS.formes);
  const [dci, setDci] = useState('');
  const [dosage, setDosage] = useState('');
  const [forme, setForme] = useState('');
  const [nom, setNom] = useState('');
  const [suivreStock, setSuivreStock] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const formeNom = text(formes.rows.find((r) => r.uuid === forme)?.forme).replace(' (Clinique Fasse)', '');
  // Nom affiché proposé : « Amoxicilline 500mg comprimé », modifiable
  const nomPropose = [dci.trim(), dosage.trim(), formeNom.toLowerCase()].filter(Boolean).join(' ');
  const nomFinal = (nom || nomPropose).trim();

  const reset = () => {
    setDci('');
    setDosage('');
    setForme('');
    setNom('');
    setSuivreStock(true);
    setError(null);
  };

  const close = () => {
    reset();
    onClose();
  };

  const save = async () => {
    if (!dci.trim() || !nomFinal) {
      setError(t('nomObligatoire', 'Indiquez au moins le nom du principe actif (DCI).'));
      return;
    }
    setSaving(true);
    setError(null);
    try {
      // 1. Concept : on réutilise un concept « Drug » du même nom s'il existe déjà
      const found = await getRest<ConceptSearch>(
        `concept?q=${encodeURIComponent(dci.trim())}&v=custom:(uuid,display,conceptClass:(uuid))`,
      );
      const existing = found.results.find(
        (c) => c.display.trim().toLowerCase() === dci.trim().toLowerCase() && c.conceptClass?.uuid === CLASSE_MEDICAMENT,
      );
      const conceptUuid =
        existing?.uuid ??
        (
          await postRest('concept', {
            names: [{ name: dci.trim(), locale: 'fr', localePreferred: true, conceptNameType: 'FULLY_SPECIFIED' }],
            datatype: TYPE_NA,
            conceptClass: CLASSE_MEDICAMENT,
          })
        ).uuid;

      // 2. Médicament (prescriptible)
      const drug = await postRest('drug', {
        name: nomFinal,
        concept: conceptUuid,
        combination: false,
        ...(dosage.trim() ? { strength: dosage.trim() } : {}),
        ...(forme ? { dosageForm: forme } : {}),
      });

      // 3. Fiche de stock liée au médicament (jamais d'article sans lien)
      if (suivreStock) {
        await postRest('stockmanagement/stockitem', {
          drugUuid: drug.uuid,
          isDrug: true,
          hasExpiration: true,
          commonName: nomFinal,
        });
      }

      onCreated(nomFinal);
      reset();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <ComposedModal open={open} onClose={close} preventCloseOnClickOutside>
      <ModalHeader title={t('ajouterMedicament', 'Ajouter un médicament')} />
      <ModalBody hasForm>
        <Stack gap={5}>
          <TextInput
            id="dci"
            labelText={t('dci', 'Principe actif (DCI) *')}
            placeholder="Amoxicilline"
            value={dci}
            onChange={(e) => setDci(e.target.value)}
          />
          <TextInput
            id="dosage"
            labelText={t('dosage', 'Dosage')}
            placeholder="500mg"
            value={dosage}
            onChange={(e) => setDosage(e.target.value)}
          />
          <Select
            id="forme"
            labelText={t('forme', 'Forme')}
            value={forme}
            onChange={(e) => setForme(e.target.value)}
            disabled={formes.loading}>
            <SelectItem value="" text={formes.loading ? t('chargement', 'Chargement...') : t('choisir', 'Choisir une forme')} />
            {formes.rows.map((r) => (
              <SelectItem key={text(r.uuid)} value={text(r.uuid)} text={text(r.forme)} />
            ))}
          </Select>
          <TextInput
            id="nom"
            labelText={t('nomAffiche', 'Nom affiché (prescription, stock, facture)')}
            placeholder={nomPropose || 'Amoxicilline 500mg comprimé'}
            helperText={t('nomAfficheAide', 'Laissez vide pour utiliser le nom proposé.')}
            value={nom}
            onChange={(e) => setNom(e.target.value)}
          />
          <Checkbox
            id="suivre-stock"
            labelText={t('suivreStock', 'Suivre ce médicament en stock')}
            checked={suivreStock}
            onChange={(_, { checked }) => setSuivreStock(checked)}
          />
          {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}
        </Stack>
      </ModalBody>
      <ModalFooter>
        <Button kind="secondary" onClick={close}>
          {t('annuler', 'Annuler')}
        </Button>
        <Button kind="primary" onClick={save} disabled={saving}>
          {saving ? t('enregistrement', 'Enregistrement...') : t('enregistrer', 'Enregistrer')}
        </Button>
      </ModalFooter>
    </ComposedModal>
  );
};

export default AjoutMedicament;
