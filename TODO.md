# TODO — Modules du protocole Clinique FACE

Suivi de l'implémentation des modules décrits dans
`Protocole_logiciel_Clinique_FACE.pdf`. Chaque ligne renvoie à la section du
protocole (§) pour retrouver le détail fonctionnel attendu.

Légende : ✅ fait · 🚧 en cours / partiel · ⬜ pas commencé

## Fait / en cours (service `backend/services/caisse`)

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
  - ⚠️ Pas encore testé sur une instance déployée — nécessite
    `docker compose build backend && docker compose up` puis vérifier
    dans "Gérer les formulaires" que le formulaire apparaît et se lance
    correctement depuis le dossier patient
- 🚧 **§9 Prescription médicamenteuse** — module Orders/Drug Orders natif
  OpenMRS ; à vérifier si activé et si le catalogue de médicaments
  (Concepts → Manage Concept Drugs) est renseigné
- 🚧 **§10 Module Pharmacie** — "Gérer le Stock" / "Gestion des Stocks"
  déjà dans le menu admin ; à configurer (produits, seuils d'alerte,
  péremption) plutôt qu'à développer
- 🚧 **§11-12 Prescription d'examens / Laboratoire** — onglet "Laboratoire"
  déjà présent dans la nav principale ; à vérifier le workflow
  prescrit → prélevé → résultat disponible → validé
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
- 🚧 **§21 Dossier patient chronique** — module "Programmes" ("Gérer
  Programmes") + Cohort Builder permettent l'inscription et le suivi de
  patients à un programme (diabète, HTA...) ; à configurer
- ⬜ **§22 Module Personnel** (fiche administrative salarié) — aucun
  équivalent RH dans OpenMRS ; à construire (hors périmètre clinique)
- ⬜ **§23 Pointage et présence du personnel** — à construire
- ⬜ **§24 Salaires** — à construire
- ⬜ **§25 Administration** (fournisseurs, contrats, équipements...) — à
  construire, hors couverture OpenMRS
- ⬜ **§26 Dépenses de la structure** — à construire
- 🚧 **§30 Centre d'alertes** — module "Alerte des Patients" / "Gestion
  des Alertes" (Patient Flags) natif pour les alertes cliniques ; les
  alertes stock/facture restent à raccorder (déjà partiellement dispo
  côté service caisse)
- 🚧 **§31 Statistiques** — module Rapports natif (Report Builder, Cohort
  Queries, Data Set Definitions) permet de construire les statistiques
  demandées sans développement ad hoc

Légende : 🚧 = module natif disponible, configuration à faire ; ⬜ = rien
de natif, développement nécessaire.

## Principe transverse à respecter (§34-35)

- Éviter toute double saisie : une info saisie une fois doit circuler
  automatiquement entre modules (ex. prescription → labo → caisse → dossier).
- Un patient = un dossier = un parcours = une facture = un historique
  unique, identifié par l'UUID OpenMRS partout.
