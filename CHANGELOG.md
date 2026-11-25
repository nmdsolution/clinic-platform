# Journal des changements HGest

## Non publié — Phase 0 (branche `phase0/traduction-fr`)

### Ajouté
- `ARCHITECTURE.md` : cartographie du dépôt et du serveur de production.
- Lot 1 — Traduction française :
  - `esm-tableau-de-bord-app` 1.5.5 : surcharges i18n (`src/traductions/surcharges-fr.ts`, ~550 textes) pour les modules officiels
    dont le français est absent ou incomplet (facturation, tâches, files d'attente, stock, hospitalisation, rendez-vous, pharmacie, labo…).
    Appliquées au démarrage via `window.i18next`, sans modifier les modules officiels.
  - `grille/traduction_fr_donnees.sql` : renommage idempotent (par UUID) des services de RDV, files, points de caisse,
    modes de paiement, programmes et du lieu « Unknown Location ». **À appliquer manuellement après sauvegarde.**

### Décisions
- Facturation : on conserve le module `billing` d'OpenMRS (+ `stockmanagement`) ; le microservice `caisse` n'est pas étendu.
