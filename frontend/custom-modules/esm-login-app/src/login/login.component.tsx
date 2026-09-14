import React, { useState, useRef, useEffect, useCallback, useMemo } from 'react';
import classnames from 'classnames';
import { useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { Checkbox, InlineLoading, InlineNotification, PasswordInput, TextInput } from '@carbon/react';
import {
  getCoreTranslation,
  interpolateUrl,
  openmrsFetch,
  refetchCurrentUser,
  sessionEndpoint,
  navigate as openmrsNavigate,
  useConfig,
  useConnectivity,
  useSession,
} from '@openmrs/esm-framework';
import { type ConfigSchema } from '../config-schema';
import illustration from './login-illustration.jpg';
import styles from './login.scss';

export interface LoginReferrer {
  referrer?: string;
}

// Renders a BCP-47 locale code in its own language (e.g. "fr" -> "Français",
// "en" -> "English"), same convention as OS-level language pickers - easier to
// recognize your language than a name translated into whichever locale is
// currently active.
function nativeLocaleName(code: string): string {
  try {
    const name = new Intl.DisplayNames([code], { type: 'language' }).of(code);
    return name ? name.charAt(0).toUpperCase() + name.slice(1) : code;
  } catch {
    return code;
  }
}

// Business logic (state, handlers, session/auth calls) below is unchanged from the upstream
// @openmrs/esm-login-app so authentication keeps working exactly as it does in stock OpenMRS 3.
// Only the rendered markup/styling is redone to match the "Clinic FACE" login mockup.

const Login: React.FC = () => {
  const {
    announcements = [],
    background = { image: '', color: '' },
    showPasswordOnSeparateScreen,
    provider: loginProvider,
    links: loginLinks,
  } = useConfig<ConfigSchema>();
  const isLoginEnabled = useConnectivity();
  const { t } = useTranslation();
  const { user, locale, allowedLocales = [] } = useSession();
  const [isChangingLocale, setIsChangingLocale] = useState(false);

  const handleLocaleChange = useCallback(
    async (evt: React.ChangeEvent<HTMLSelectElement>) => {
      const newLocale = evt.target.value;
      if (!newLocale || newLocale === locale) {
        return;
      }
      setIsChangingLocale(true);
      try {
        // The session (even pre-authentication) carries its own locale on the
        // server side; updating it here is what the login/help-menu pickers
        // do throughout O3. A full reload follows because the app shell only
        // fetches translation bundles for the active locale once, at boot.
        await openmrsFetch(sessionEndpoint, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: { locale: newLocale },
        });
        window.location.reload();
      } catch {
        setIsChangingLocale(false);
      }
    },
    [locale],
  );
  const location = useLocation() as unknown as Omit<Location, 'state'> & {
    state: LoginReferrer;
  };
  const navigate = useNavigate();

  const [errorMessage, setErrorMessage] = useState('');
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [showPasswordField, setShowPasswordField] = useState(false);
  const passwordInputRef = useRef<HTMLInputElement>(null);
  const usernameInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!user) {
      if (loginProvider.type === 'oauth2' || loginProvider.type === 'custom') {
        openmrsNavigate({ to: loginProvider.loginUrl });
      } else if (!username && location.pathname === '/login/confirm') {
        navigate('/login');
      }
    }
  }, [username, navigate, location, user, loginProvider]);

  useEffect(() => {
    if (showPasswordOnSeparateScreen) {
      if (showPasswordField) {
        if (!passwordInputRef.current?.value) {
          passwordInputRef.current?.focus();
        }
      } else {
        usernameInputRef.current?.focus();
      }
    }
  }, [showPasswordField, showPasswordOnSeparateScreen]);

  const continueLogin = useCallback(() => {
    const currentUsername = usernameInputRef.current?.value?.trim();
    if (currentUsername) {
      // If credentials were autofilled, input onChange might not have been called
      setUsername(currentUsername);
      setShowPasswordField(true);
    } else {
      usernameInputRef.current?.focus();
    }
  }, []);

  const changeUsername = useCallback((evt: React.ChangeEvent<HTMLInputElement>) => setUsername(evt.target.value), []);
  const changePassword = useCallback((evt: React.ChangeEvent<HTMLInputElement>) => setPassword(evt.target.value), []);

  const containerClassName = classnames(styles.page, {
    [styles.pageWithImage]: !!background.image,
    [styles.pageWithColor]: !background.image && !!background.color,
  });

  const containerStyle = useMemo<React.CSSProperties | undefined>(() => {
    if (background.image) {
      return { '--login-bg-image': `url(${interpolateUrl(background.image)})` } as React.CSSProperties;
    }
    if (background.color) {
      return { '--login-bg-color': background.color } as React.CSSProperties;
    }
    return undefined;
  }, [background]);

  const handleSubmit = useCallback(
    async (evt: React.FormEvent<HTMLFormElement>) => {
      evt.preventDefault();
      evt.stopPropagation();

      // If credentials were autofilled, input onChange might not have been called
      const currentUsername = usernameInputRef.current?.value?.trim() || username;
      const currentPassword = passwordInputRef.current?.value || password;

      if (showPasswordOnSeparateScreen && !showPasswordField) {
        continueLogin();
        return false;
      }

      if (!currentPassword || !currentPassword.trim()) {
        passwordInputRef.current?.focus();
        return false;
      }

      try {
        setIsLoggingIn(true);
        const sessionStore = await refetchCurrentUser(currentUsername, currentPassword);
        const session = sessionStore.session;
        const authenticated = sessionStore?.session?.authenticated;

        if (authenticated) {
          if (session.sessionLocation) {
            let to = loginLinks?.loginSuccess || '/home';
            if (location?.state?.referrer) {
              // Only accept relative paths; absolute or protocol-relative referrers
              // are silently ignored to prevent open-redirect attacks after login.
              if (location.state.referrer.startsWith('/')) {
                to = `\${openmrsSpaBase}${location.state.referrer}`;
              }
            }

            openmrsNavigate({ to });
          } else {
            navigate('/login/location');
          }
        } else {
          setErrorMessage(t('invalidCredentials', 'Invalid username or password'));
          setUsername('');
          setPassword('');
          if (showPasswordOnSeparateScreen) {
            setShowPasswordField(false);
          }
        }

        return true;
      } catch (error: unknown) {
        if (error instanceof Error) {
          setErrorMessage(error.message);
        } else {
          setErrorMessage(t('invalidCredentials', 'Invalid username or password'));
        }
        setUsername('');
        setPassword('');
        if (showPasswordOnSeparateScreen) {
          setShowPasswordField(false);
        }
      } finally {
        setIsLoggingIn(false);
      }
    },
    [
      username,
      password,
      navigate,
      showPasswordOnSeparateScreen,
      showPasswordField,
      loginLinks,
      location,
      t,
      continueLogin,
    ],
  );

  if (!loginProvider || loginProvider.type === 'basic') {
    return (
      <div className={containerClassName} style={containerStyle} data-testid="login-container">
        <div className={styles.bgBlobA} aria-hidden="true" />
        <div className={styles.bgBlobB} aria-hidden="true" />
        <div className={styles.bgRing} aria-hidden="true" />

        {announcements.length > 0 && (
          <div className={styles.announcements}>
            {announcements.map((announcement, i) => (
              <InlineNotification
                key={i}
                kind={announcement.kind}
                title={announcement.title ? t(announcement.title) : ''}
                subtitle={t(announcement.text)}
                lowContrast
                hideCloseButton
              />
            ))}
          </div>
        )}

        <div className={styles.card}>
          <div className={styles.illustrationPanel}>
            <div className={styles.illustrationBlobA} aria-hidden="true" />
            <div className={styles.illustrationBlobB} aria-hidden="true" />

            <div className={styles.illustrationText}>
              <div className={styles.illustrationHeading}>{t('loginGreeting', 'Bonjour !')}</div>
              <div className={styles.illustrationSubtitle}>
                {t(
                  'loginSubtitle',
                  "Entrez vos identifiants pour accéder à vos patients et vos files d'attente.",
                )}
              </div>
            </div>

            <div className={styles.illustrationImageWrap}>
              <div className={styles.illustrationCard}>
                <img
                  className={styles.illustrationImage}
                  src={illustration}
                  alt={t('loginIllustrationAlt', 'Soignant de la Clinique FACE')}
                />
              </div>
            </div>
          </div>

          <div className={styles.formPanel}>
            <div className={styles.localeRow}>
              <span className={styles.localePill}>
                <select
                  className={styles.localeSelect}
                  value={locale}
                  onChange={handleLocaleChange}
                  disabled={isChangingLocale}
                  aria-label={t('changeLanguage', 'Changer de langue')}
                >
                  {(allowedLocales.length ? allowedLocales : [locale]).filter(Boolean).map((code) => (
                    <option key={code} value={code}>
                      {nativeLocaleName(code)}
                    </option>
                  ))}
                </select>
                <svg width="12" height="12" viewBox="0 0 12 12" fill="none" aria-hidden="true">
                  <path
                    d="M2.5 4.5L6 8L9.5 4.5"
                    stroke="#525252"
                    strokeWidth="1.4"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </svg>
              </span>
            </div>

            <div className={styles.formBody}>
              <div className={styles.brandRow}>
                <span className={styles.brandIcon} aria-hidden="true">
                  <svg width="21" height="21" viewBox="0 0 22 22">
                    <path
                      d="M11 19.2C6.2 16.2 3 13.4 3 9.6A4.6 4.6 0 0 1 11 6.5 4.6 4.6 0 0 1 19 9.6c0 3.8-3.2 6.6-8 9.6Z"
                      fill="#ffffff"
                    />
                    <path
                      d="M4.6 11.4h3.1l1.5-2.6 2 5 1.6-3.1h4.6"
                      stroke="#005d5d"
                      strokeWidth="1.5"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      fill="none"
                    />
                  </svg>
                </span>
                <span className={styles.brandWordmark}>{t('appName', 'Clinic FACE')}</span>
              </div>

              {errorMessage && (
                <div className={styles.errorMessage}>
                  <InlineNotification
                    kind="error"
                    subtitle={t(errorMessage)}
                    title={getCoreTranslation('error')}
                    onClick={() => setErrorMessage('')}
                  />
                </div>
              )}

              <form onSubmit={handleSubmit}>
                <label className={styles.fieldLabel} htmlFor="username">
                  {t('username', "Nom d'utilisateur")}
                </label>
                <div className={styles.field}>
                  <svg
                    className={styles.fieldIcon}
                    width="16"
                    height="16"
                    viewBox="0 0 16 16"
                    fill="none"
                    aria-hidden="true"
                  >
                    <circle cx="8" cy="5.5" r="2.8" stroke="currentColor" strokeWidth="1.3" />
                    <path
                      d="M2.8 13.6c.7-2.6 2.7-4 5.2-4s4.5 1.4 5.2 4"
                      stroke="currentColor"
                      strokeWidth="1.3"
                      strokeLinecap="round"
                    />
                  </svg>
                  <TextInput
                    id="username"
                    type="text"
                    name="username"
                    autoComplete="username"
                    labelText={t('username', "Nom d'utilisateur")}
                    hideLabel
                    value={username}
                    onChange={changeUsername}
                    ref={usernameInputRef}
                    required
                    autoFocus
                  />
                </div>

                {showPasswordOnSeparateScreen ? (
                  <>
                    <div className={showPasswordField ? undefined : styles.hiddenPasswordField}>
                      <label className={styles.fieldLabel} htmlFor="password">
                        {t('password', 'Mot de passe')}
                      </label>
                      <div className={styles.field}>
                        <svg
                          className={styles.fieldIcon}
                          width="16"
                          height="16"
                          viewBox="0 0 16 16"
                          fill="none"
                          aria-hidden="true"
                        >
                          <rect x="3" y="7" width="10" height="6.5" rx="1.4" stroke="currentColor" strokeWidth="1.3" />
                          <path d="M5.5 7V5.2a2.5 2.5 0 0 1 5 0V7" stroke="currentColor" strokeWidth="1.3" />
                        </svg>
                        <PasswordInput
                          id="password"
                          labelText={t('password', 'Mot de passe')}
                          hideLabel
                          name="password"
                          autoComplete="current-password"
                          onChange={changePassword}
                          ref={passwordInputRef}
                          required
                          value={password}
                          showPasswordLabel={t('showPassword', 'Afficher le mot de passe')}
                          invalidText={t('validValueRequired', 'Une valeur valide est requise')}
                          aria-hidden={!showPasswordField}
                          tabIndex={showPasswordField ? 0 : -1}
                        />
                      </div>
                    </div>

                    {showPasswordField ? (
                      <>
                        <div className={styles.rowBetween}>
                          <Checkbox id="remember-me" labelText={t('rememberMe', 'Rester connecté')} defaultChecked />
                          <a href="#" className={styles.forgotLink} onClick={(evt) => evt.preventDefault()}>
                            {t('forgotPassword', 'Mot de passe oublié ?')}
                          </a>
                        </div>
                        <button type="submit" className={styles.btnPrimary} disabled={!isLoginEnabled || isLoggingIn}>
                          {isLoggingIn ? (
                            <InlineLoading
                              className={styles.loader}
                              description={t('loggingIn', 'Connexion en cours') + '...'}
                            />
                          ) : (
                            t('login', 'Se connecter')
                          )}
                        </button>
                      </>
                    ) : (
                      <button
                        type="submit"
                        className={styles.btnPrimary}
                        onClick={(evt) => {
                          evt.preventDefault();
                          continueLogin();
                        }}
                        disabled={!isLoginEnabled}
                      >
                        {t('continue', 'Continuer')}
                      </button>
                    )}
                  </>
                ) : (
                  <>
                    <label className={styles.fieldLabel} htmlFor="password">
                      {t('password', 'Mot de passe')}
                    </label>
                    <div className={styles.field}>
                      <svg
                        className={styles.fieldIcon}
                        width="16"
                        height="16"
                        viewBox="0 0 16 16"
                        fill="none"
                        aria-hidden="true"
                      >
                        <rect x="3" y="7" width="10" height="6.5" rx="1.4" stroke="currentColor" strokeWidth="1.3" />
                        <path d="M5.5 7V5.2a2.5 2.5 0 0 1 5 0V7" stroke="currentColor" strokeWidth="1.3" />
                      </svg>
                      <PasswordInput
                        id="password"
                        labelText={t('password', 'Mot de passe')}
                        hideLabel
                        name="password"
                        autoComplete="current-password"
                        onChange={changePassword}
                        ref={passwordInputRef}
                        required
                        value={password}
                        showPasswordLabel={t('showPassword', 'Afficher le mot de passe')}
                        invalidText={t('validValueRequired', 'Une valeur valide est requise')}
                      />
                    </div>

                    <div className={styles.rowBetween}>
                      <Checkbox id="remember-me" labelText={t('rememberMe', 'Rester connecté')} defaultChecked />
                      <a href="#" className={styles.forgotLink} onClick={(evt) => evt.preventDefault()}>
                        {t('forgotPassword', 'Mot de passe oublié ?')}
                      </a>
                    </div>

                    <button type="submit" className={styles.btnPrimary} disabled={!isLoginEnabled || isLoggingIn}>
                      {isLoggingIn ? (
                        <InlineLoading
                          className={styles.loader}
                          description={t('loggingIn', 'Connexion en cours') + '...'}
                        />
                      ) : (
                        t('login', 'Se connecter')
                      )}
                    </button>
                  </>
                )}

                {/* SSO n'est pas configuré pour cette instance (loginProvider.type reste 'basic') :
                    ce bouton reflète le mockup mais n'a pas de fournisseur à déclencher tant
                    qu'aucun IdP externe n'est branché. */}
                <div className={styles.divider}>
                  <div className={styles.dividerLine} />
                  <span className={styles.dividerText}>{t('or', 'ou')}</span>
                  <div className={styles.dividerLine} />
                </div>
                <button type="button" className={styles.btnSecondary} disabled title={t('ssoNotConfigured', "Authentification unique non configurée")}>
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none" aria-hidden="true">
                    <rect x="2.2" y="2.2" width="11.6" height="11.6" rx="2" stroke="#161616" strokeWidth="1.3" />
                    <path d="M5.5 8h5M8 5.5v5" stroke="#161616" strokeWidth="1.3" strokeLinecap="round" />
                  </svg>
                  {t('ssoLogin', 'Authentification unique (SSO)')}
                </button>

                {window.applicationVersion && <div className={styles.versionText}>{window.applicationVersion}</div>}
              </form>
            </div>

            <div className={styles.footerText}>
              {t('loginFooterText', 'Clinic FACE · OpenMRS 3 Reference Application · v3.7.1')}
            </div>
          </div>
        </div>
      </div>
    );
  }
  return null;
};

export default Login;
