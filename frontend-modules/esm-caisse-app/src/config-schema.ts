import { Type } from '@openmrs/esm-framework';

/**
 * Schéma de configuration du module Caisse.
 * Modifiable depuis l'administration OpenMRS (Implementer Tools > Configure)
 * sans avoir à reconstruire le module.
 */
export const configSchema = {
  apiBasePath: {
    _type: Type.String,
    _description: "Chemin de base de l'API du module Caisse (relatif à l'origine du site).",
    _default: '/caisse',
  },
  currency: {
    _type: Type.String,
    _description: 'Devise affichée dans les montants.',
    _default: 'FCFA',
  },
};

export interface CaisseConfig {
  apiBasePath: string;
  currency: string;
}
