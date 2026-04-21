#!/bin/bash
# AlphaClaw — Dustin's Agent
# Docker entrypoint: seeds config, places auth files, starts AlphaClaw
set -e

OPENCLAW_DIR="/app/.openclaw"
GOG_DIR="$OPENCLAW_DIR/gogcli"
CREDS_DIR="$OPENCLAW_DIR/credentials"
CRON_DIR="$OPENCLAW_DIR/cron"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log()  { echo -e "${GREEN}[d1-boot]${NC} $1"; }
warn() { echo -e "${YELLOW}[d1-warn]${NC} $1"; }

# ── 1. Create directory structure ────────────────────────────────────────────
log "Creating .openclaw directory structure..."
mkdir -p "$OPENCLAW_DIR" "$GOG_DIR" "$CREDS_DIR" "$CRON_DIR"
mkdir -p "$OPENCLAW_DIR/workspace-dustin/scripts"
mkdir -p "$OPENCLAW_DIR/workspace-dustin/memory"
mkdir -p "$OPENCLAW_DIR/workspace-dustin/data"

# ── 2. Resolve public URL ─────────────────────────────────────────────────────
PUBLIC_URL="${ALPHACLAW_BASE_URL:-${ALPHACLAW_SETUP_URL:-${RENDER_EXTERNAL_URL:-}}}"
if [ -z "$PUBLIC_URL" ]; then
    warn "ALPHACLAW_BASE_URL not set — Google Chat webhook will need manual configuration"
    PUBLIC_URL="http://localhost:3000"
fi
GOOGLECHAT_AUDIENCE="${PUBLIC_URL%/}/googlechat"
log "Public URL: $PUBLIC_URL"
log "Google Chat audience: $GOOGLECHAT_AUDIENCE"

# ── 3. Decode and place Google Chat service account ───────────────────────────
CHAT_SA_PATH="$OPENCLAW_DIR/google-chat-sa.json"
if [ -n "$GOOGLE_CHAT_SERVICE_ACCOUNT_B64" ]; then
    log "Placing Google Chat service account..."
    echo "$GOOGLE_CHAT_SERVICE_ACCOUNT_B64" | base64 -d > "$CHAT_SA_PATH"
    chmod 600 "$CHAT_SA_PATH"
elif [ -n "$GOOGLE_CHAT_SERVICE_ACCOUNT_JSON" ]; then
    echo "$GOOGLE_CHAT_SERVICE_ACCOUNT_JSON" > "$CHAT_SA_PATH"
    chmod 600 "$CHAT_SA_PATH"
else
    warn "GOOGLE_CHAT_SERVICE_ACCOUNT_B64 not set — Google Chat channel disabled until configured"
    CHAT_SA_PATH=""
fi

# ── 4. Decode and place Google OAuth client (for gws/AlphaClaw Google auth) ──
GOG_CREDENTIALS_PATH="$GOG_DIR/credentials.json"
if [ -n "$GOOGLE_OAUTH_CLIENT_B64" ]; then
    log "Placing Google OAuth client credentials..."
    echo "$GOOGLE_OAUTH_CLIENT_B64" | base64 -d > "$GOG_CREDENTIALS_PATH"
    chmod 600 "$GOG_CREDENTIALS_PATH"
    # Also place for gws CLI compatibility
    mkdir -p "$HOME/.config/gws"
    cp "$GOG_CREDENTIALS_PATH" "$HOME/.config/gws/client_secret.json" 2>/dev/null || true
elif [ -n "$GOOGLE_OAUTH_CLIENT_JSON" ]; then
    echo "$GOOGLE_OAUTH_CLIENT_JSON" > "$GOG_CREDENTIALS_PATH"
    chmod 600 "$GOG_CREDENTIALS_PATH"
else
    warn "GOOGLE_OAUTH_CLIENT_B64 not set — Google Workspace auth needs manual setup via UI"
fi

