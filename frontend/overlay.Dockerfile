# Builds the Caisse module and the custom-branded Clinic FACE login module, then overlays both
# on top of the officially published OpenMRS 3 frontend image - same technique as
# frontend-modules/esm-caisse-app/overlay.Dockerfile (patch importmap.json + routes.registry.json,
# copy the module's dist/ in), extended here to also replace the stock login screen.
#
# Build context for this Dockerfile is the repository root (see docker-compose.override.yml),
# so every COPY below is a repo-root-relative path.

ARG BASE_FRONTEND_TAG=3.7.1

FROM node:20-alpine AS build-caisse
WORKDIR /app
COPY frontend-modules/esm-caisse-app/package.json ./
RUN npm install --legacy-peer-deps
COPY frontend-modules/esm-caisse-app/tsconfig.json frontend-modules/esm-caisse-app/rspack.config.js ./
COPY frontend-modules/esm-caisse-app/src ./src
COPY frontend-modules/esm-caisse-app/translations ./translations
RUN npm run build

FROM node:20-alpine AS build-login
WORKDIR /app
COPY frontend/custom-modules/esm-login-app/package.json ./
RUN npm install --legacy-peer-deps
COPY frontend/custom-modules/esm-login-app/tsconfig.json frontend/custom-modules/esm-login-app/rspack.config.js ./
COPY frontend/custom-modules/esm-login-app/src ./src
RUN npm run build

FROM openmrs/openmrs-reference-application-3-frontend:${BASE_FRONTEND_TAG} AS base-frontend

FROM node:20-alpine AS merge
WORKDIR /merge
COPY --from=base-frontend /usr/share/nginx/html/importmap.json ./importmap.json
COPY --from=base-frontend /usr/share/nginx/html/routes.registry.json ./routes.registry.json
COPY --from=build-caisse /app/dist/routes.json ./caisse-routes.json
COPY --from=build-login /app/dist/routes.json ./login-routes.json
RUN node -e " \
  const fs = require('fs'); \
  const importmap = JSON.parse(fs.readFileSync('importmap.json', 'utf8')); \
  importmap.imports['@face/esm-caisse-app'] = './openmrs-esm-caisse-app-1.0.0/openmrs-esm-caisse-app.js'; \
  importmap.imports['@openmrs/esm-login-app'] = './openmrs-esm-login-app-custom-1.0.0/openmrs-esm-login-app.js'; \
  fs.writeFileSync('importmap.json', JSON.stringify(importmap)); \
  const registry = JSON.parse(fs.readFileSync('routes.registry.json', 'utf8')); \
  const caisseRoutes = JSON.parse(fs.readFileSync('caisse-routes.json', 'utf8')); \
  const loginRoutes = JSON.parse(fs.readFileSync('login-routes.json', 'utf8')); \
  registry['@face/esm-caisse-app'] = caisseRoutes; \
  registry['@openmrs/esm-login-app'] = loginRoutes; \
  fs.writeFileSync('routes.registry.json', JSON.stringify(registry)); \
  "

FROM openmrs/openmrs-reference-application-3-frontend:${BASE_FRONTEND_TAG}
COPY --from=build-caisse /app/dist /usr/share/nginx/html/openmrs-esm-caisse-app-1.0.0/
COPY --from=build-login /app/dist /usr/share/nginx/html/openmrs-esm-login-app-custom-1.0.0/
COPY --from=merge /merge/importmap.json /usr/share/nginx/html/importmap.json
COPY --from=merge /merge/routes.registry.json /usr/share/nginx/html/routes.registry.json
# Remplace le config-core_demo.json de stock par notre version (mêmes clés de
# base + couleur de marque et logo Clinique FACE) : le nom de fichier reste
# identique à celui déjà référencé par SPA_CONFIG_URLS, donc rien d'autre à
# changer côté docker-compose.
COPY frontend/config-core_demo.json /usr/share/nginx/html/config-core_demo.json
