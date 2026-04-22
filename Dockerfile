FROM node:22-alpine

WORKDIR /app

# System deps for native modules and gws CLI
RUN apk add --no-cache     python3     make     g++     git     curl     bash

# Install ALL dependencies (including devDeps needed for UI build)
COPY package*.json ./
COPY scripts/ ./scripts/
RUN npm ci

# Copy application source
COPY . .

# Build UI assets (requires tailwindcss, esbuild, @xterm/xterm from devDeps)
RUN npm run build:ui

# Prune devDependencies after build to keep image lean
RUN npm prune --omit=dev

# AlphaClaw web UI
EXPOSE 3000

# Make entrypoint executable
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
