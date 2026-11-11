import React from 'react';
import { useTranslation } from 'react-i18next';
import { ConfigurableLink } from '@openmrs/esm-framework';

const MenuLink: React.FC = () => {
  const { t } = useTranslation();

  return (
    <ConfigurableLink to="${openmrsSpaBase}/tableau-de-bord">{t('tableauDeBord', 'Tableau de bord')}</ConfigurableLink>
  );
};

export default MenuLink;
