# HGest — Architecture du dépôt

> Document de départ (Phase 0), rédigé à partir de l'exploration du dépôt le 25/11/2026.
> À tenir à jour à chaque lot. Les points marqués **(à confirmer)** n'ont pas pu être vérifiés dans le code.

## 1. Vue d'ensemble

HGest = distribution **OpenMRS 3 (O3)** déployée à la Fondation Médicale FASSE
(`https://fasse.franco-avenir.org/openmrs/spa`), orchestrée par Docker Compose.

```
Navigateur ──► gateway (nginx) ──┬─► frontend (nginx, SPA O3 + nos esm-*)   /openmrs/spa/
                                 ├─► backend  (OpenMRS 2.8 / Java 21)       /openmrs
                                 ├─► caisse   (FastAPI, base face_caisse)   /caisse/
                                 ├─► Gemini API (clé côté serveur)          /assistant-api/generate
                                 └─► grafana  (monitoring, optionnel)       /grafana
                          db (MariaDB 10.11) ◄── backend + caisse
```

| Dossier | Rôle |
|---|---|
| `frontend/` | Assemblage de la SPA O3 (`spa-assemble-config.json`, 41 modules officiels), config runtime `config-core_demo.json`, et `custom-modules/` (nos 3 `esm-*`). |
| `backend/distro/` | Distribution OpenMRS : `distro.properties` (liste des modules omod) + `configuration/` (Initializer : concepts, drugs, encounter types, locations, programmes, formulaires AMPATH, flags, global properties). |
| `backend/Dockerfile` | Construit le WAR/omods, **recompile un `stockmanagement` patché** (fork `ebouJ`, commit épinglé — PR amont non publiée), remplace le logo du legacy UI. |
| `backend/services/caisse/` | Microservice FastAPI de caisse/facturation (JWT propre, sessions de caisse, factures, paiements, files, RDV, rapports) + tests pytest. |
| `gateway/` | nginx reverse proxy (CSP, gzip, assets logo, proxy Gemini, `/caisse/`, `/grafana`), entrypoint avec templates SSL. |
| `grille/` | **Scripts SQL de données** (tarifs, stock, labo, locations, datasets du tableau de bord) + sources Word/PDF de la grille tarifaire. |
| `monitoring/`, `certbot/`, `tests/` | Prometheus/Loki/Grafana/blackbox ; certificats ; tests e2e et SSL hérités d'OpenMRS. |

## 2. Frontend

### Modules personnalisés (`frontend/custom-modules/`)
| Module | Package | Pages / extensions | Remarques |
|---|---|---|---|
| `esm-tableau-de-bord-app` (v1.5.4) | `@face/esm-tableau-de-bord-app` | Pages `tableau-de-bord`, `patients`, `medicaments`, `ventes` ; extensions `barre-modules` (slot `top-nav-info-slot`) et `assistant-ia` (slot `top-nav-actions-slot`). | Lit les données via des **datasets de reporting SQL** (`api.ts`, UUID `0f7a0000-…b001`→`b016`) créés par `grille/tableau_de_bord_datasets.sql`. Textes FR/EN (`translations/`), mais une partie des libellés est en dur (ex. `assistant/connaissances.ts`). |
| `esm-caisse-app` | `@face/esm-caisse-app` | Page `caisse`, lien de menu `caisse-menu-link`. | UI du microservice `caisse`. **Lien retiré du menu** par `config-core_demo.json` (`remove: caisse-menu-link`) → module de facto inactif. |
| `esm-login-app` | surcharge du login O3 | login, sélecteur d'emplacement, changement de mot de passe. | Logo `logo-clinic.png` aussi utilisé par `backend/Dockerfile`. |

### Build et déploiement front
- Le déploiement réel passe par `docker-compose.override.yml` (chargé automatiquement) → `frontend/overlay.Dockerfile`, qui **compile les trois `esm-*`** (caisse, tableau de bord, login) et les fusionne dans l'image officielle `openmrs-reference-application-3-frontend:3.7.1` (patch de `importmap.json` + `routes.registry.json`). Vérifié sur le serveur : `@face/esm-caisse-app`, `@face/esm-tableau-de-bord-app` (1.5.4) et le login custom sont dans l'importmap. L'overlay de `custom-modules/esm-caisse-app/` est l'ancienne version (caisse seule), non utilisée.
- Le numéro de version est **codé en dur dans le chemin** (`openmrs-esm-tableau-de-bord-app-1.5.4/`) : un changement de version impose de modifier l'overlay (et d'incrémenter pour casser le cache navigateur).
- Config runtime : `frontend/config-core_demo.json` (couleur de marque, logo, devise XAF, config labo, retrait du lien caisse).
- Les modules officiels (`esm-billing-app 1.3.1`, `esm-stock-management-app 3.2.1`, `esm-laboratory-app 1.5.1`, `esm-ward-app`, `esm-service-queues-app`, `esm-appointments-app`, `esm-dispensing-app`…) sont ceux d'O3 ; leurs libellés viennent des traductions amont (d'où l'anglais résiduel).

