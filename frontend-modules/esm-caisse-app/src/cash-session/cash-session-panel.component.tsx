import React, { useEffect, useState, useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, NumberInput, InlineNotification, Tile, Stack, TextArea } from '@carbon/react';
import { CaisseApi, CaisseApiError, type CashSession } from '../caisse-api';
import styles from './cash-session-panel.scss';

interface Props {
  api: CaisseApi;
  currency: string;
}

const CashSessionPanel: React.FC<Props> = ({ api, currency }) => {
  const { t } = useTranslation();
  const [session, setSession] = useState<CashSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [openingFloat, setOpeningFloat] = useState(0);
  const [countedCash, setCountedCash] = useState(0);
  const [countedMobileMoney, setCountedMobileMoney] = useState(0);
  const [countedOther, setCountedOther] = useState(0);
  const [notes, setNotes] = useState('');
  const [lastClosed, setLastClosed] = useState<CashSession | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const current = await api.getCurrentCashSession();
      setSession(current);
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('loadError', 'Chargement impossible'));
    } finally {
      setLoading(false);
    }
  }, [api, t]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const handleOpen = async () => {
    setError(null);
    try {
      const opened = await api.openCashSession(openingFloat);
      setSession(opened);
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('openError', "Impossible d'ouvrir la caisse"));
    }
  };

  const handleClose = async () => {
    if (!session) return;
    setError(null);
    try {
      const closed = await api.closeCashSession(session.id, {
        counted_cash: countedCash,
        counted_mobile_money: countedMobileMoney,
        counted_other: countedOther,
        notes,
      });
      setLastClosed(closed);
      setSession(null);
      setCountedCash(0);
      setCountedMobileMoney(0);
      setCountedOther(0);
      setNotes('');
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('closeError', 'Impossible de fermer la caisse'));
    }
  };

  if (loading) {
    return <p>{t('loading', 'Chargement...')}</p>;
  }

  return (
    <div className={styles.container}>
      {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}

      {!session && (
        <Tile className={styles.tile}>
          <Stack gap={5}>
            <h5>{t('openCashSession', 'Ouvrir la caisse')}</h5>
            <NumberInput
              id="opening-float"
              label={t('openingFloat', 'Fonds de caisse de départ')}
              value={openingFloat}
              min={0}
              step={500}
              onChange={(_e, { value }) => setOpeningFloat(Number(value) || 0)}
            />
            <Button onClick={handleOpen}>{t('open', 'Ouvrir')}</Button>
          </Stack>
        </Tile>
      )}

      {session && (
        <Tile className={styles.tile}>
          <Stack gap={5}>
            <h5>{t('cashSessionOpenSince', 'Caisse ouverte depuis')} {new Date(session.opened_at).toLocaleString()}</h5>
            <p>
              {t('openingFloat', 'Fonds de caisse de départ')}: {session.opening_float} {currency}
            </p>
            <p>
              {t('expectedCash', 'Montant théorique en espèces')}: <strong>{session.expected_amount} {currency}</strong>
            </p>
            <h6>{t('closeCashSession', 'Fermer la caisse')}</h6>
            <NumberInput
              id="counted-cash"
              label={t('countedCash', 'Espèces comptées')}
              value={countedCash}
              min={0}
              step={500}
              onChange={(_e, { value }) => setCountedCash(Number(value) || 0)}
            />
            <NumberInput
              id="counted-mobile-money"
              label={t('countedMobileMoney', 'Mobile Money / Orange Money compté')}
              value={countedMobileMoney}
              min={0}
              step={500}
              onChange={(_e, { value }) => setCountedMobileMoney(Number(value) || 0)}
            />
            <NumberInput
              id="counted-other"
              label={t('countedOther', 'Autres moyens de paiement')}
              value={countedOther}
              min={0}
              step={500}
              onChange={(_e, { value }) => setCountedOther(Number(value) || 0)}
            />
            <TextArea
              id="close-notes"
              labelText={t('notes', 'Remarques (optionnel)')}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
            <Button kind="danger" onClick={handleClose}>
              {t('close', 'Fermer la caisse')}
            </Button>
          </Stack>
        </Tile>
      )}

      {lastClosed && (
        <InlineNotification
          kind={lastClosed.variance === 0 ? 'success' : 'warning'}
          lowContrast
          title={t('sessionClosed', 'Session de caisse fermée')}
          subtitle={
            lastClosed.variance === 0
              ? t('noVariance', 'Aucun écart constaté.')
              : t('variance', 'Écart constaté : {{amount}} {{currency}}', {
                  amount: lastClosed.variance,
                  currency,
                })
          }
        />
      )}
    </div>
  );
};

export default CashSessionPanel;
