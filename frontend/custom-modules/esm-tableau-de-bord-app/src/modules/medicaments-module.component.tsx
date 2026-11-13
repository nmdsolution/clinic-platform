import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { Pills } from '@carbon/react/icons';
import ModuleLayout from '../layout/module-layout.component';
import MedicamentsTab from '../medicaments/medicaments-tab.component';

/** Module Médicaments : /openmrs/spa/medicaments */
const MedicamentsModule: React.FC = () => (
  <ModuleLayout
    base="medicaments"
    title="Médicaments"
    icon={Pills}
    sections={[
      { path: '', label: 'Catalogue' },
      { path: 'ajouter', label: 'Ajouter un médicament' },
    ]}>
    <Routes>
      <Route path="/" element={<MedicamentsTab />} />
      <Route path="/ajouter" element={<MedicamentsTab ouvrirAjout />} />
    </Routes>
  </ModuleLayout>
);

export default MedicamentsModule;