## 3. Backend OpenMRS

- Modules clés (`distro.properties`) : initializer, fhir2, webservices.rest, idgen, legacyui, addresshierarchy, reporting + reportingrest, queue, appointments (Bahmni), bedmanagement, **stockmanagement**, **billing** (tables `cashier_*`), tasks, patientflags, o3forms, authentication, referencedemodata/demo content.
- **Initializer** (`backend/distro/configuration/`) : seul `concepts/laboratory_orderables_fasse.csv` est copié dans l'image (cf. fin du `backend/Dockerfile`). Le commentaire du Dockerfile précise que **les autres fichiers ont été chargés à la main** sur le serveur et ne doivent pas être rejoués (risque de doublons).
- Configuration globale : `globalproperties.csv` (nom HGest, locale `fr`, devise XAF, logo reçu).

## 4. Deux piles de facturation en parallèle

| | OpenMRS `billing` (module omod + `esm-billing-app`) | `caisse` (FastAPI + `esm-caisse-app`) |
|---|---|---|
| Statut | **Utilisé en production** (Ventes, Impayés, Tarifs, Recettes lisent `cashier_*`) | Déployé dans compose mais **non exposé** dans l'UI |
| Données | tables `cashier_billable_service`, `cashier_item_price`… chargées par `grille/tarifs_billing_init.sql` | base séparée `face_caisse` |
| Fonctions | paiement simple, un seul tarif « Standard » | sessions de caisse, JWT, files, RDV, rapports |

**Décision à prendre avant la Phase 1 (P2)** : choisir une seule source de vérité (voir §7). Construire les grilles tarifaires/tiers payant sur les deux serait du gaspillage.

## 5. Données de référence et déploiement des données

- Les données FASSE (tarifs, stock, labo, locations, datasets) sont des **scripts SQL manuels** dans `grille/` (usage documenté : `scp` + `docker exec mysql … < fichier.sql` sur le VPS). Ils ne sont **ni idempotents ni versionnés par une migration**, et contredisent l'exigence « redéployer chez un nouveau client en une commande » (roadmap §5).
- `stock_items_import.csv` (racine) : import d'articles de stock.
- Secrets : `docker-compose.yml` contient des valeurs par défaut faibles (`ChangeMoi123!`, `Admin123`, `changeme-…`) ; `.env` est ignoré par git et géré à la main sur chaque serveur ; `GEMINI_API_KEY`/`GEMINI_MODEL` viennent de l'environnement du gateway.

## 6. Tests et CI

- `backend/services/caisse/tests/` : pytest (auth, factures, files, RDV).
- **Aucun test** dans les `esm-*` (pas de Jest configuré, pas de Playwright). `tests/e2e/` est l'héritage OpenMRS (scripts d'images), pas notre parcours.
- `.github/workflows/` : workflows hérités du dépôt de référence O3 **(à auditer : lesquels s'appliquent encore ?)**.
- `CHANGELOG.md` n'existe pas ; `CLAUDE.md` est ignoré par git.

## 7. Constats qui influencent la feuille de route

1. **Déploiement front OK** : `docker compose build frontend && docker compose up -d frontend` sur `/opt/clinic-platform` (à confirmer par le propriétaire).
2. **Deux piles de facturation** — arbitrage nécessaire (recommandation : rester sur `billing` OpenMRS + `stockmanagement`, qui alimentent déjà le tableau de bord, et étendre par un module backend/config ; garder `caisse` seulement si on réutilise ses sessions de caisse/clôture).
3. **Données par SQL manuel** → les convertir en Initializer (CSV/JSON) ou en scripts idempotents versionnés avant d'aller plus loin.
4. **Le tableau de bord dépend de datasets SQL** identifiés par UUID fixes : tout changement de schéma billing/stock doit les mettre à jour.
5. **Traductions** : sources d'anglais = (a) libellés amont O3 → surcharge via `translations/` / config ; (b) données (services de visite, files, points de caisse, programmes, concepts) → Initializer/SQL ; (c) textes en dur dans nos `esm-*`.
6. **Stock** : le backend dépend d'un fork patché de `stockmanagement` (risque de maintenance tant que la PR amont n'est pas publiée).

## 8. Serveur de production (constaté en lecture seule)

- VPS `vps-7de2756e`, dépôt dans `/opt/clinic-platform` (même commit `a6339a4f` que le dépôt local), conteneurs `clinic-platform-{frontend,gateway,backend,caisse,db}-1` actifs.
- Le serveur héberge **d'autres projets** (solarhut, ecommerce-prod, whatagent-prod, ndaoo) : ne jamais toucher à leurs conteneurs ni à Docker globalement (`prune`, etc.).
- `.env` serveur : `TAG=3.7.1`, identifiants DB/admin/caisse et `GEMINI_API_KEY` (valeurs non copiées ici).
