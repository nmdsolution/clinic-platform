import React from 'react';
import { type TFunction } from 'i18next';
import logoSrc from './logo-clinic.png';

const Logo: React.FC<{ t: TFunction }> = ({ t }) => (
  <img
    src={logoSrc}
    alt={t('openmrsLogo', 'Clinic FACE logo')}
    width="72"
    height="72"
    style={{ marginBottom: '12px', borderRadius: '16px' }}
  />
);

export default Logo;
