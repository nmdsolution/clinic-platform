import React, { useEffect, useRef, useState } from 'react';
import { HeaderGlobalAction, InlineLoading, TextArea, Button } from '@carbon/react';
import { ChatBot, Close, Send } from '@carbon/react/icons';
import { useSession } from '@openmrs/esm-framework';
import { DATASETS, fetchDataSet, formatFcfa, num, text } from '../api';
import { CONNAISSANCES, SUGGESTIONS } from './connaissances';
import styles from './assistant.scss';

interface Message {
  role: 'user' | 'model';
  text: string;
}

interface GeminiResponse {
  candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
  error?: { message?: string };
}

/** Chiffres agrégés du jour, sans aucun nom ni donnée de patient */
async function chiffresDuJour(): Promise<string> {
  try {
    const [indicateurs, medicaments] = await Promise.all([
      fetchDataSet(DATASETS.indicateurs),
      fetchDataSet(DATASETS.medicaments),
    ]);
    const k = indicateurs[0] ?? {};
    const suivis = medicaments.filter((m) => m.etat !== 'Non suivi en stock');
    const ruptures = suivis.filter((m) => m.etat === 'Rupture').length;
    return [
      `Nouveaux patients aujourd'hui : ${num(k.patients_jour)}`,
      `Visites ouvertes aujourd'hui : ${num(k.visites_jour)}`,
      `Visites non terminées (toutes dates) : ${num(k.visites_ouvertes)}`,
      `Factures aujourd'hui : ${num(k.factures_jour)}`,
      `Encaissé aujourd'hui : ${formatFcfa(k.encaisse_jour)}`,
      `Factures impayées : ${num(k.impayes_nb)}, reste à recouvrer : ${formatFcfa(k.impayes_montant)}`,
      `Examens de laboratoire en attente (7 jours) : ${num(k.examens_en_attente)}`,
      `Médicaments au catalogue : ${medicaments.length}, suivis en stock : ${suivis.length}, en rupture : ${ruptures}`,
    ].join('\n');
  } catch {
    return 'Chiffres du jour indisponibles (droits insuffisants ou connexion).';
  }
}

/** Mise en forme minimale de la réponse : gras **...** et retours à la ligne */
function MiseEnForme({ value }: { value: string }) {
  return (
    <>
      {value.split('\n').map((ligne, i) => (
        <p key={i} className={styles.ligne}>
          {ligne.split(/(\*\*[^*]+\*\*)/g).map((morceau, j) =>
            morceau.startsWith('**') && morceau.endsWith('**') ? (
              <strong key={j}>{morceau.slice(2, -2)}</strong>
            ) : (
              <React.Fragment key={j}>{morceau.replace(/^\s*[*-]\s+/, '• ')}</React.Fragment>
            ),
          )}
        </p>
      ))}
    </>
  );
}