# ── 5. Seed openclaw.json if not exists ────────────────────────────────────────
OC_JSON="$OPENCLAW_DIR/openclaw.json"
if [ ! -f "$OC_JSON" ]; then
    log "Seeding openclaw.json..."
    CHAT_SA_CONFIG=""
    if [ -n "$CHAT_SA_PATH" ]; then
        CHAT_SA_CONFIG="\"$CHAT_SA_PATH\""
    else
        CHAT_SA_CONFIG="null"
    fi
    cat > "$OC_JSON" << JSONEOF
{
  "meta": { "version": "2026.4.15", "seededBy": "d1-docker-entrypoint" },
  "auth": { "profiles": {} },
  "agents": {
    "defaults": {
      "model": { "primary": "github-copilot/claude-sonnet-4.6", "fallbacks": [] },
      "skills": [],
      "memorySearch": { "type": "qmd", "scoreThreshold": 0.7 }
    },
    "list": [
      {
        "id": "main",
        "default": true,
        "model": "github-copilot/claude-sonnet-4.6",
        "workspace": "/app/.openclaw/workspace-dustin",
        "skills": ["google-workspace", "byterover", "websearch"],
        "identity": { "name": "D1", "emoji": "💼" },
        "heartbeat": {
          "every": "30m",
          "target": "googlechat",
          "lightContext": true,
          "isolatedSession": true,
          "activeHours": { "start": "00:00", "end": "09:00" }
        },
        "tools": {
          "deny": ["camera.snap","camera.clip","screen.record","contacts.add","sms.send"]
        },
        "sandbox": { "mode": "off" }
      }
    ]
  },
  "tools": {
    "profile": "coding",
    "web": { "search": { "enabled": true, "provider": "duckduckgo" } }
  },
  "channels": {
    "googlechat": {
      "enabled": ${CHAT_SA_PATH:+true}${CHAT_SA_PATH:-false},
      "serviceAccountFile": $CHAT_SA_CONFIG,
      "audienceType": "app-url",
      "audience": "$GOOGLECHAT_AUDIENCE",
      "allowBots": true,
      "dm": { "policy": "open", "allowFrom": ["*"] },
      "groupPolicy": "open",
      "groups": { "*": { "enabled": true } }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "all",
    "reload": { "mode": "hybrid", "debounceMs": 300 },
    "auth": { "mode": "token", "token": "" },
    "tailscale": { "mode": "off", "resetOnExit": false },
    "controlUi": {
      "allowInsecureAuth": true,
      "allowedOrigins": ["*"]
    },
    "nodes": {
      "denyCommands": ["camera.snap","camera.clip","screen.record","sms.send"]
    }
  },
  "skills": {
    "install": { "nodeManager": "npm" },
    "entries": {
      "google-workspace": {
        "enabled": true,
        "config": {
          "binary": "/usr/local/bin/gws",
          "credentialsDir": "/app/.openclaw/gogcli",
          "scriptPath": "/app/.openclaw/skills/google-workspace/gws.py"
        }
      }
    }
  },
  "models": {},
  "commands": { "native": "auto", "nativeSkills": "auto", "restart": true },
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "boot-md": { "enabled": true },
        "bootstrap-extra-files": { "enabled": true },
        "command-logger": { "enabled": true },
        "session-memory": { "enabled": true }
      }
    }
  },
  "session": {
    "scope": "per-sender",
    "dmScope": "per-peer",
    "reset": { "mode": "idle", "idleMinutes": 120 },
    "threadBindings": { "enabled": true, "idleHours": 24 }
  },
  "cron": {
    "enabled": true,
    "maxConcurrentRuns": 2,
    "sessionRetention": "24h"
  }
}
JSONEOF
    log "openclaw.json seeded"
else
    log "openclaw.json already exists — updating allowedOrigins and audience..."
    python3 - "$OC_JSON" "$GOOGLECHAT_AUDIENCE" "$CHAT_SA_PATH" "$PUBLIC_URL" << 'PYEOF'
