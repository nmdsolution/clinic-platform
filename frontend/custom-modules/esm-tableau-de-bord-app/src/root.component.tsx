import React from 'react';
import { Dashboard } from '@carbon/react/icons';
import ModuleLayout from './layout/module-layout.component';
import ParcoursTab from './parcours/parcours-tab.component';

/** Tableau de bord : uniquement les chiffres du jour et le parcours patient */
const Root: React.FC = () => (
  <ModuleLayout base="tableau-de-bord" title="Tableau de bord" icon={Dashboard}>
    <ParcoursTab />
  </ModuleLayout>
);

export default Root;
