# TODO — Modules du protocole Clinique FACE

Suivi de l'implémentation des modules décrits dans
`Protocole_logiciel_Clinique_FACE.pdf`. Chaque ligne renvoie à la section du
protocole (§) pour retrouver le détail fonctionnel attendu.

Légende : ✅ fait · 🚧 en cours / partiel · ⬜ pas commencé

## ⚠️ À trancher : redondance service `backend/services/caisse` vs modules natifs

Découverte importante du 2026-09-18 : en testant les modules OpenMRS natifs
cette session, on a confirmé que la plupart des fonctions du service Python
`caisse` ont un **équivalent natif déjà fonctionnel** dans la distro :

| § | Fonction | Service `caisse` (Python) | Natif OpenMRS | Statut natif |
|---|---|---|---|---|
| §6 | Salle d'attente | `routers/queues.py` | `queue-omod` ("Files d'attente") | ✅ testé fonctionnel dès le début de la session |
| §19-20 | Rendez-vous | `routers/appointments.py` | `appointments-omod` ("Rendez-vous") | ✅ présent dans la nav, pas encore testé en détail |
| §17-18 | Facturation/Caisse | `routers/invoices.py`, `routers/payments.py`, `routers/cash_sessions.py` | `billing-omod` ("En cours de facturation") | ✅ **testé de bout en bout** (2026-09-18) : catalogue de services avec prix, facture, finalisation, paiement (Cash + **mtn money + orange money déjà présents**), reçu imprimable, remise, remboursement, et **les actes déjà réalisés (consultation, prescription, examen labo) apparaissent automatiquement à facturer — pas de double saisie**, conforme au principe §34. Bémol : liste des factures filtrable par date (piste d'audit existe), mais **pas de total automatique / rapprochement "théorique vs encaissé"** prêt à l'emploi (les propriétés `billing.reports.dailyShiftSummary` etc. n'ont pas d'ID de rapport Jasper configuré) — à construire via Report Builder (Data Set Definition sommant les paiements par jour/moyen de paiement), dans la continuité du travail §31 |
| §4 | Recherche patient | `routers/patients.py` | Recherche patient native OpenMRS | Native évidemment disponible |
| §2 | Comptes/rôles | `routers/auth.py` | Comptes/rôles OpenMRS natifs | Native évidemment disponible |

**Ce qui reste probablement légitime à garder en Python**, car sans
équivalent natif : §3/§27 tableau de bord/financier consolidé (peut aussi se
faire via Report Builder, cf. §31 plus bas), §28 vue de synthèse promotrice,
§29 journal des modifications côté caisse spécifiquement — et bien sûr tout
ce qui est listé en "Pas commencé" (RH, salaires, dépenses, kiné, courbes
biologiques, courriers).

**Décision à prendre** : soit on migre progressivement le frontend/les
patients réels vers les modules natifs (Billing, Queue, Appointments) et on
retire le service `caisse` en conséquence (à faire prudemment, migration
réelle, pas une simple suppression de code), soit on garde les deux en
parallèle un moment. Rien n'a été supprimé ni migré à ce stade — cette
section documente juste la découverte pour décision ultérieure.

## Historique (fait / en cours dans le service `backend/services/caisse`, statut avant réévaluation ci-dessus)

- ✅ **§2 Identification des utilisateurs** — comptes, rôles (ADMIN,
  PROMOTRICE, DAF, CAISSIER, SECRETAIRE), login (`routers/auth.py`)
- ✅ **§3 Tableau de bord général (partiel)** — `GET /reports/daily-summary`
- ✅ **§4 Accueil du patient (recherche uniquement)** — `routers/patients.py`
  recherche via l'API OpenMRS ; création de fiche patient encore à faire
  côté OpenMRS/frontend
- ✅ **§6 Salle d'attente virtuelle** — `routers/queues.py` (statuts, prise
  en charge)
- ✅ **§17 Facturation** — `routers/invoices.py`
- ✅ **§18 Module Caisse** — `routers/payments.py`, `routers/cash_sessions.py`
- ✅ **§19-20 Rendez-vous et agenda** — `routers/appointments.py`
- 🚧 **§27 Tableau de bord financier** — seul le résumé quotidien existe,
  pas encore de recettes/dépenses par période choisie
- ✅ **§29 Journal des modifications** — table `AuditLog`, tracé sur les
  actions sensibles (facture, paiement, ouverture/fermeture caisse)
