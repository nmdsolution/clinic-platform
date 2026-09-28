# Construit le module Caisse puis le fusionne dans l'image frontend OpenMRS
# déjà officiellement construite (importmap.json + routes.registry.json
# patchés), sans relancer l'énorme pipeline de build Node de tous les
# modules officiels - juste notre petit module en plus.
# Build context: ./frontend (parent directory)

ARG BASE_FRONTEND_TAG=3.7.1

FROM node:20-alpine AS build
WORKDIR /app
COPY custom-modules/esm-caisse-app/package.json ./
RUN npm install --legacy-peer-deps
COPY custom-modules/esm-caisse-app/tsconfig.json custom-modules/esm-caisse-app/rspack.config.js ./
COPY custom-modules/esm-caisse-app/src ./src
COPY custom-modules/esm-caisse-app/translations ./translations
RUN npm run build

FROM openmrs/openmrs-reference-application-3-frontend:${BASE_FRONTEND_TAG} AS base-frontend

FROM node:20-alpine AS merge
WORKDIR /merge
COPY --from=base-frontend /usr/share/nginx/html/importmap.json ./importmap.json
COPY --from=base-frontend /usr/share/nginx/html/routes.registry.json ./routes.registry.json
COPY --from=build /app/dist/routes.json ./caisse-routes.json
RUN node -e " \
  const fs = require('fs'); \
  const importmap = JSON.parse(fs.readFileSync('importmap.json', 'utf8')); \
  importmap.imports['@face/esm-caisse-app'] = './openmrs-esm-caisse-app-1.0.0/openmrs-esm-caisse-app.js'; \
  fs.writeFileSync('importmap.json', JSON.stringify(importmap)); \
  const registry = JSON.parse(fs.readFileSync('routes.registry.json', 'utf8')); \
  const caisseRoutes = JSON.parse(fs.readFileSync('caisse-routes.json', 'utf8')); \
  registry['@face/esm-caisse-app'] = caisseRoutes; \
  fs.writeFileSync('routes.registry.json', JSON.stringify(registry)); \
  "

FROM openmrs/openmrs-reference-application-3-frontend:${BASE_FRONTEND_TAG}
COPY --from=build /app/dist /usr/share/nginx/html/openmrs-esm-caisse-app-1.0.0/
COPY --from=merge /merge/importmap.json /usr/share/nginx/html/importmap.json
COPY --from=merge /merge/routes.registry.json /usr/share/nginx/html/routes.registry.json
# Copy our custom config so it overrides the base image's default config-core_demo.json
COPY config-core_demo.json /usr/share/nginx/html/config-core_demo.json
