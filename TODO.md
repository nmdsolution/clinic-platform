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
- 🚧 **§10 Module Pharmacie (stock)** — "Gérer le Stock" / "Gestion des
  Stocks" (module Stock Management) déjà dans le menu admin et déjà
  dans le distro (`stockmanagement-omod`) ; **non couvert par
  Initializer** (pas de domaine dédié) — les stocks, seuils d'alerte et
  péremptions doivent être saisis directement dans l'UI "Gestion des
  Stocks" une fois le catalogue de médicaments ci-dessus chargé,
  puisque ce sont des données d'exploitation (quantités réelles) et non
  des métadonnées versionnables
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