/** Bouton « Assistant » de la barre du haut et son panneau de discussion */
const AssistantBouton: React.FC = () => {
  const session = useSession();
  const [ouvert, setOuvert] = useState(false);
  const [messages, setMessages] = useState<Array<Message>>([]);
  const [saisie, setSaisie] = useState('');
  const [envoi, setEnvoi] = useState(false);
  const [erreur, setErreur] = useState<string | null>(null);
  const finRef = useRef<HTMLDivElement>(null);

  useEffect(() => finRef.current?.scrollIntoView({ behavior: 'smooth' }), [messages, envoi]);

  const envoyer = async (question: string) => {
    const q = question.trim();
    if (!q || envoi) return;
    const historique: Array<Message> = [...messages, { role: 'user', text: q }];
    setMessages(historique);
    setSaisie('');
    setEnvoi(true);
    setErreur(null);
    try {
      const roles = (session?.user?.roles ?? []).map((r) => r.display).join(', ');
      const contexte = [
        CONNAISSANCES,
        '',
        `CONTEXTE ACTUEL (${new Date().toLocaleString('fr-FR')})`,
        `Écran ouvert : ${window.location.pathname.replace(/^.*\/spa\//, '') || 'accueil'}`,
        `Rôles de l'utilisateur : ${roles || 'inconnus'}`,
        await chiffresDuJour(),
      ].join('\n');

      // Sans réponse en 60 s, on abandonne avec un message clair (connexion lente, service saturé)
      const controller = new AbortController();
      const timer = window.setTimeout(() => controller.abort(), 60_000);
      const response = await fetch('/assistant-api/generate', {
        method: 'POST',
        signal: controller.signal,
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: contexte }] },
          // Les 12 derniers messages suffisent et allègent l'envoi sur connexion lente
          contents: historique.slice(-12).map((m) => ({ role: m.role, parts: [{ text: m.text }] })),
          generationConfig: { temperature: 0.3, maxOutputTokens: 2048 },
        }),
      });
      window.clearTimeout(timer);
      const data: GeminiResponse = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new Error(
          response.status === 401
            ? 'Session expirée : reconnectez-vous.'
            : response.status === 503 || response.status === 504
              ? 'Le service d’IA est saturé ou trop lent. Réessayez dans un instant.'
              : response.status === 429
              ? 'Trop de questions en peu de temps (limite de l’offre gratuite). Réessayez dans une minute.'
              : data.error?.message
                ? `Assistant indisponible : ${data.error.message}`
                : 'Assistant indisponible pour le moment.',
        );
      }
      const reponse = (data.candidates?.[0]?.content?.parts ?? []).map((p) => text(p.text ?? '')).join('').trim();
      setMessages([...historique, { role: 'model', text: reponse || 'Je n’ai pas de réponse. Reformulez la question.' }]);
    } catch (err) {
      setErreur(
        err instanceof DOMException && err.name === 'AbortError'
          ? 'Pas de réponse après 60 secondes. Vérifiez la connexion et réessayez.'
          : err instanceof Error
            ? err.message
            : 'Assistant indisponible pour le moment.',
      );
    } finally {
      setEnvoi(false);
    }
  };

  return (
    <>
      <HeaderGlobalAction
        aria-label="Assistant"
        isActive={ouvert}
        onClick={() => setOuvert((o) => !o)}
        className={styles.bouton}>
        <ChatBot size={20} />
      </HeaderGlobalAction>
      {ouvert && (
        <aside className={styles.panneau} aria-label="Assistant HGest">
          <header className={styles.entete}>
            <span className={styles.titre}>Assistant HGest</span>
            <button type="button" className={styles.fermer} onClick={() => setOuvert(false)} aria-label="Fermer">
              <Close size={20} />
            </button>
          </header>
          <div className={styles.messages}>
            {messages.length === 0 && (
              <div className={styles.accueil}>
                <p>Posez une question sur le logiciel, le parcours du patient ou un problème.</p>
                <p className={styles.avertissement}>
                  N’écrivez jamais le nom ou les informations d’un patient : les questions sont traitées par Google.
                </p>
                <div className={styles.suggestions}>
                  {SUGGESTIONS.map((s) => (
                    <button key={s} type="button" className={styles.suggestion} onClick={() => envoyer(s)}>
                      {s}
                    </button>
                  ))}
                </div>
              </div>
            )}
            {messages.map((m, i) => (
              <div key={i} className={m.role === 'user' ? styles.question : styles.reponse}>
                {m.role === 'user' ? m.text : <MiseEnForme value={m.text} />}
              </div>
            ))}
            {envoi && <InlineLoading description="L’assistant réfléchit..." />}
            {erreur && <p className={styles.erreur}>{erreur}</p>}
            <div ref={finRef} />
          </div>
          <form
            className={styles.saisie}
            onSubmit={(e) => {
              e.preventDefault();
              envoyer(saisie);
            }}>
            <TextArea
              id="assistant-question"
              labelText=""
              hideLabel
              rows={2}
              placeholder="Votre question..."
              value={saisie}
              onChange={(e) => setSaisie(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                  e.preventDefault();
                  envoyer(saisie);
                }
              }}
            />
            <Button type="submit" hasIconOnly renderIcon={Send} iconDescription="Envoyer" disabled={envoi || !saisie.trim()} />
          </form>
        </aside>
      )}
    </>
  );
};

export default AssistantBouton;
