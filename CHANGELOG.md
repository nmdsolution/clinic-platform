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
- Lot 2 — Métadonnées patient (Cameroun) : `grille/metadonnees_patient.sql` (SSN/Race/… retirés, CNI, profession,
  personne à prévenir, libellés d'adresse Quartier/Ville/Région) et section « Personne à prévenir » dans
  `config-core_demo.json`. Le payeur est reporté à la Phase 1 (liste liée aux tarifs).
- Lot 3 — Clôture des visites :
  - `grille/visites_cloture.sql` : type de visite « Hospitalisation » (jamais clôturé automatiquement) et
    régularisation unique des visites ouvertes depuis plus de 24 h (appliqué le 25/11/2026 : 59 visites clôturées,
    visite 294 passée en Hospitalisation).
  - Tâche OpenMRS « Auto Close Visits Task » activée chaque jour à 23:59:59 heure du Cameroun (22:59:59 UTC), pour
    les types Consultation au centre, Consultation externe et Visite à domicile (`visits.autoCloseVisitType`).
  - `esm-tableau-de-bord-app` 1.5.6 : onglet **Patients › Visites ouvertes** (dataset `…b017`) avec durée,
    impayés du patient et bouton « Clôturer » ; les hospitalisations se clôturent à la sortie depuis le dossier.
  - Les fichiers `*.test.ts(x)` sont exclus du `tsconfig` du module en attendant l'installation de Jest (lot 6).

### Décisions
- Facturation : on conserve le module `billing` d'OpenMRS (+ `stockmanagement`) ; le microservice `caisse` n'est pas étendu.
