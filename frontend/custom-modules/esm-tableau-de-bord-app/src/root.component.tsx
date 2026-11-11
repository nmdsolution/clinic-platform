import React from 'react';
import { useTranslation } from 'react-i18next';
import { Tabs, TabList, Tab, TabPanels, TabPanel } from '@carbon/react';
import PatientsTab from './patients/patients-tab.component';
import ConsultationsTab from './consultations/consultations-tab.component';
import RecettesTab from './recettes/recettes-tab.component';
import StockTab from './stock/stock-tab.component';
import styles from './root.scss';

const Root: React.FC = () => {
  const { t } = useTranslation();

  return (
    <div className={styles.container}>
      <h3 className={styles.title}>{t('titre', 'Fondation Médicale FASSE — Tableau de bord')}</h3>
      <Tabs>
        <TabList aria-label={t('tableauDeBord', 'Tableau de bord')} contained>
          <Tab>{t('patients', 'Patients')}</Tab>
          <Tab>{t('consultations', 'Consultations')}</Tab>
          <Tab>{t('recettes', 'Recettes')}</Tab>
          <Tab>{t('stock', 'Stock')}</Tab>
        </TabList>
        <TabPanels>
          <TabPanel className={styles.panel}>
            <PatientsTab />
          </TabPanel>
          <TabPanel className={styles.panel}>
            <ConsultationsTab />
          </TabPanel>
          <TabPanel className={styles.panel}>
            <RecettesTab />
          </TabPanel>
          <TabPanel className={styles.panel}>
            <StockTab />
          </TabPanel>
        </TabPanels>
      </Tabs>
    </div>
  );
};

export default Root;
