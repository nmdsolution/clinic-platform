import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Modal, NumberInput, Select, SelectItem, TextInput, InlineNotification } from '@carbon/react';
import { CaisseApi, CaisseApiError, type Invoice } from '../caisse-api';

const METHODS = ['ESPECES', 'MOBILE_MONEY', 'ORANGE_MONEY', 'VIREMENT', 'ASSURANCE', 'GRATUITE'];

interface Props {
  api: CaisseApi;
  invoice: Invoice;
  currency: string;
  onClose: () => void;
  onPaid: () => void;
}

const PaymentModal: React.FC<Props> = ({ api, invoice, currency, onClose, onPaid }) => {
  const { t } = useTranslation();
  const [amount, setAmount] = useState(invoice.balance_due);
  const [method, setMethod] = useState(METHODS[0]);
  const [reference, setReference] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async () => {
    setSubmitting(true);
    setError(null);
    try {
      await api.recordPayment(invoice.id, { amount, method, reference: reference || undefined });
      onPaid();
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('paymentError', 'Encaissement impossible'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal
      open
      modalHeading={t('collectPaymentFor', 'Encaissement — {{invoice}}', { invoice: invoice.invoice_number })}
      primaryButtonText={submitting ? t('processing', 'Traitement...') : t('confirm', 'Confirmer')}
      secondaryButtonText={t('cancel', 'Annuler')}
      onRequestClose={onClose}
      onRequestSubmit={handleSubmit}
      primaryButtonDisabled={submitting || amount <= 0 || amount > invoice.balance_due}
    >
      {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}
      <p>
        {t('patient', 'Patient')}: <strong>{invoice.patient_display}</strong>
      </p>
      <p>
        {t('balanceDue', 'Solde dû')}: <strong>{invoice.balance_due} {currency}</strong>
      </p>
      <NumberInput
        id="payment-amount"
        label={t('amountToCollect', `Montant à encaisser (${currency})`)}
        value={amount}
        min={1}
        max={invoice.balance_due}
        step={100}
        onChange={(_e, { value }) => setAmount(Number(value) || 0)}
      />
      <Select id="payment-method" labelText={t('paymentMethod', 'Moyen de paiement')} value={method} onChange={(e) => setMethod(e.target.value)}>
        {METHODS.map((m) => (
          <SelectItem key={m} value={m} text={m} />
        ))}
      </Select>
      {(method === 'MOBILE_MONEY' || method === 'ORANGE_MONEY' || method === 'VIREMENT') && (
        <TextInput
          id="payment-reference"
          labelText={t('transactionReference', 'Référence de transaction')}
          value={reference}
          onChange={(e) => setReference(e.target.value)}
        />
      )}
    </Modal>
  );
};

export default PaymentModal;
