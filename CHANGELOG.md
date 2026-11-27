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
- Médicaments : unités, stock et prix (`grille/medicaments_unites_prix.sql`, appliqué le 26/11/2026 après sauvegarde) :
  - Chaque médicament relié au stock a une vraie forme du jeu des unités de dosage (Comprimé, Ampoule, Fiole, Flacon,
    Poche, Sachet, Ovule). Ceftriaxone avait « Intraveineuse » (une voie) : le serveur refusait l'ordonnance
    (`DrugOrder.error.notAmongAllowedConcepts`). Flacon, Poche, Sachet et le nouveau concept Ovule sont ajoutés au jeu.
  - Trois articles de stock étaient reliés au mauvais médicament (Oméprazole inj, Érythromycine cp, Nystatine ovule) :
    nouveaux médicaments créés et reliés.
  - L'unité de stock « Piece » est remplacée par la forme du médicament (facteur 1, quantités inchangées).
  - Prix de vente sur les 47 articles de stock (repris des services de même nom) : une ordonnance crée maintenant une
    ligne au bon prix au lieu de 0 FCFA.
  - `validateBatch: false` pour `esm-dispensing-app` : 47 lots sur 49 n'ont pas de date de péremption, ils étaient
    tous écartés à la délivrance. À réactiver quand la pharmacie aura saisi les vraies dates.
- Tarifs à l'ouverture de visite (`grille/tarifs_consultation_modes.sql`, appliqué le 26/11/2026 après sauvegarde) :
  le formulaire de visite n'affiche que les services ayant un prix lié au mode de paiement choisi. Les actes de
  consultation (services 5 à 19 et 112) ont maintenant un prix Espèces, Orange Money et MTN Mobile Money (même montant) ;
  « Cash » renommé « Espèces », prix PayPal retiré. Attributs de visite et types de commande renommés en français ;
  le dataset des indicateurs (`…b008`) repère désormais les examens par l’UUID du type de commande, et non plus par son nom.
- Traductions (`esm-tableau-de-bord-app` 1.5.9) : les ~570 textes français des modules officiels passent de
  `surcharges-fr.ts` (jamais appliqués : l'événement i18next « added » ne se déclenche pas) à
  `frontend/traductions-fr.json`, fusionné dans `config-core_demo.json` comme « Translation overrides » à la
  construction de l'image. Ajouts : statuts de facture (PAID, POSTED, PENDING), Finaliser la facture, Demander une remise,
  N° de facture, Traitements à venir, Retour à l'ordonnance, Calculée automatiquement, Homme/Femme ;
  unité de durée « Jours » (`daysDurationUnit`).
- Page facture (`styles-globaux.ts`) : la barre d'actions et le bloc des totaux/paiement passent à la ligne au lieu
  d'être coupés sur un écran étroit (1071 px).
- Pagination REST et PayPal (`grille/pagination_paypal.sql`, appliqué le 27/11/2026 après sauvegarde) :
  `webservices.rest.maxResultsDefault` et `maxResultsAbsolute` passent à 200 (réenregistrés par l'API pour vider le
  cache). Le formulaire de visite ne lit qu'une page de services : avec 116 services, la consultation
  ophtalmologique n'apparaissait pas. Mode de paiement PayPal retiré.
- Nettoyage du test du 26/11/2026 (patient TEST HGEST, 1000ECT), appliqué le 27/11/2026 après sauvegarde
  `avant_nettoyage_test_20261127_1005` : factures 0021-6 à 0024-0, leurs lignes et le paiement de 2 000 FCFA
  annulés (`grille/nettoyage_test_hgest.sql`) ; ordonnances, délivrance, consultations, visite et patient annulés
  par l'API. Rien n'est supprimé. Les rapports de facturation et le tableau de bord ignorent les données annulées.
  **Reste à faire :** remettre en stock les 3 Fioles de Ceftriaxone (lot INIT-2026-09). L'ajustement est impossible
  tant que le concept des motifs d'ajustement (`stockmanagement.stockAdjustmentReasonCodeConceptId`,
  `3bbfaa44-…`) n'existe pas.

### Décisions
- Facturation : on conserve le module `billing` d'OpenMRS (+ `stockmanagement`) ; le microservice `caisse` n'est pas étendu.