- 🚧 **§28 Supervision à distance** — les rôles ADMIN/PROMOTRICE existent et
  les endpoints sont accessibles à distance, mais aucune vue de synthèse
  dédiée à la promotrice n'est encore construite

## Couvert nativement par OpenMRS (à configurer, pas à coder)

Confirmé via le menu Administration de l'app OpenMRS déjà déployée (modules
Legacy admin + O3) :

- ✅ **§7-8 Dossier médical électronique / Consultation médicale** —
  configuré via Initializer dans `backend/distro/configuration/` :
  - `encountertypes/encountertypes.csv` : type d'encounter
    "Consultation médicale"
  - `concepts/consultation_concepts.csv` : 20 nouveaux concepts (motif,
    anamnèse, examen clinique par système, glycémie capillaire,
    périmètre abdominal, douleur EVA, conduite à tenir, date de
    contrôle) — l'IMC/TA/FC/temp/SpO2/FR/poids/taille restent couverts
    par le widget natif `esm-patient-vitals-app` déjà installé (aucune
    config supplémentaire nécessaire)
  - `ampathforms/consultation_medicale.json` : formulaire clinique O3
    correspondant, avec les 3 pages du protocole (motif/anamnèse,
    examen clinique + constantes complémentaires, conduite à tenir)
  - Le diagnostic codé (§8 "Diagnostic") n'est **pas** dupliqué ici :
    utiliser le widget natif "Notes de visite / Diagnostics" du dossier
    patient (déjà fourni par O3), qui code proprement via CIEL/ICD-10
    plutôt qu'un champ texte libre
  - ✅ Testé sur l'instance déployée (2026-09-14) : le formulaire
    "Consultation médicale" apparaît dans "Manage Forms", publié

