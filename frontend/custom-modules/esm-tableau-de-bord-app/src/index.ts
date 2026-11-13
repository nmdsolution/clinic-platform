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

/** Page complète, montée sur la route /openmrs/spa/tableau-de-bord */
export const root = getAsyncLifecycle(() => import('./root.component'), options);

/** Lien dans le menu des applications (app-menu-slot) */
export const menuLink = getAsyncLifecycle(() => import('./menu-link.component'), options);

/** Barre des modules dans l'en-tête (top-nav-info-slot), à la manière de Dolibarr */
export const barreModules = getAsyncLifecycle(() => import('./barre-modules/barre-modules.component'), options);
