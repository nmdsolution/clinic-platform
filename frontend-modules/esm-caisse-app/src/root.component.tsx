import React, { useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useConfig } from '@openmrs/esm-framework';
import { Tabs, TabList, Tab, TabPanels, TabPanel, Button } from '@carbon/react';
import { CaisseApi, getStoredToken, getStoredUser, type CaisseUser, type Invoice } from './caisse-api';
import type { CaisseConfig } from './config-schema';
import LoginForm from './login/login-form.component';
import NewInvoiceForm from './invoices/new-invoice-form.component';
import InvoiceList from './invoices/invoice-list.component';
import CashSessionPanel from './cash-session/cash-session-panel.component';
import DailySummaryPanel from './dashboard/daily-summary.component';
import styles from './root.scss';

const Root: React.FC = () => {
  const { t } = useTranslation();
  const config = useConfig<CaisseConfig>();
  const api = useMemo(() => new CaisseApi(config.apiBasePath), [config.apiBasePath]);

  const [user, setUser] = useState<CaisseUser | null>(() => (getStoredToken() ? getStoredUser() : null));
  const [ssoAttempted, setSsoAttempted] = useState(false);
  const [invoicesRefreshKey, setInvoicesRefreshKey] = useState(0);

  // Pas de compte Caisse en cache : on tente une connexion silencieuse via
  // la session OpenMRS déjà ouverte avant d'afficher le formulaire de login.
  useEffect(() => {
    if (user || ssoAttempted) {
      return;
    }
    api
      .ssoLogin()
      .then(setUser)
      .catch(() => {
        /* pas de session OpenMRS exploitable : on affichera le formulaire */
      })
      .finally(() => setSsoAttempted(true));
  }, [api, user, ssoAttempted]);

  const handleLogout = () => {
    // On ne relance pas le SSO ici : un·e caissier·e qui se déconnecte
    // explicitement doit retomber sur le formulaire (poste partagé entre
    // plusieurs personnes), pas être reconnecté·e automatiquement tant que
    // la session OpenMRS elle-même reste ouverte.
    api.logout();
    setUser(null);
  };

  const handleInvoiceCreated = (_invoice: Invoice) => {
    setInvoicesRefreshKey((k) => k + 1);
  };

  if (!user) {
    if (!ssoAttempted) {
      return (
        <div className={styles.container}>
          <h3 className={styles.title}>{t('caisseTitle', 'Clinique FACE — Caisse & Facturation')}</h3>
          <p>{t('connecting', 'Connexion en cours...')}</p>
        </div>
      );
    }
    return (
      <div className={styles.container}>
        <h3 className={styles.title}>{t('caisseTitle', 'Clinique FACE — Caisse & Facturation')}</h3>
        <LoginForm api={api} onLoggedIn={setUser} />
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <div className={styles.header}>
        <h3 className={styles.title}>{t('caisseTitle', 'Clinique FACE — Caisse & Facturation')}</h3>
        <div className={styles.userInfo}>
          <span>
            {user.full_name} ({user.role})
          </span>
          <Button kind="ghost" size="sm" onClick={handleLogout}>
            {t('logout', 'Déconnexion')}
          </Button>
        </div>
      </div>

      <Tabs>
        <TabList aria-label={t('caisseTabs', 'Sections caisse')}>
          <Tab>{t('newInvoice', 'Nouvelle facture')}</Tab>
          <Tab>{t('todaysInvoices', "Factures du jour")}</Tab>
          <Tab>{t('cashSession', 'Caisse')}</Tab>
          <Tab>{t('dashboard', 'Tableau de bord')}</Tab>
        </TabList>
        <TabPanels>
          <TabPanel>
            <NewInvoiceForm api={api} currency={config.currency} onInvoiceCreated={handleInvoiceCreated} />
          </TabPanel>
          <TabPanel>
            <InvoiceList api={api} currency={config.currency} refreshKey={invoicesRefreshKey} />
          </TabPanel>
          <TabPanel>
            <CashSessionPanel api={api} currency={config.currency} />
          </TabPanel>
          <TabPanel>
            <DailySummaryPanel api={api} currency={config.currency} refreshKey={invoicesRefreshKey} />
          </TabPanel>
        </TabPanels>
      </Tabs>
    </div>
  );
};

export default Root;
