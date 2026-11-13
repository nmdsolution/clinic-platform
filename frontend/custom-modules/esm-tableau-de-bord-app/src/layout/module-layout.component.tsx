import React, { useEffect, useState } from 'react';
import { BrowserRouter, NavLink } from 'react-router-dom';
import { ConfigurableLink, useSession } from '@openmrs/esm-framework';
import { Home } from '@carbon/react/icons';
import styles from './module-layout.scss';

export interface Section {
  /** Sous-chemin dans le module ('' pour la page d'entrée) */
  path: string;
  label: string;
  /** Écran d'un autre module (chemin après /openmrs/spa/) : le lien y mène directement */
  externe?: string;
}

interface Props {
  /** Chemin du module après /openmrs/spa/ (ex. « patients ») */
  base: string;
  title: string;
  icon: typeof Home;
  sections?: Array<Section>;
  children: React.ReactNode;
}

const heure = new Intl.DateTimeFormat('fr-FR', { hour: '2-digit', minute: '2-digit' });

/**
 * Gabarit commun des modules FASSE, calqué sur « Gestion des Stocks » :
 * menu du module à gauche, en-tête (icône, titre, lieu, date) et contenu.
 */
const ModuleLayout: React.FC<Props> = ({ base, title, icon: Icon, sections = [], children }) => {
  const session = useSession();
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <BrowserRouter basename={`${window.getOpenmrsSpaBase()}${base}`}>
      <div className={styles.page}>
        {sections.length > 0 && (
          <nav className={styles.sidebar} aria-label={title}>
            {sections.map((s) =>
              s.externe ? (
                <ConfigurableLink key={s.label} to={`\${openmrsSpaBase}${s.externe}`} className={styles.navItem}>
                  {s.label}
                </ConfigurableLink>
              ) : (
              <NavLink
                key={s.path}
                to={`/${s.path}`}
                end
                className={({ isActive }) => `${styles.navItem} ${isActive ? styles.navActive : ''}`}>
                {s.label}
              </NavLink>
              ),
            )}
          </nav>
        )}
        <main className={styles.main}>
          <header className={styles.header}>
            <div className={styles.headerIcon}>
              <Icon size={32} />
            </div>
            <div className={styles.headerText}>
              <span className={styles.headerKicker}>Clinique</span>
              <h1 className={styles.headerTitle}>{title}</h1>
            </div>
            <div className={styles.headerMeta}>
              {session?.sessionLocation?.display && <span>{session.sessionLocation.display}</span>}
              <span>Aujourd'hui, {heure.format(now)}</span>
            </div>
          </header>
          <div className={styles.content}>{children}</div>
        </main>
      </div>
    </BrowserRouter>
  );
};

export default ModuleLayout;
