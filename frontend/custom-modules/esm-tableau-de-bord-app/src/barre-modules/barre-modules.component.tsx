import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ConfigurableLink } from '@openmrs/esm-framework';
import {
  Box,
  Dashboard,
  Home,
  Medication,
  Pills,
  Report,
  UserMultiple,
} from '@carbon/react/icons';
import styles from './barre-modules.scss';

interface Module {
  label: string;
  /** Chemin après /openmrs/spa/ (avec éventuellement ?onglet=...) */
  to: string;
  icon: typeof Home;
}

// Files d'attente, Rendez-vous, Laboratoire et facturation sont déjà dans le menu
// de gauche de l'Accueil : on ne les répète pas ici.
const MODULES: Array<Module> = [
  { label: 'Accueil', to: 'home', icon: Home },
  { label: 'Patients', to: 'tableau-de-bord?onglet=patients', icon: UserMultiple },
  { label: 'Pharmacie', to: 'dispensing', icon: Medication },
  { label: 'Médicaments', to: 'tableau-de-bord?onglet=medicaments', icon: Pills },
  { label: 'Stock', to: 'stock-management', icon: Box },
  { label: 'Tableau de bord', to: 'tableau-de-bord', icon: Dashboard },
  { label: 'Rapports', to: 'reports', icon: Report },
];

function currentPath() {
  return window.location.pathname.replace(/^.*\/spa\//, '') + window.location.search;
}

/** Le module le plus précis qui correspond à l'adresse courante est mis en évidence */
function activeModule(path: string): string | undefined {
  return MODULES.filter((m) => path === m.to || path.startsWith(m.to.split('?')[0] + '/') || path.startsWith(m.to))
    .sort((a, b) => b.to.length - a.to.length)[0]?.to;
}

/** Barre des modules dans l'en-tête, comme dans Dolibarr : une icône et un libellé par module */
const BarreModules: React.FC = () => {
  const { t } = useTranslation();
  const [path, setPath] = useState(currentPath);

  useEffect(() => {
    const update = () => setPath(currentPath());
    window.addEventListener('single-spa:routing-event', update);
    window.addEventListener('popstate', update);
    return () => {
      window.removeEventListener('single-spa:routing-event', update);
      window.removeEventListener('popstate', update);
    };
  }, []);

  const active = activeModule(path);

  return (
    <nav className={styles.barre} aria-label={t('modules', 'Modules')}>
      {MODULES.map((m) => {
        const Icon = m.icon;
        return (
          <ConfigurableLink
            key={m.to}
            to={`\${openmrsSpaBase}/${m.to}`}
            className={`${styles.module} ${m.to === active ? styles.active : ''}`}
            title={m.label}>
            <Icon size={20} />
            <span className={styles.label}>{t(m.label, m.label)}</span>
          </ConfigurableLink>
        );
      })}
    </nav>
  );
};

export default BarreModules;
