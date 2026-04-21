# Coolify Deployment Guide — D1 (Dustin's Agent)

## Prerequisites
- Coolify running at `https://cloud.boldbusiness.com`
- GitHub repo: `https://github.com/mnjbold/alphaclaw_dustin`
- Google Chat service account JSON (from Jewel)
- Google OAuth client JSON (`gog_client_secret.json`, from Jewel)

---

## Step 1 — Encode the Google credential files

Run these on your machine (WSL or Linux):

```bash
# Encode Google Chat service account
base64 -w0 ~/.openclaw/gen-lang-client-0768862569-d25b2b9e7693.json
# → copy the output → paste as GOOGLE_CHAT_SERVICE_ACCOUNT_B64 in Coolify

# Encode Google OAuth client
base64 -w0 ~/.openclaw/gog_client_secret.json
# → copy the output → paste as GOOGLE_OAUTH_CLIENT_B64 in Coolify
```

---

## Step 2 — Create a new service in Coolify

1. Open Coolify → **New Resource** → **Application**
2. Source: **GitHub** → select `mnjbold/alphaclaw_dustin`
3. Branch: `main`
4. Build: **Dockerfile** (auto-detected)
5. Port: `3000`

---

## Step 3 — Set environment variables

In Coolify → Service → **Environment Variables**, add ALL of these:

| Variable | Value |
|----------|-------|
| `SETUP_PASSWORD` | Choose a strong password |
| `ALPHACLAW_BASE_URL` | `https://d1.boldbusiness.com` (your Coolify domain) |
| `GITHUB_TOKEN` | GitHub PAT with repo read access |
| `GITHUB_WORKSPACE_REPO` | `mnjbold/alphaclaw_dustin` |
| `GOOGLE_CHAT_SERVICE_ACCOUNT_B64` | Output from Step 1 (service account) |
| `GOOGLE_OAUTH_CLIENT_B64` | Output from Step 1 (OAuth client) |
| `WATCHDOG_AUTO_REPAIR` | `true` |
| `PORT` | `3000` |

Optional (add later once confirmed):

| Variable | Value |
|----------|-------|
| `ANTHROPIC_API_KEY` | From Anthropic Console |
| `GEMINI_API_KEY` | From Google AI Studio |
| `DUSTIN_CHAT_USER_ID` | Dustin's Google Chat user ID |
| `MONDAY_API_KEY` | From Monday.com API settings |
| `JIRA_API_TOKEN` | From Atlassian account |

---

## Step 4 — Configure domain

1. Coolify → Service → **Domains**
2. Add: `d1.boldbusiness.com` (or whatever domain you choose)
3. Enable: **Force HTTPS**
4. Coolify handles SSL automatically

---

## Step 5 — Deploy

1. Click **Deploy** in Coolify
2. Watch logs — you'll see `[d1-boot]` messages
3. Once running, visit `https://d1.boldbusiness.com`
4. Login with `SETUP_PASSWORD`

---

## Step 6 — Connect Google Chat

After first boot, the audience URL is pre-set to `https://d1.boldbusiness.com/googlechat`.

Now tell the Google Chat app about this URL:

1. Go to **Google Cloud Console** → `gen-lang-client-0768862569` project
2. APIs & Services → **Google Chat API** → Configuration
3. Under **App URL**: set to `https://d1.boldbusiness.com/googlechat`
4. Save

Then in AlphaClaw UI → **Channels** → **Google Chat** → click **Test Connection**

---

## Step 7 — Authorize Google Workspace for Dustin

1. AlphaClaw UI → **Google** → **Add Account**
2. Scopes to request: Gmail, Calendar, Drive, Sheets, Docs, Tasks, Contacts, Meet
3. Sign in as: `djohnson@boldbusiness.com`
4. This authorizes D1 to access Dustin's Gmail, Calendar, Drive, etc.

---

## Step 8 — Authorize GitHub Copilot (for Claude Sonnet model)

1. AlphaClaw UI → **Models** → **GitHub Copilot**
2. Follow the auth flow
3. Select model: `claude-sonnet-4.6`

---

## Step 9 — Enable Cron Jobs

1. AlphaClaw UI → **Cron** → click **Import from file**
2. Upload `config/cron-jobs.json` (the pre-built Dustin cron schedule)
3. Verify all 18 jobs appear
4. Toggle them ON

---

## Step 10 — Persistent Storage in Coolify

**Critical:** AlphaClaw stores all config, credentials, and memory in `/app/.openclaw`.
This MUST be a Coolify volume or data will be lost on restart.

1. Coolify → Service → **Volumes**
2. Add volume: `/app/.openclaw` → `d1-openclaw-data`
3. Redeploy

---

## Verifying Everything Works

```bash
# Check logs in Coolify → Service → Logs
# Should see:
[d1-boot] Public URL: https://d1.boldbusiness.com
[d1-boot] Google Chat audience: https://d1.boldbusiness.com/googlechat
[d1-boot] Placing Google Chat service account...
[d1-boot] Placing Google OAuth client credentials...
[d1-boot] openclaw.json seeded
[d1-boot] Boot complete. Starting AlphaClaw on port 3000...
```

Then visit `https://d1.boldbusiness.com` — you should see the AlphaClaw setup UI.

---

## What's Pre-configured

✓ **Any URL allowed** — `allowedOrigins: ["*"]` in openclaw.json  
✓ **Any device** — `gateway.bind: "all"`  
✓ **Google Chat channel** — pre-seeded with service account + audience URL  
✓ **D1 agent** — model, skills, heartbeat, guardrails from onboarding  
✓ **Workspace files** — IDENTITY, SOUL, AGENTS, TOOLS, HEARTBEAT bundled  
✓ **Google OAuth client** — pre-placed for AlphaClaw's Google auth flow  
✓ **Watchdog** — auto-repair enabled  

What requires manual action:
- Dustin's GitHub Copilot auth (step 8)
- Dustin's Google Workspace auth/djohnson@boldbusiness.com (step 7)
- Google Chat app URL in Google Cloud Console (step 6)
- Cron job delivery target (DUSTIN_CHAT_USER_ID)
- Integration API keys (Monday, Jira, QuickBooks, T-Sheets)
