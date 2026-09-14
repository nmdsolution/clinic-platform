import React from 'react';
import { type TFunction } from 'i18next';

// Clinic FACE's own brand mark (two overlapping teal circles), matching the login mockup -
// deliberately not OpenMRS's own logo mark, used wherever the upstream module rendered <Logo>.
const Logo: React.FC<{ t: TFunction }> = ({ t }) => (
  <svg
    width="48"
    height="48"
    viewBox="0 0 22 22"
    role="img"
    aria-label={t('openmrsLogo', 'Clinic FACE logo')}
    style={{ marginBottom: '12px' }}
  >
    <circle cx="9" cy="11" r="7" fill="#005d5d" />
    <circle cx="15" cy="8" r="5" fill="#3fa39c" />
  </svg>
);

export default Logo;
