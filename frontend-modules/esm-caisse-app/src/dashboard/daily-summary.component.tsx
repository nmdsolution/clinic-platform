import React, { useEffect, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { InlineNotification, Tile } from '@carbon/react';
import { CaisseApi, CaisseApiError, type DailySummary } from '../caisse-api';
import styles from './daily-summary.scss';

interface Props {
  api: CaisseApi;
  currency: string;
  refreshKey: number;
}

const DailySummaryPanel: React.FC<Props> = ({ api, currency, refreshKey }) => {
  const { t } = useTranslation();
  const [summary, setSummary] = useState<DailySummary | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setSummary(await api.getDailySummary());
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('loadError', 'Chargement impossible'));
    } finally {
      setLoading(false);
    }
  }, [api, t]);

  useEffect(() => {
    load();
  }, [load, refreshKey]);

  if (loading) return <p>{t('loading', 'Chargement...')}</p>;
  if (error) return <InlineNotification kind="error" title={error} lowContrast hideCloseButton />;
  if (!summary) return null;

  return (
    <div className={styles.grid}>
      <Tile className={styles.tile}>
        <span className={styles.label}>{t('invoicesToday', 'Factures aujourd\'hui')}</span>
        <span className={styles.value}>{summary.invoices_count}</span>
      </Tile>
      <Tile className={styles.tile}>
        <span className={styles.label}>{t('totalBilled', 'Chiffre d\'affaires facturé')}</span>
        <span className={styles.value}>{summary.total_billed} {currency}</span>
      </Tile>
      <Tile className={styles.tile}>
        <span className={styles.label}>{t('totalCollected', 'Montant encaissé')}</span>
        <span className={styles.value}>{summary.total_collected} {currency}</span>
      </Tile>
      <Tile className={styles.tile}>
        <span className={styles.label}>{t('unpaidInvoices', 'Factures non payées')}</span>
        <span className={styles.value}>
          {summary.unpaid_invoices_count} ({summary.unpaid_amount} {currency})
        </span>
      </Tile>
      <Tile className={styles.tile}>
        <span className={styles.label}>{t('byPaymentMethod', 'Par moyen de paiement')}</span>
        <ul className={styles.breakdown}>
          {Object.entries(summary.by_payment_method).map(([method, amount]) => (
            <li key={method}>
              {method}: {amount} {currency}
            </li>
          ))}
        </ul>
      </Tile>
      <Tile className={styles.tile}>
        <span className={styles.label}>{t('byCategory', 'Par catégorie d\'acte')}</span>
        <ul className={styles.breakdown}>
          {Object.entries(summary.by_category).map(([cat, amount]) => (
            <li key={cat}>
              {cat}: {amount} {currency}
            </li>
          ))}
        </ul>
      </Tile>
    </div>
  );
};

export default DailySummaryPanel;
