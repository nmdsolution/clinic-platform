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
- Lot 4 (facturation d'un patient inconnu) : reporté à la demande du client.
- Lot 5 — Tableau de bord (`esm-tableau-de-bord-app` 1.5.7) :
  - Étape Pharmacie : ne dit plus que « le stock diminue automatiquement » (la dispensation n'est pas reliée au stock,
    0 dispensation enregistrée) ; indique d'enregistrer la sortie dans Médicaments.
  - Étape Consultation : « Voir les patients présents » ouvre Patients › Visites ouvertes au lieu de l'accueil générique.
    Les autres liens (inscription, facturation, files d'attente, laboratoire, dispensation, impayés) ont été vérifiés
    contre `routes.registry.json` de production.
  - Assistant IA : base de connaissances alignée (stock non décompté, clôture automatique des visites).
- Pharmacie reliée au stock (`esm-tableau-de-bord-app` 1.5.8) : `enableStockDispense: true` pour `esm-dispensing-app`
  dans `config-core_demo.json`. À la délivrance, le pharmacien choisit le lot et le stock de la Pharmacie principale
  est déduit (`stockmanagement/dispenserequest`). Vérifié : l'inventaire est trouvé depuis le lieu de connexion
  « Fondation Médicale Fasse ». Textes du parcours et de l'assistant mis à jour en conséquence.

### Décisions
- Facturation : on conserve le module `billing` d'OpenMRS (+ `stockmanagement`) ; le microservice `caisse` n'est pas étendu.
