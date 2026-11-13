import React, { useMemo, useState } from 'react';
import {
  Button,
  ComposedModal,
  DatePicker,
  DatePickerInput,
  InlineNotification,
  ModalBody,
  ModalFooter,
  ModalHeader,
  NumberInput,
  RadioButton,
  RadioButtonGroup,
  Select,
  SelectItem,
  Stack,
  TextInput,
} from '@carbon/react';
import { useSession } from '@openmrs/esm-framework';
import { DATASETS, errorMessage, isoDay, num, postRest, text, useDataSet, type Row } from '../api';

/** Type d'opération « Adjustment » du module Stock (uuid fixe de l'installation) */
const OPERATION_AJUSTEMENT = '11111111-1111-1111-1111-111111111111';
const NOUVEAU_LOT = 'nouveau';

interface Props {
  fiche: Row;
  /** Lignes de stock du médicament (magasin, lot, quantité) */
  lots: Array<Row>;
  onClose: () => void;
  onSaved: () => void;
}

/**
 * Entrée ou sortie de stock en une action : une opération « Ajustement » est créée
 * puis clôturée dans le module Stock, ce qui met à jour le stock et l'historique.
 */
const AjusterStock: React.FC<Props> = ({ fiche, lots, onClose, onSaved }) => {
  const session = useSession();
  const magasins = useDataSet(DATASETS.magasins);
  const [magasin, setMagasin] = useState(text(lots[0]?.location_uuid));
  const [sens, setSens] = useState<'entree' | 'sortie'>('entree');
  const [quantite, setQuantite] = useState<number | ''>('');
  const [lot, setLot] = useState('');
  const [numeroLot, setNumeroLot] = useState('');
  const [peremption, setPeremption] = useState<Date | null>(null);
  const [motif, setMotif] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const avecPeremption = num(fiche.avec_peremption) === 1;
  const lotsDuMagasin = useMemo(() => lots.filter((l) => l.location_uuid === magasin && l.batch_uuid), [lots, magasin]);
  const lotChoisi = lot || text(lotsDuMagasin[0]?.batch_uuid) || NOUVEAU_LOT;
  const disponible = num(lotsDuMagasin.find((l) => l.batch_uuid === lotChoisi)?.quantite);

  const save = async () => {
    const q = Number(quantite);
    if (!magasin) return setError('Choisissez le magasin.');
    if (!q || q <= 0) return setError('Indiquez une quantité supérieure à 0.');
    if (!motif.trim()) return setError('Indiquez le motif (ex. livraison, casse, erreur de comptage).');
    if (sens === 'sortie' && lotChoisi !== NOUVEAU_LOT && q > disponible) {
      return setError(`Quantité trop grande : il reste ${disponible} dans ce lot.`);
    }
    if (avecPeremption && lotChoisi === NOUVEAU_LOT && (!numeroLot.trim() || !peremption)) {
      return setError('Pour un nouveau lot, indiquez son numéro et sa date de péremption.');
    }
    setSaving(true);
    setError(null);
    try {
      // Un article créé sans unité de stock en reçoit une (unité la plus courante, facteur 1)
      let uom = text(fiche.uom_uuid);
      if (!uom) {
        uom = (
          await postRest('stockmanagement/stockitempackaginguom', {
            stockItemUuid: fiche.stock_item_uuid,
            packagingUomUuid: fiche.unite_defaut_uuid,
            factor: 1,
          })
        ).uuid;
      }

      const item =
        lotChoisi === NOUVEAU_LOT
          ? {
              batchNo: numeroLot.trim() || undefined,
              expiration: peremption ? `${isoDay(peremption)}T00:00:00.000Z` : undefined,
            }
          : { stockBatchUuid: lotChoisi };

      const operation = await postRest('stockmanagement/stockoperation', {
        operationTypeUuid: OPERATION_AJUSTEMENT,
        atLocationUuid: magasin,
        sourceUuid: magasin,
        operationDate: new Date().toISOString(),
        remarks: motif.trim(),
        responsiblePersonUuid: session?.user?.person?.uuid,
        approvalRequired: false,
        stockOperationItems: [
          {
            stockItemUuid: fiche.stock_item_uuid,
            stockItemPackagingUOMUuid: uom,
            quantity: sens === 'sortie' ? -q : q,
            ...item,
          },
        ],
      });

      // Sans approbation, l'opération se clôture directement ; sinon on la soumet d'abord
      try {
        await postRest('stockmanagement/stockoperationaction', { name: 'COMPLETE', uuid: operation.uuid });
      } catch {
        await postRest('stockmanagement/stockoperationaction', { name: 'SUBMIT', uuid: operation.uuid });
        await postRest('stockmanagement/stockoperationaction', { name: 'COMPLETE', uuid: operation.uuid });
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
      <ModalHeader title={`Ajuster le stock — ${text(fiche.nom)}`} />
      <ModalBody hasForm>
        <Stack gap={5}>
          <RadioButtonGroup
            name="sens"
            legendText="Mouvement"
            valueSelected={sens}
            onChange={(v) => setSens(v as 'entree' | 'sortie')}>
            <RadioButton id="entree" value="entree" labelText="Entrée (+)" />
            <RadioButton id="sortie" value="sortie" labelText="Sortie (−)" />
          </RadioButtonGroup>
          <Select id="magasin" labelText="Magasin *" value={magasin} onChange={(e) => setMagasin(e.target.value)}>
            <SelectItem value="" text={magasins.loading ? 'Chargement...' : 'Choisir un magasin'} />
            {magasins.rows.map((m) => (
              <SelectItem key={text(m.uuid)} value={text(m.uuid)} text={text(m.magasin)} />
            ))}
          </Select>
          <Select id="lot" labelText="Lot" value={lotChoisi} onChange={(e) => setLot(e.target.value)}>
            {lotsDuMagasin.map((l) => (
              <SelectItem
                key={text(l.batch_uuid)}
                value={text(l.batch_uuid)}
                text={`${text(l.lot) || 'sans numéro'} — reste ${num(l.quantite)}`}
              />
            ))}
            {sens === 'entree' && <SelectItem value={NOUVEAU_LOT} text="Nouveau lot" />}
          </Select>
          {lotChoisi === NOUVEAU_LOT && (
            <>
              <TextInput
                id="numero-lot"
                labelText={avecPeremption ? 'Numéro du lot *' : 'Numéro du lot'}
                value={numeroLot}
                onChange={(e) => setNumeroLot(e.target.value)}
              />
              {avecPeremption && (
                <DatePicker
                  datePickerType="single"
                  dateFormat="d/m/Y"
                  minDate={isoDay(new Date())}
                  onChange={([date]) => setPeremption(date ?? null)}>
                  <DatePickerInput id="peremption" labelText="Date de péremption *" placeholder="jj/mm/aaaa" />
                </DatePicker>
              )}
            </>
          )}
          <NumberInput
            id="quantite"
            label={`Quantité (${text(fiche.unite) || 'unités'}) *`}
            min={0}
            value={quantite}
            allowEmpty
            onChange={(_, { value }) => setQuantite(value === '' || value === undefined ? '' : Number(value))}
          />
          <TextInput
            id="motif"
            labelText="Motif *"
            placeholder="Livraison du fournisseur, casse, erreur de comptage..."
            value={motif}
            onChange={(e) => setMotif(e.target.value)}
          />
          {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}
        </Stack>
      </ModalBody>
      <ModalFooter>
        <Button kind="secondary" onClick={onClose}>
          Annuler
        </Button>
        <Button kind="primary" onClick={save} disabled={saving}>
          {saving ? 'Enregistrement...' : 'Valider le mouvement'}
        </Button>
      </ModalFooter>
    </ComposedModal>
  );
};

export default AjusterStock;