import json, sys
path, audience, sa_path, public_url = sys.argv[1:]
d = json.load(open(path, encoding="utf-8"))

# Ensure allowedOrigins includes "*" and public_url
if "gateway" not in d: d["gateway"] = {}
if "controlUi" not in d["gateway"]: d["gateway"]["controlUi"] = {}
origins = d["gateway"]["controlUi"].get("allowedOrigins", [])
for o in ["*", public_url]:
    if o and o not in origins:
        origins.append(o)
d["gateway"]["controlUi"]["allowedOrigins"] = origins
d["gateway"]["bind"] = "all"

# Update Google Chat audience
if "channels" not in d: d["channels"] = {}
if "googlechat" not in d["channels"]: d["channels"]["googlechat"] = {}
d["channels"]["googlechat"]["audience"] = audience
if sa_path and sa_path != "null":
    d["channels"]["googlechat"]["serviceAccountFile"] = sa_path
    d["channels"]["googlechat"]["enabled"] = True

json.dump(d, open(path, "w", encoding="utf-8"), indent=2)
print("[d1-boot] openclaw.json updated")
PYEOF
fi

# ── 6. Seed cron/jobs.json if not exists ─────────────────────────────────────
CRON_JSON="$CRON_DIR/jobs.json"
if [ ! -f "$CRON_JSON" ]; then
    log "Creating empty cron/jobs.json..."
    echo '{"version":1,"jobs":[]}' > "$CRON_JSON"
fi

# ── 7. Copy workspace files if not exists ────────────────────────────────────
WORKSPACE="$OPENCLAW_DIR/workspace-dustin"
if [ ! -f "$WORKSPACE/IDENTITY.md" ] && [ -d "/app/config/workspace-dustin" ]; then
    log "Seeding workspace-dustin from bundled config..."
    cp /app/config/workspace-dustin/*.md "$WORKSPACE/" 2>/dev/null || true
    cp /app/config/workspace-dustin/scripts/*.sh "$WORKSPACE/scripts/" 2>/dev/null || true
    chmod +x "$WORKSPACE/scripts/"*.sh 2>/dev/null || true
fi

# ── 8. Set SETUP_PASSWORD from env ───────────────────────────────────────────
ENV_FILE="/app/.env"
if [ ! -f "$ENV_FILE" ]; then
    log "Creating .env file..."
    touch "$ENV_FILE"
fi

set_env() {
    local key="$1"; local val="$2"
    if [ -n "$val" ]; then
        if grep -q "^$key=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^$key=.*|$key=$val|" "$ENV_FILE"
        else
            echo "$key=$val" >> "$ENV_FILE"
        fi
    fi
}

set_env "SETUP_PASSWORD" "$SETUP_PASSWORD"
set_env "GITHUB_TOKEN" "$GITHUB_TOKEN"
set_env "GITHUB_WORKSPACE_REPO" "$GITHUB_WORKSPACE_REPO"
set_env "ALPHACLAW_BASE_URL" "$PUBLIC_URL"
set_env "WATCHDOG_AUTO_REPAIR" "${WATCHDOG_AUTO_REPAIR:-true}"
[ -n "$ANTHROPIC_API_KEY" ] && set_env "ANTHROPIC_API_KEY" "$ANTHROPIC_API_KEY"
[ -n "$OPENAI_API_KEY" ] && set_env "OPENAI_API_KEY" "$OPENAI_API_KEY"
# Gemini key — Coolify env var overrides; default provided so tools work out of the box
GEMINI_API_KEY="${GEMINI_API_KEY:-AIzaSyCHRwE6up3Y6alB9Z61fq4hnTCJfTHVMSM}"
set_env "GEMINI_API_KEY" "$GEMINI_API_KEY"

log "Boot complete. Starting AlphaClaw on port ${PORT:-3000}..."
exec node /app/bin/alphaclaw.js start
