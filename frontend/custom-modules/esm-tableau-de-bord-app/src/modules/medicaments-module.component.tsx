import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { Pills } from '@carbon/react/icons';
import ModuleLayout from '../layout/module-layout.component';
import MedicamentsTab from '../medicaments/medicaments-tab.component';
import FicheMedicament from '../medicaments/fiche-medicament.component';
import StockTab from '../stock/stock-tab.component';

/** Module Médicaments : /openmrs/spa/medicaments (catalogue, fiche de chaque médicament, stock) */
const MedicamentsModule: React.FC = () => (
  <ModuleLayout
    base="medicaments"
    title="Médicaments"
    icon={Pills}
    sections={[
      { path: '', label: 'Catalogue' },
      { path: 'stock', label: 'Stock', externe: 'stock-management' },
    ]}>
    <Routes>
      <Route path="/" element={<MedicamentsTab />} />
      <Route path="/fiche/:uuid" element={<FicheMedicament />} />
      <Route path="/stock" element={<StockTab />} />
    </Routes>
  </ModuleLayout>
);

export default MedicamentsModule;
