# syntax=docker/dockerfile:1
# Image Relaticle pour KOZAMA : identique à l'image officielle, mais l'interface est recompilée
# avec les réglages temps réel (Reverb) pour que l'assistant Rela affiche ses réponses en direct.
# Seuls les fichiers public/build sont remplacés : le code PHP reste exactement celui de l'image officielle.

ARG RELATICLE_IMAGE=ghcr.io/relaticle/relaticle:latest

FROM ${RELATICLE_IMAGE} AS base

FROM node:26-alpine AS frontend
WORKDIR /app
COPY --from=base /var/www/html/package.json /var/www/html/pnpm-lock.yaml ./
RUN npm install -g "$(node -p 'require("./package.json").packageManager')" \
    && pnpm install --frozen-lockfile --ignore-scripts
COPY --from=base /var/www/html/vite.config.js ./
COPY --from=base /var/www/html/resources ./resources
COPY --from=base /var/www/html/packages ./packages
COPY --from=base /var/www/html/vendor ./vendor
COPY --from=base /var/www/html/public ./public

# Valeurs publiques (elles finissent de toute façon dans le JavaScript envoyé au navigateur).
ARG VITE_REVERB_APP_KEY
ARG VITE_REVERB_HOST
ARG VITE_REVERB_PORT=443
ARG VITE_REVERB_SCHEME=https
ENV VITE_REVERB_APP_KEY=${VITE_REVERB_APP_KEY} \
    VITE_REVERB_HOST=${VITE_REVERB_HOST} \
    VITE_REVERB_PORT=${VITE_REVERB_PORT} \
    VITE_REVERB_SCHEME=${VITE_REVERB_SCHEME}

RUN test -n "$VITE_REVERB_APP_KEY" && test -n "$VITE_REVERB_HOST" \
    && rm -rf public/build && pnpm run build

FROM base
COPY --chown=www-data:www-data --from=frontend /app/public/build ./public/build
