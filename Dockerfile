FROM node:22-alpine

WORKDIR /app

# System deps for native modules and gws CLI
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git \
    curl \
    bash

# Install dependencies first (layer cache)
COPY package*.json ./
COPY scripts/ ./scripts/
RUN npm ci --omit=dev

# Copy application source
COPY . .

# Build UI assets
RUN npm run build:ui 2>/dev/null || echo "[docker] UI build skipped (no prebuilt assets)"

# Persistent data volume — openclaw config, credentials, memory
VOLUME ["/app/.openclaw"]

# AlphaClaw web UI
EXPOSE 3000

# Make entrypoint executable
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
