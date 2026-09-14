import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Button, TextInput, InlineNotification, Form, Stack } from '@carbon/react';
import { CaisseApi, CaisseApiError, type CaisseUser } from '../caisse-api';
import styles from './login-form.scss';

interface LoginFormProps {
  api: CaisseApi;
  onLoggedIn: (user: CaisseUser) => void;
}

const LoginForm: React.FC<LoginFormProps> = ({ api, onLoggedIn }) => {
  const { t } = useTranslation();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setError(null);
    setBusy(true);
    try {
      const user = await api.login(username, password);
      onLoggedIn(user);
    } catch (err) {
      setError(err instanceof CaisseApiError ? err.message : t('loginError', 'Connexion impossible'));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className={styles.loginContainer}>
      <Form onSubmit={handleSubmit} className={styles.loginForm}>
        <Stack gap={5}>
          <h4>{t('caisseLoginTitle', 'Connexion — Module Caisse')}</h4>
          {error && <InlineNotification kind="error" title={error} lowContrast hideCloseButton />}
          <TextInput
            id="caisse-username"
            labelText={t('username', 'Identifiant')}
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
          />
          <TextInput
            id="caisse-password"
            type="password"
            labelText={t('password', 'Mot de passe')}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
          <Button type="submit" disabled={busy || !username || !password}>
            {busy ? t('connecting', 'Connexion en cours...') : t('login', 'Se connecter')}
          </Button>
        </Stack>
      </Form>
    </div>
  );
};

export default LoginForm;
