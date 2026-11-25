import React from 'react';
import { Route, Routes } from 'react-router-dom';
import { UserMultiple } from '@carbon/react/icons';
import ModuleLayout from '../layout/module-layout.component';
import PatientsTab from '../patients/patients-tab.component';
import ConsultationsTab from '../consultations/consultations-tab.component';
import VisitesOuvertesTab from '../visites/visites-ouvertes-tab.component';

/** Module Patients : /openmrs/spa/patients */
const PatientsModule: React.FC = () => (
  <ModuleLayout
    base="patients"
    title="Patients"
    icon={UserMultiple}
    sections={[
      { path: '', label: 'Liste des patients' },
      { path: 'consultations', label: 'Consultations' },
      { path: 'visites-ouvertes', label: 'Visites ouvertes' },
    ]}>
    <Routes>
      <Route path="/" element={<PatientsTab />} />
      <Route path="/consultations" element={<ConsultationsTab />} />
      <Route path="/visites-ouvertes" element={<VisitesOuvertesTab />} />
    </Routes>
  </ModuleLayout>
);

export default PatientsModule;
