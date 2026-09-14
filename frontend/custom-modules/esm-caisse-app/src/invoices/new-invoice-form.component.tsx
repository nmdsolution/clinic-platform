import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Button,
  TextInput,
  NumberInput,
  Select,
  SelectItem,
  InlineNotification,
  Stack,
  Tile,
  StructuredListWrapper,
  StructuredListHead,
  StructuredListRow,
  StructuredListCell,
  StructuredListBody,
} from '@carbon/react';
import { TrashCan } from '@carbon/react/icons';
import { CaisseApi, CaisseApiError, type Invoice, type InvoiceLine, type PatientSearchResult } from '../caisse-api';
import styles from './new-invoice-form.scss';

const CATEGORIES = [
  'CONSULTATION',
  'LABORATOIRE',
  'IMAGERIE',
  'EXAMEN_FONCTIONNEL',
  'MEDICAMENT',
  'KINESITHERAPIE',
  'DENTAIRE',
  'OPHTALMOLOGIE',
  'SOINS',
  'AUTRE',
];

interface Props {
  api: CaisseApi;
  currency: string;
  onInvoiceCreated: (invoice: Invoice) => void;
}

const NewInvoiceForm: React.FC<Props> = ({ api, currency, onInvoiceCreated }) => {
  const { t } = useTranslation();

  const [query, setQuery] = useState('');
  const [results, setResults] = useState<PatientSearchResult[]>([]);
  const [selectedPatient, setSelectedPatient] = useState<PatientSearchResult | null>(null);
  const [searching, setSearching] = useState(false);

  const [lines, setLines] = useState<InvoiceLine[]>([]);
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [description, setDescription] = useState('');
  const [unitPrice, setUnitPrice] = useState(0);
  const [quantity, setQuantity] = useState(1);

  const [discount, setDiscount] = useState(0);
  const [insurance, setInsurance] = useState(0);

  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleSearch = async () => {
    if (query.trim().length < 2) return;
    setSearching(true);
    setError(null);
    try {
      const found = await api.searchPatients(query.trim());
      setResults(found);
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('searchError', 'Recherche impossible'));
    } finally {
      setSearching(false);
    }
  };

  const addLine = () => {
    if (!description.trim() || unitPrice < 0 || quantity < 1) return;
    setLines((prev) => [...prev, { category, description: description.trim(), unit_price: unitPrice, quantity }]);
    setDescription('');
    setUnitPrice(0);
    setQuantity(1);
  };

  const removeLine = (index: number) => {
    setLines((prev) => prev.filter((_, i) => i !== index));
  };

  const total = lines.reduce((sum, l) => sum + l.unit_price * l.quantity, 0) - discount - insurance;

  const handleSubmit = async () => {
    if (!selectedPatient || lines.length === 0) return;
    setSubmitting(true);
    setError(null);
    try {
      const invoice = await api.createInvoice({
        patient_uuid: selectedPatient.uuid,
        patient_display: selectedPatient.display,
        lines,
        discount_amount: discount,
        insurance_covered_amount: insurance,
      });
      onInvoiceCreated(invoice);
      setSelectedPatient(null);
      setResults([]);
      setQuery('');
      setLines([]);
      setDiscount(0);
      setInsurance(0);
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('createInvoiceError', 'Création de facture impossible'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className={styles.container}>
      {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}

      <Tile className={styles.tile}>
        <Stack gap={4}>
          <h5>{t('step1Patient', '1. Patient')}</h5>
          {!selectedPatient ? (
            <>
              <div className={styles.searchRow}>
                <TextInput
                  id="patient-search"
                  labelText={t('searchPatient', 'Rechercher un patient (nom ou numéro de dossier)')}
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                />
                <Button onClick={handleSearch} disabled={searching || query.trim().length < 2}>
                  {t('search', 'Rechercher')}
                </Button>
              </div>
              {results.length > 0 && (
                <ul className={styles.resultsList}>
                  {results.map((r) => (
                    <li key={r.uuid}>
                      <button type="button" className={styles.resultItem} onClick={() => setSelectedPatient(r)}>
                        {r.display}
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </>
          ) : (
            <div className={styles.selectedPatient}>
              <strong>{selectedPatient.display}</strong>
              <Button kind="ghost" size="sm" onClick={() => setSelectedPatient(null)}>
                {t('change', 'Changer')}
              </Button>
            </div>
          )}
        </Stack>
      </Tile>

      <Tile className={styles.tile}>
        <Stack gap={4}>
          <h5>{t('step2Lines', '2. Actes et médicaments')}</h5>
          <div className={styles.lineForm}>
            <Select id="line-category" labelText={t('category', 'Catégorie')} value={category} onChange={(e) => setCategory(e.target.value)}>
              {CATEGORIES.map((c) => (
                <SelectItem key={c} value={c} text={c} />
              ))}
            </Select>
            <TextInput id="line-description" labelText={t('description', 'Description')} value={description} onChange={(e) => setDescription(e.target.value)} />
            <NumberInput id="line-unit-price" label={t('unitPrice', `Prix unitaire (${currency})`)} value={unitPrice} min={0} step={100} onChange={(_e, { value }) => setUnitPrice(Number(value) || 0)} />
            <NumberInput id="line-quantity" label={t('quantity', 'Quantité')} value={quantity} min={1} step={1} onChange={(_e, { value }) => setQuantity(Number(value) || 1)} />
            <Button onClick={addLine}>{t('addLine', 'Ajouter la ligne')}</Button>
          </div>

          {lines.length > 0 && (
            <StructuredListWrapper>
              <StructuredListHead>
                <StructuredListRow head>
                  <StructuredListCell head>{t('description', 'Description')}</StructuredListCell>
                  <StructuredListCell head>{t('unitPrice', 'Prix unitaire')}</StructuredListCell>
                  <StructuredListCell head>{t('quantity', 'Qté')}</StructuredListCell>
                  <StructuredListCell head>{t('total', 'Total')}</StructuredListCell>
                  <StructuredListCell head />
                </StructuredListRow>
              </StructuredListHead>
              <StructuredListBody>
                {lines.map((l, i) => (
                  <StructuredListRow key={i}>
                    <StructuredListCell>{l.description}</StructuredListCell>
                    <StructuredListCell>{l.unit_price} {currency}</StructuredListCell>
                    <StructuredListCell>{l.quantity}</StructuredListCell>
                    <StructuredListCell>{l.unit_price * l.quantity} {currency}</StructuredListCell>
                    <StructuredListCell>
                      <Button kind="ghost" size="sm" hasIconOnly iconDescription={t('remove', 'Retirer')} renderIcon={TrashCan} onClick={() => removeLine(i)} />
                    </StructuredListCell>
                  </StructuredListRow>
                ))}
              </StructuredListBody>
            </StructuredListWrapper>
          )}
        </Stack>
      </Tile>

      <Tile className={styles.tile}>
        <Stack gap={4}>
          <h5>{t('step3Totals', '3. Remise / Assurance / Total')}</h5>
          <NumberInput id="discount" label={t('discount', `Remise (${currency})`)} value={discount} min={0} step={100} onChange={(_e, { value }) => setDiscount(Number(value) || 0)} />
          <NumberInput id="insurance" label={t('insuranceCovered', `Part assurance (${currency})`)} value={insurance} min={0} step={100} onChange={(_e, { value }) => setInsurance(Number(value) || 0)} />
          <p className={styles.totalLine}>
            {t('invoiceTotal', 'Total facture')}: <strong>{Math.max(total, 0)} {currency}</strong>
          </p>
          <Button onClick={handleSubmit} disabled={submitting || !selectedPatient || lines.length === 0}>
            {submitting ? t('creating', 'Création...') : t('createInvoice', 'Créer la facture')}
          </Button>
        </Stack>
      </Tile>
    </div>
  );
};

export default NewInvoiceForm;
