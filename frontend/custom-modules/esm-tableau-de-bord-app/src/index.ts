/**
 * Point d'entrée du module Tableau de bord - Fondation Médicale FASSE.
 * Les données viennent des datasets SQL de grille/tableau_de_bord_datasets.sql,
 * évalués par l'API reportingrest d'OpenMRS.
 */
import { getAsyncLifecycle } from '@openmrs/esm-framework';

const moduleName = '@face/esm-tableau-de-bord-app';

const options = {
  featureName: 'tableau-de-bord',
  moduleName,
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const importTranslation = (require as any).context('../translations', false, /.json$/, 'lazy');

export function startupApp() {}

/** Tableau de bord : /openmrs/spa/tableau-de-bord */
export const root = getAsyncLifecycle(() => import('./root.component'), options);

/** Modules structurés comme « Gestion des Stocks » (menu à gauche, en-tête, contenu) */
export const patientsModule = getAsyncLifecycle(() => import('./modules/patients-module.component'), options);
export const medicamentsModule = getAsyncLifecycle(() => import('./modules/medicaments-module.component'), options);
export const ventesModule = getAsyncLifecycle(() => import('./modules/ventes-module.component'), options);

/** Barre des modules dans l'en-tête (top-nav-info-slot), à la manière de Dolibarr */
export const barreModules = getAsyncLifecycle(() => import('./barre-modules/barre-modules.component'), options);