⚠️ **Piège opérationnel à connaître pour tout futur changement dans
`backend/distro/configuration/`** : le service `backend` monte un volume
Docker nommé persistant (`openmrs-data:/openmrs/data`, voir
`docker-compose.yml`). L'image ne resynchronise PAS automatiquement son
`openmrs_config` embarqué vers `/openmrs/data/configuration` sur un
volume déjà initialisé — seul un premier démarrage sur volume vide le
fait. Résultat : un nouveau/modifié fichier Initializer déployé via CI
n'est pas pris en compte tant qu'il n'est pas copié manuellement dans le
volume vivant. Contournement utilisé le 2026-09-14 :
```bash
cd /opt/clinic-platform
BACKEND=$(docker ps -qf "name=backend")
docker exec $BACKEND mkdir -p /openmrs/data/configuration/<domaine>
docker cp backend/distro/configuration/<domaine>/<fichier> $BACKEND:/openmrs/data/configuration/<domaine>/<fichier>
docker restart $BACKEND
```
À corriger durablement (TODO) : faire en sorte que le déploiement
resynchronise `backend/distro/configuration/` vers le volume à chaque
déploiement (étape dans le workflow CI, ou script d'entrée custom),
sinon ce geste manuel sera nécessaire à chaque changement de
configuration Initializer.
- ✅ **§9 Prescription médicamenteuse (catalogue de démo)** — configuré
  via Initializer :
  - `concepts/pharmacy_demo_concepts.csv` : 5 formes galéniques
    (comprimé, sirop, injectable, sachet, suspension buvable) + 11
    molécules (Amoxicilline, Paracétamol, Paracétamol pédiatrique,
    Ibuprofène, Artéméther/Luméfantrine, Métronidazole, Ciprofloxacine,
    Oméprazole, SRO, Fer + Acide folique, Diclofénac)
  - `drugs/pharmacy_demo_drugs.csv` : 11 présentations de médicaments
    prescriptibles (nom, forme, dosage) — catalogue **de démonstration**,
    à remplacer par le vrai formulaire de la pharmacie avant mise en
    production réelle
  - ✅ Testé sur l'instance déployée (2026-09-16) : "Amoxicilline 1g
    comprimé (clinique fasse)" apparaît bien dans la recherche de
    médicaments lors de la prescription, aux côtés du catalogue déjà
    présent (Amoxicillin 250mg/500mg, Augmentin, Bactoclav...)
  - ⚠️ Les prix (achat/vente) ne sont pas dans ce catalogue — à ajouter
    séparément (Concept Drug ne porte pas de prix ; ça se gère plutôt
    via "Gérer les services facturables" / le service caisse)
- ✅ **§10 Module Pharmacie (stock)** — "Gérer le Stock" / "Gestion des
  Stocks" (module Stock Management), **non couvert par Initializer**
  (pas de domaine dédié) — géré directement dans l'UI, données
  d'exploitation non versionnables
  - ✅ Les 11 articles du catalogue de démo (§9) ont été créés dans
    "Gestion des Stocks" (2026-09-16), via un import CSV positionnel
    (16 colonnes : DRUG_ID, DISPENSING_UNIT/PUOM = concept_id de la
    forme galénique, PACK_SIZE=1, fournisseur "Fasse store", seuil de
    réapprovisionnement 20) — le fichier `stock_items_import.csv` est
    à la racine du repo (non commité, c'est un utilitaire ponctuel, pas
    une config versionnée)
  - ✅ **Résolu (2026-09-17) : opérations de stock (Receipt, Opening
    Stock...) fonctionnelles**, après un parcours de débogage en
    plusieurs étapes sur `openmrs-module-stockmanagement` 3.0.0 /
    `esm-stock-management-app` 3.2.1 :
    1. **Bug "permanent" NPE** sur la création d'un "User role scope" :
       `NullPointerException` sur `UserRoleScope.setPermanent` quand le
       champ "Permanent ?" n'est pas coché explicitement — contourné en
       cochant "Permanent" dans le formulaire
    2. **Self-update interdit** : un utilisateur ne peut pas se créer sa
       propre portée de rôle de stock (`userrolescopes.userUuid.selfupdate`)
       — contourné en créant un compte temporaire pour attribuer la
       portée au compte principal
    3. **Cause racine trouvée : `at_location_id` cannot be null` à la
       création d'une opération.** `StockOperationDTOValidator` — le
       code censé résoudre l'emplacement et remplir `atLocationUuid` —
       n'est **jamais invoqué nulle part dans le module 3.0.0** (code
       mort), confirmé par un bug report public et une PR de correctif
       encore ouverte à l'amont :
       https://talk.openmrs.org/t/operation-receipt-save-fails-with-at-location-id-cannot-be-null-stockmanagement-api-3-0-0/49811
       et https://github.com/openmrs/openmrs-module-stockmanagement/pull/47
       — **corrigé en buildant nous-mêmes le module depuis la branche du
       correctif** (fork `ebouJ/openmrs-module-stockmanagement`, commit
       `890c93736e591fc3a4fb9977ae260de7b9b371b7`, version
       `3.1.0-SNAPSHOT`) : voir `backend/Dockerfile` (étape de build
       Maven supplémentaire avant la distro) et
       `backend/distro/pom.xml` (`stockmanagement.version`)
    4. Une fois le validateur actif, deux vrais contrôles de permission
       sont apparus (auparavant silencieusement ignorés) :
       - la "Portée" (User role scope) doit couvrir l'emplacement
         **exact requis par le type d'opération** (ex. "Receipt" exige
         un emplacement taggé "Main Store", pas juste l'établissement
         parent "Fondation Fasse")
       - le champ **"Rôle"** de la portée doit être un rôle qui possède
         réellement le privilège technique `Task:
         stockmanagement.stockoperations.mutate` (ex. "Inventory
         Manager" ou "Inventory Clerk") — **pas** "System Developer",
         qui ne l'a pas malgré ses autres privilèges élevés
    - Testé avec succès : réception "RCPT-0001" (Paracétamol, Fasse
      store → Main Store) créée, quantité reflétée dans le tableau de
      bord ("En rupture de stock" mis à jour en conséquence)
    - Reste à faire (optionnel, complétude démo) : faire une réception
      pour les 10 autres médicaments du catalogue
- ✅ **§11-12 Prescription d'examens / Laboratoire** — onglet "Laboratoire"
  natif (`esm-laboratory-app`), workflow prescrit → prélevé → résultat
  disponible → validé
  - ✅ Catalogue de tests/examens configuré via Initializer :
    `concepts/laboratory_exams_concepts.csv` — 14 nouveaux concepts
    classe "Test" (Glycémie labo, CRP, Urée, NFS, Bilan hépatique,
    Bilan lipidique, TSH, Sérologies, Examens urinaires, Holter ECG,
    Spirométrie, Polygraphie, Échographie, Radiographie), en
    réutilisant HbA1c / Créatinine / Ionogramme / Résultat ECG /
    Résultat MAPA déjà créés pour §7-8 et §21 — couvre l'intégralité
    de la liste du protocole §11
  - ✅ Testé sur l'instance déployée (2026-09-17) : "Glycémie"
    prescriptible via "Analyses" → "Test order" dans le dossier
    patient (ORD-377), et la demande apparaît bien dans la file
    d'attente du module Laboratoire ("Examens prescrits")
- ⬜ **§13 Courbes biologiques** — pas d'équivalent natif évident dans le
  menu ; probablement à construire (graphique d'évolution par patient)
- 🚧 **§14 Résultats des examens** — via Observations/Encounters + upload
  de documents ; à vérifier la prise en charge de l'import PDF
- ⬜ **§15 Adressage et courriers** — pas de module natif visible ; à
  construire (génération de lettres/certificats/ordonnances imprimables)
- ⬜ **§16 Module Kinésithérapie** — pas de module natif ; à construire
  (formulaire de séance + compteur de séances restantes), possiblement
  via Form Builder + un rapport dédié
- 🚧 **§19-20 Rendez-vous et agenda** — module natif "Rendez-vous"
  (Appointment Scheduling) visible dans la nav, en plus du service
  caisse déjà en place
- ✅ **§21 Dossier patient chronique** — configuré via Initializer dans
  `backend/distro/configuration/` :
  - `encountertypes/encountertypes.csv` : type d'encounter "Suivi de
    programme chronique" (ajouté à côté de "Consultation médicale")
  - `concepts/chronic_programs_concepts.csv` : 2 concepts "Program"
    (Diabète, Hypertension) + 8 concepts cliniques (HbA1c, créatinine,
    albuminurie, fond d'œil, contrôle des pieds, ionogramme, résultat
    ECG, résultat MAPA) — poids/TA restent sur le widget natif Vitals,
    glycémie capillaire et traitement réutilisent les concepts déjà
    créés pour la Consultation médicale (§7-8)
  - `programs/chronic_programs.csv` : "Programme Diabète" et "Programme
    Hypertension", inscriptibles/consultables via le module Programs
    natif (Administration → Gérer Programmes) et Cohort Builder
  - `ampathforms/suivi_diabete.json` et `ampathforms/suivi_hypertension.json` :
    formulaires de visite de suivi correspondants
  - ✅ Testé sur l'instance déployée (2026-09-15) : inscription du
    patient au "Programme Diabète" confirmée (statut Actif), formulaire
    "Suivi Diabète" ouvert et enregistré avec succès depuis
    "Formulaires cliniques" (et non "Actions" — voir correction de
    navigation ci-dessous)
  - Non couvert pour l'instant : workflows/états de programme (ex.
    "actif" / "perdu de vue" / "transféré" / "décédé") — l'inscription
    simple avec dates suffit pour une première version
- ⬜ **§22 Module Personnel** (fiche administrative salarié) — aucun
  équivalent RH dans OpenMRS ; à construire (hors périmètre clinique)
- ⬜ **§23 Pointage et présence du personnel** — à construire
- ⬜ **§24 Salaires** — à construire
- ⬜ **§25 Administration** (fournisseurs, contrats, équipements...) — à
  construire, hors couverture OpenMRS
- ⬜ **§26 Dépenses de la structure** — à construire
- 🚧 **§30 Centre d'alertes** — module "Alerte des Patients" / "Gestion
  des Alertes" (Patient Flags) natif pour les alertes cliniques
  - ✅ Alertes stock (stock faible, péremption) **déjà couvertes
    nativement** par le tableau de bord "Gestion des Stocks" (confirmé
    fonctionnel pendant les tests §10) — rien à ajouter
  - ✅ Premier flag clinique configuré via Initializer :
    `flags/clinical_flags.csv` — "Résultat biologique anormal" (SQL
    evaluator), se déclenche quand Glycémie, CRP, Urée, TSH, HbA1c,
    Créatinine ou Glycémie capillaire sort de sa plage normale définie
    sur les concepts §7-8/§11/§21
  - ✅ Testé avec succès sur l'instance déployée (2026-09-18) : le flag
    se déclenche bien pour Richard Jones après une glycémie capillaire
    hors norme (2,5 g/L). Trois problèmes trouvés et corrigés en route :
    1. Classe évaluateur mal nommée : `SqlFlagEvaluator` (comme dans
       l'exemple de la doc Initializer) n'existe pas dans
       `patientflags` 3.0.10 → c'est `SQLFlagEvaluator` (SQL en
       majuscules)
    2. La requête doit contenir littéralement un motif `alias.patient_id`
       référençant une vraie colonne (la table `obs` n'a que
       `person_id`) — corrigé en joignant la table `patient`
       (`pat.patient_id`)
    3. Les opérateurs `<`/`>` se sont fait corrompre en `&lt;`/`&gt;`
       lors d'un copier-coller dans le formulaire "Modifier Alerte" de
       l'admin legacy, cassant la syntaxe SQL — corrigé en réécrivant
       la requête avec `NOT BETWEEN ... AND ...` pour éviter ces
       caractères entièrement
    - ⚠️ **Note de divergence** : ce flag a été corrigé directement en
      base via l'UI "Modifier Alerte" (Initializer ne semble pas
      re-synchroniser un flag existant après une modification du CSV —
      comportement à creuser si on ajoute d'autres flags). Le fichier
      `flags/clinical_flags.csv` a été mis à jour avec la même requête
      corrigée pour rester cohérent, mais un déploiement futur depuis
      zéro (volume vide) doit être revérifié pour confirmer que le CSV
      seul suffit.
  - ⬜ Alerte "facture non réglée" : relève du service `caisse` (base de
    données séparée), pas un Patient Flag OpenMRS — à construire côté
    caisse si besoin
  - ⬜ Reste à ajouter si le premier flag fonctionne : rendez-vous à
    venir, contrôle médical à programmer, salarié absent/retard,
    document administratif expirant
- 🚧 **§31 Statistiques** — module Rapports natif (Report Builder, Cohort
  Queries, Data Set Definitions) permet de construire les statistiques
  demandées sans développement ad hoc. **Pas configurable via
  Initializer** (pas de domaine dédié aux définitions de rapports) —
  construction manuelle via l'UI, à la demande
  - ✅ Partiellement couvert côté service `caisse` : `GET
    /reports/daily-summary` (patients/recettes du jour, §3 et §27)
  - ✅ Cohort Query "Patients vus aujourd'hui" (Encounter Query, toute
    rencontre entre deux dates fixes) créée et **confirmée sauvegardée**
    dans Administration → Cohort Queries (2026-09-18) — attention aux
    champs "from forms" / "created by" qui peuvent se cocher par
    erreur et sur-restreindre la requête
  - ✅ **SQL Dataset "Résumé caisse du jour"** créé et sauvegardé
    (Administration → Data Set Definitions → SQL Dataset), résout le
    manque de rapport de clôture de caisse noté en §17-18/§27 sans
    passer par Jasper :
    ```sql
    SELECT pm.name AS moyen_de_paiement, SUM(p.amount) AS total, COUNT(*) AS nb_paiements
    FROM cashier_bill_payment p
    JOIN cashier_payment_mode pm ON pm.payment_mode_id = p.payment_mode_id
    WHERE p.voided = 0 AND DATE(p.date_created) = CURDATE()
    GROUP BY pm.name
    ```
    Testé avec succès : retourne "Cash | 2000.00 | 1" correspondant au
    paiement réel de Richard Jones. Tables du module Billing (héritage
    "Cashier") : `cashier_bill`, `cashier_bill_payment`,
    `cashier_payment_mode`, `cashier_cash_point`, `cashier_timesheet`
  - ⬜ Étapes suivantes pour finaliser ces rapports en "Rapports"
    exécutables : créer un **Report Definition** combinant chaque
    Cohort/Data Set, exécutable depuis "Rapports" → "Exécuter les
    rapports". Actuellement seulement prévisualisables depuis leur
    page d'édition, pas encore de vrai rapport planifiable/exportable
  - ⬜ Reste à construire (répéter le même schéma SQL Dataset) :
    répartition par service, diagnostics fréquents, consommation de
    médicaments, fréquentation labo/dentaire/ophta/kiné, nouveaux vs
    anciens patients, et étendre le résumé caisse à "montant théorique
    vs encaissé" (comparer factures POSTED vs PAID) pour coller
    exactement au §18
    patients — chacun est une nouvelle Cohort/Data Set/Report
    Definition à créer via l'UI selon le besoin réel de la clinique

Légende : 🚧 = module natif disponible, configuration à faire ; ⬜ = rien
de natif, développement nécessaire.

## Principe transverse à respecter (§34-35)

- Éviter toute double saisie : une info saisie une fois doit circuler
  automatiquement entre modules (ex. prescription → labo → caisse → dossier).
- Un patient = un dossier = un parcours = une facture = un historique
  unique, identifié par l'UUID OpenMRS partout.
