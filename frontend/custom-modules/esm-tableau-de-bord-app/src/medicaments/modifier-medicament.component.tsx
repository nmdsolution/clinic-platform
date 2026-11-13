import React, { useState } from 'react';
import {
  Button,
  ComposedModal,
  InlineNotification,
  ModalBody,
  ModalFooter,
  ModalHeader,
  NumberInput,
  Select,
  SelectItem,
  Stack,
  TextInput,
} from '@carbon/react';
import { DATASETS, errorMessage, postRest, text, useDataSet, type Row } from '../api';

interface Props {
  fiche: Row;
  onClose: () => void;
  onSaved: () => void;
}

/** Modification du nom, du dosage, de la forme et du seuil d'alerte d'un médicament */
const ModifierMedicament: React.FC<Props> = ({ fiche, onClose, onSaved }) => {
  const formes = useDataSet(DATASETS.formes);
  const [nom, setNom] = useState(text(fiche.nom));
  const [dosage, setDosage] = useState(text(fiche.dosage));
  const [forme, setForme] = useState(text(fiche.forme_uuid));
  const [seuil, setSeuil] = useState<number | ''>(
    fiche.seuil === null || fiche.seuil === undefined ? '' : Number(fiche.seuil),
  );
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const suivi = !!fiche.stock_item_uuid;

  const save = async () => {
    if (!nom.trim()) {
      setError('Le nom est obligatoire.');
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await postRest(`drug/${fiche.uuid}`, {
        name: nom.trim(),
        strength: dosage.trim() || null,
        ...(forme ? { dosageForm: forme } : {}),
      });
      if (suivi && seuil !== '' && fiche.uom_uuid) {
        await postRest(`stockmanagement/stockitem/${fiche.stock_item_uuid}`, {
          commonName: nom.trim(),
          reorderLevel: seuil,
          reorderLevelUoMUuid: fiche.uom_uuid,
        });
      }
      onSaved();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <ComposedModal open onClose={onClose} preventCloseOnClickOutside>
      <ModalHeader title="Modifier le médicament" />
      <ModalBody hasForm>
        <Stack gap={5}>
          <TextInput id="nom" labelText="Nom affiché *" value={nom} onChange={(e) => setNom(e.target.value)} />
          <TextInput
            id="dosage"
            labelText="Dosage"
            placeholder="500mg"
            value={dosage}
            onChange={(e) => setDosage(e.target.value)}
          />
          <Select id="forme" labelText="Forme" value={forme} onChange={(e) => setForme(e.target.value)}>
            <SelectItem value="" text={formes.loading ? 'Chargement...' : 'Choisir une forme'} />
            {formes.rows.map((r) => (
              <SelectItem key={text(r.uuid)} value={text(r.uuid)} text={text(r.forme)} />
            ))}
          </Select>
          {suivi && (
            <NumberInput
              id="seuil"
              label={`Seuil d'alerte (${text(fiche.unite) || 'unités'})`}
              helperText={fiche.uom_uuid ? 'Alerte quand le stock descend à ce niveau.' : "Ajustez d'abord le stock une fois pour définir l'unité."}
              min={0}
              value={seuil}
              disabled={!fiche.uom_uuid}
              allowEmpty
              onChange={(_, { value }) => setSeuil(value === '' || value === undefined ? '' : Number(value))}
            />
          )}
          {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}
        </Stack>
      </ModalBody>
      <ModalFooter>
        <Button kind="secondary" onClick={onClose}>
          Annuler
        </Button>
        <Button kind="primary" onClick={save} disabled={saving}>
          {saving ? 'Enregistrement...' : 'Enregistrer'}
        </Button>
      </ModalFooter>
    </ComposedModal>
  );
};

export default ModifierMedicament;
