import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { Receipt } from '@carbon/react/icons';
import ModuleLayout from '../layout/module-layout.component';
import RecettesTab from '../recettes/recettes-tab.component';
import ImpayesTab from '../impayes/impayes-tab.component';
import TarifsTab from '../tarifs/tarifs-tab.component';

/** Module Ventes : /openmrs/spa/ventes (la saisie des factures reste dans « En cours de facturation ») */
const VentesModule: React.FC = () => (
  <ModuleLayout
    base="ventes"
    title="Ventes"
    icon={Receipt}
    sections={[
      { path: '', label: 'Recettes' },
      { path: 'impayes', label: 'Impayés' },
      { path: 'tarifs', label: 'Tarifs' },
    ]}>
    <Routes>
      <Route path="/" element={<RecettesTab />} />
      <Route path="/impayes" element={<ImpayesTab />} />
      <Route path="/tarifs" element={<TarifsTab />} />
    </Routes>
  </ModuleLayout>
);

export default VentesModule;
