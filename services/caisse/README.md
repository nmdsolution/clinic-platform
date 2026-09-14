# Module Caisse & Facturation — Clinique FACE

Microservice Python (FastAPI) implémentant les sections **17 (Facturation)**
et **18 (Module Caisse)** du protocole fonctionnel de la Clinique FACE, plus
une brique de départ pour le tableau de bord financier (§27).

Ce service ne duplique jamais le dossier médical : il référence les patients
par leur `uuid` OpenMRS et va chercher leur nom via l'API REST d'OpenMRS
(`GET /caisse/patients/search?q=...`).

## Ce qui est implémenté

- **Facturation** : création de facture, lignes d'actes/médicaments,
  remise, prise en charge assurance, annulation tracée (jamais de
  suppression silencieuse — cahier des charges §29).
- **Encaissement** : espèces, Mobile Money, Orange Money, virement,
  assurance, gratuité. Numéro de reçu unique. Refus si le montant dépasse
  le solde dû.
- **Session de caisse** : ouverture avec fonds de départ, fermeture avec
  comptage réel et calcul automatique de l'écart (`variance`).
- **Rôles** : ADMIN, PROMOTRICE, DAF, CAISSIER, SECRETAIRE — certaines
  actions (annulation de facture, création de comptes) sont réservées.
- **Journal des modifications** : chaque action sensible (création,
  paiement, annulation, ouverture/fermeture de caisse) est enregistrée
  dans `audit_logs` avec l'auteur et l'horodatage.
- **Tableau de bord** : `GET /reports/daily-summary` (recettes du jour,
  répartition par moyen de paiement et par catégorie d'acte, factures
  impayées).

## Ce qui n'est PAS encore fait (prochaines étapes)

- Interface web (cette première version est une API pure — testable via
  `/docs`, à consommer depuis un frontend à construire).
- Migrations de schéma versionnées (Alembic) — pour l'instant les tables
  sont créées automatiquement au démarrage (`create_all`), suffisant en
  développement mais à remplacer avant une mise en production durable.
- Impression PDF des factures/reçus (le endpoint `/payments/{id}/receipt`
  renvoie les données structurées, pas encore un PDF).
- Génération automatique de lignes de facture depuis les prescriptions
  OpenMRS (le principe « pas de double saisie » du §34 n'est pour l'instant
  câblé que côté recherche patient ; le lien prescription → ligne de
  facture reste à faire quand le module Pharmacie sera construit).

## Démarrage

Le service est déclaré dans `docker-compose.yml` (service `caisse`) et
démarre avec le reste de la plateforme :

```bash
docker compose up -d
```

Il est exposé via le gateway sur `http://localhost/caisse/` — par exemple
`http://localhost/caisse/docs` pour la documentation interactive Swagger.

**Identifiants par défaut** (à changer immédiatement en production, via les
variables d'environnement `CAISSE_ADMIN_USERNAME` / `CAISSE_ADMIN_PASSWORD`) :

```
Utilisateur : admin
Mot de passe : ChangeMoi123!
```

## Variables d'environnement principales

| Variable                     | Rôle                                                  | Défaut                    |
|-------------------------------|--------------------------------------------------------|---------------------------|
| `CAISSE_DB_HOST`              | Hôte MariaDB (réutilise le conteneur `db` existant)     | `db`                      |
| `CAISSE_DB_NAME`              | Base dédiée (créée automatiquement au démarrage)        | `face_caisse`             |
| `CAISSE_JWT_SECRET`           | Clé de signature des jetons de session                 | *(à définir !)*           |
| `CAISSE_ADMIN_USERNAME/PASSWORD` | Compte admin créé au premier démarrage               | `admin` / `ChangeMoi123!` |
| `CAISSE_OPENMRS_BASE_URL`     | URL de l'API OpenMRS pour la recherche patient          | `http://backend:8080/openmrs` |
| `CAISSE_OPENMRS_USERNAME/PASSWORD` | Identifiants du compte technique OpenMRS utilisé   | `admin` / `Admin123`      |

## Tests

```bash
cd services/caisse
python -m venv .venv && .venv/Scripts/activate   # ou source .venv/bin/activate sous Linux/Mac
pip install -r requirements.txt pytest
pytest -v
```

Les tests utilisent une base SQLite en mémoire — ils ne touchent jamais à
la vraie base MariaDB de la plateforme.

## Parcours métier couvert par les tests (`tests/test_invoices.py`)

1. Connexion / rejet d'identifiants invalides.
2. Création de facture, calcul automatique du total (lignes - remise -
   part assurance).
3. Refus d'encaissement si aucune session de caisse n'est ouverte.
4. Cycle complet : ouverture de caisse → facture → paiement partiel
   (espèces) → refus si le montant dépasse le solde → solde final (Mobile
   Money) → fermeture de caisse avec écart nul.
5. Détection d'un écart de caisse (manque en espèces).
6. Impossibilité d'ouvrir deux sessions de caisse simultanément.
7. Contrôle des rôles : un caissier ne peut pas annuler une facture,
   un DAF/administrateur le peut.
8. Tableau de bord quotidien reflète bien les factures et paiements.
