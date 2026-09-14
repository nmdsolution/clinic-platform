import React from 'react';
import { useTranslation } from 'react-i18next';
import { ConfigurableLink } from '@openmrs/esm-framework';

const CaisseMenuLink: React.FC = () => {
  const { t } = useTranslation();

  return (
    <ConfigurableLink to="${openmrsSpaBase}/caisse">{t('caisse', 'Caisse')}</ConfigurableLink>
  );
};

export default CaisseMenuLink;
