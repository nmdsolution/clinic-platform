import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Tabs, TabList, Tab, TabPanels, TabPanel } from '@carbon/react';
import ParcoursTab from './parcours/parcours-tab.component';
import PatientsTab from './patients/patients-tab.component';
import ConsultationsTab from './consultations/consultations-tab.component';
import RecettesTab from './recettes/recettes-tab.component';
import ImpayesTab from './impayes/impayes-tab.component';
import TarifsTab from './tarifs/tarifs-tab.component';
import MedicamentsTab from './medicaments/medicaments-tab.component';
import StockTab from './stock/stock-tab.component';
import styles from './root.scss';

const ONGLETS = ['parcours', 'patients', 'consultations', 'recettes', 'impayes', 'tarifs', 'medicaments', 'stock'];

const Root: React.FC = () => {
  const { t } = useTranslation();
  const [index, setIndex] = useState(0);
  const openTab = (onglet: string) => setIndex(Math.max(0, ONGLETS.indexOf(onglet)));

  return (
    <div className={styles.container}>
      <h3 className={styles.title}>{t('titre', 'Fondation Médicale FASSE — Tableau de bord')}</h3>
      <Tabs selectedIndex={index} onChange={({ selectedIndex }) => setIndex(selectedIndex)}>
        <TabList aria-label={t('tableauDeBord', 'Tableau de bord')} contained>
          <Tab>{t('parcoursPatient', 'Parcours patient')}</Tab>
          <Tab>{t('patients', 'Patients')}</Tab>
          <Tab>{t('consultations', 'Consultations')}</Tab>
          <Tab>{t('recettes', 'Recettes')}</Tab>
          <Tab>{t('impayes', 'Impayés')}</Tab>
          <Tab>{t('tarifs', 'Tarifs')}</Tab>
          <Tab>{t('medicaments', 'Médicaments')}</Tab>
          <Tab>{t('stock', 'Stock')}</Tab>
        </TabList>
        <TabPanels>
          <TabPanel className={styles.panel}>
            <ParcoursTab onOpenTab={openTab} />
          </TabPanel>
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
            <ImpayesTab />
          </TabPanel>
          <TabPanel className={styles.panel}>
            <TarifsTab />
          </TabPanel>
          <TabPanel className={styles.panel}>
            <MedicamentsTab />
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
