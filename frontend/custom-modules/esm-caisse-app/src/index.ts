/**
 * Point d'entrée du module Caisse & Facturation - Clinique FACE.
 * Voir services/caisse/ pour l'API Python que ce module consomme.
 */
import { getAsyncLifecycle, defineConfigSchema } from '@openmrs/esm-framework';
import { configSchema } from './config-schema';

const moduleName = '@face/esm-caisse-app';

const options = {
  featureName: 'caisse',
  moduleName,
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const importTranslation = (require as any).context('../translations', false, /.json$/, 'lazy');

export function startupApp() {
  defineConfigSchema(moduleName, configSchema);
}

/** Page complète, montée sur la route /openmrs/spa/caisse */
export const root = getAsyncLifecycle(() => import('./root.component'), options);

/** Lien dans le menu principal de navigation (app-menu-slot) */
export const caisseMenuLink = getAsyncLifecycle(() => import('./nav-link/caisse-link.component'), options);
