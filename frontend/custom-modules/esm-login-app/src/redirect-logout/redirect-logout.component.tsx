import { useEffect } from 'react';
import { navigate, setUserLanguage, useConfig, useConnectivity, useSession } from '@openmrs/esm-framework';
import { type ConfigSchema } from '../config-schema';
import { performLogout } from './logout.resource';

// The original OpenMRS module also calls an internal `clearHistory()` helper here (scrubs
// sensitive routes from browser history on logout). It isn't part of the public
// `@openmrs/esm-framework` import map entry, so this fork can't reach it safely; logout still
// works correctly without it.

const RedirectLogout: React.FC = () => {
  const config = useConfig<ConfigSchema>();
  const isLoginEnabled = useConnectivity();
  const session = useSession();

  useEffect(() => {
    if (!session.authenticated || !isLoginEnabled) {
      if (config.provider.type === 'custom') {
        navigate({ to: config.provider.loginUrl });
      } else if (config.provider.type === 'oauth2') {
        // do nothing, do not redirect
      } else {
        navigate({ to: '${openmrsSpaBase}/login' });
      }
    } else {
      performLogout()
        .then(() => {
          const defaultLanguage = document.documentElement.getAttribute('data-default-lang');

          setUserLanguage({
            locale: defaultLanguage,
            authenticated: false,
            sessionId: '',
          });

          if (config.provider.type === 'custom') {
            navigate({ to: config.provider.loginUrl });
          } else if (config.provider.type === 'oauth2') {
            // do nothing, do not redirect
          } else {
            navigate({ to: '${openmrsSpaBase}/login' });
          }
        })
        .catch((error) => {
          console.error('Logout failed:', error);
        });
    }
  }, [config, isLoginEnabled, session]);

  return null;
};

export default RedirectLogout;
