import React, { useEffect, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import {
  Button,
  Tag,
  InlineNotification,
  StructuredListWrapper,
  StructuredListHead,
  StructuredListRow,
  StructuredListCell,
  StructuredListBody,
} from '@carbon/react';
import { CaisseApi, CaisseApiError, type Invoice } from '../caisse-api';
import PaymentModal from './payment-modal.component';
import styles from './invoice-list.scss';

interface Props {
  api: CaisseApi;
  currency: string;
  refreshKey: number;
}

const STATUS_KIND: Record<Invoice['status'], 'gray' | 'blue' | 'green' | 'red'> = {
  OPEN: 'gray',
  PARTIALLY_PAID: 'blue',
  PAID: 'green',
  CANCELLED: 'red',
};

const InvoiceList: React.FC<Props> = ({ api, currency, refreshKey }) => {
  const { t } = useTranslation();
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [payingInvoice, setPayingInvoice] = useState<Invoice | null>(null);

  const today = new Date().toISOString().slice(0, 10);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const list = await api.listInvoices({ date_from: today, date_to: today });
      setInvoices(list);
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('loadError', 'Chargement impossible'));
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [api, today]);

  useEffect(() => {
    load();
  }, [load, refreshKey]);

  if (loading) {
    return <p>{t('loading', 'Chargement...')}</p>;
  }

  return (
    <div className={styles.container}>
      {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}

      {invoices.length === 0 ? (
        <p>{t('noInvoicesToday', "Aucune facture aujourd'hui.")}</p>
      ) : (
        <StructuredListWrapper>
          <StructuredListHead>
            <StructuredListRow head>
              <StructuredListCell head>{t('invoiceNumber', 'N° facture')}</StructuredListCell>
              <StructuredListCell head>{t('patient', 'Patient')}</StructuredListCell>
              <StructuredListCell head>{t('total', 'Total')}</StructuredListCell>
              <StructuredListCell head>{t('balanceDue', 'Solde dû')}</StructuredListCell>
              <StructuredListCell head>{t('status', 'Statut')}</StructuredListCell>
              <StructuredListCell head />
            </StructuredListRow>
          </StructuredListHead>
          <StructuredListBody>
            {invoices.map((inv) => (
              <StructuredListRow key={inv.id}>
                <StructuredListCell>{inv.invoice_number}</StructuredListCell>
                <StructuredListCell>{inv.patient_display}</StructuredListCell>
                <StructuredListCell>{inv.total_amount} {currency}</StructuredListCell>
                <StructuredListCell>{inv.balance_due} {currency}</StructuredListCell>
                <StructuredListCell>
                  <Tag type={STATUS_KIND[inv.status]}>{inv.status}</Tag>
                </StructuredListCell>
                <StructuredListCell>
                  {inv.balance_due > 0 && (
                    <Button kind="tertiary" size="sm" onClick={() => setPayingInvoice(inv)}>
                      {t('collectPayment', 'Encaisser')}
                    </Button>
                  )}
                </StructuredListCell>
              </StructuredListRow>
            ))}
          </StructuredListBody>
        </StructuredListWrapper>
      )}

      {payingInvoice && (
        <PaymentModal
          api={api}
          invoice={payingInvoice}
          currency={currency}
          onClose={() => setPayingInvoice(null)}
          onPaid={() => {
            setPayingInvoice(null);
            load();
          }}
        />
      )}
    </div>
  );
};

export default InvoiceList;
