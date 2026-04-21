# D1 Agent Onboarding Checklist — Dustin Johnson
**Generated:** 2026-04-22 | **Based on:** BAIIT Onboarding Questionnaire v1.0  
**Agent:** D1 — Finance / HR / IT | **Email:** djohnson@boldbusiness.com

---

## ✅ DONE — Configured in this deployment

### Identity & Agent
- [x] Agent name: D1 (Dustin's Agent)
- [x] Owner: Dustin Johnson | djohnson@boldbusiness.com
- [x] Role: Head of Finance, HR & IT
- [x] Manager: Ed Kopko (CEO)
- [x] Direct reports: Viviana, Vina, Alana, Earmiel, Wendy — in USER.md
- [x] Timezone: PH (UTC+8)
- [x] Model: `claude-Opus+claude-sonnet-4.6` (977k ctx, finance reasoning)
- [x] Heartbeat: every 30min, 7am–5pm PH, lightContext + isolatedSession
- [x] Workspace files: IDENTITY, SOUL, USER, AGENTS, TOOLS, HEARTBEAT, MODELS, BOOT

### Automations & Cron (18 jobs — all in `config/cron-jobs.json`)

| Time (PH) | Job | What D1 does |
|-----------|-----|--------------|
| 7:00am daily | Morning Brief | Calendar, AR, HR (Monday) + IT (Jira) tickets, payments via email, alerts to Chat |
| 8:05am daily | IT Check-in Prep | Pulls Jira tickets, highlights critical items, emails Earmiel prep before 8:15 |
| 8:28am daily | Team Tracker Scrub | Overview dashboard before Vivi's 8:30 standup |
| 10:00am Mon | Alana 1:1 Prep | AR, client follow-ups, 1-on-1 agenda |
| 8:30am Tue | Invoice Approval Queue | Audits invoices — surfaces to Dustin, never auto-approves |
| 9:00am Wed | Vina HR TB Prep | HR audit items surfaced to Dustin |
| 10:00am Wed | Bold Weekly Sales Call Prep | Meeting prep, Justin slides focus, topic discussion |
| 10:00am alt-Wed | Biweekly Payroll Check | T-Sheets trend analysis → overview to Dustin + Ed; no counting; HITL gate |
| 9:00am Thu | Thursday Team Call Prep | Reviews meeting notes, flags actionable items, confirms with Dustin |
| 11:00am Thu | Ed Weekly Call Prep | Finance+HR+IT exec summary — report from team Wednesday, analysis + insights for Ed |
| 11:30am Thu | Leadership Call Prep | Compares Monday board vs. previous week — checklists + topic prep + follow-up |
| 4:30pm daily | EOD Action Check | Groups email items into action lists, creates Monday tasks, 1-month followup loop, sends via email + Chat |
| 5:00pm daily | EOD Summary | Dashboard update + saves daily report to Google Drive folder |
| 9:00am Fri | IT Weekly Report | Follows EOD summary format — Jira ISD, infra, Teramind |
| 9:05am Fri | HR Weekly Report | Follows EOD summary format — HR Jira, DocuSign, Greenhouse, visa |
| 10:00am Fri | AI Spend Weekly | Pulls from Jira + Monday, creates insights + maintains tracker sheet |
| 11:30am Fri | Earmiel TB Prep | From Jira tickets + past meeting minutes |
| 9:00am 1st Mon | Monthly Financials | 2nd Monday: remind team to prepare. 3rd Monday: analysis to Dustin |

### Databases Created for D1 (auto-maintained, not Dustin's existing sheets)
- [x] `D1 — Action Items & Reports` — action items from emails/meetings, monthly followup loop
- [x] `D1 — AR Tracker` — accounts receivable aging, client follow-up status
- [x] `D1 — Payroll History` — biweekly trend analysis, hours/headcount over time
- [x] `D1 — AI Spend Tracker` — weekly AI cost by service/team with insights
- [x] `D1 — Daily Reports Archive` — all EOD summaries, IT/HR weekly reports
- [x] `setup/setup_databases.sh` — creates all sheets via gws CLI, outputs sheet IDs
- [x] `setup/d1_database_schema.sql` — Supabase fallback if Google Sheets not preferred

### Scripts
- [x] `morning_brief.sh` — calendar, email, DocuSign, IT alerts, JIRA scrape
- [x] `finance_report.sh` — invoice data, AR, AI spend
- [x] `it_report.sh` — Jira ISD, infra alerts, Teramind
- [x] `hr_report.sh` — HR Jira, DocuSign, Greenhouse, visa tracking
- [x] `eod_summary.sh` — EOD action queue

### Guardrails (hard-coded in AGENTS.md + SOUL.md)
- [x] NEVER send email without Dustin's explicit approval
- [x] NEVER email outside @boldbusiness.com or @mercuryz.com
- [x] NEVER submit payroll (HITL gate always)
- [x] NEVER approve invoices (surface for review only)
- [x] NEVER share financials/PII externally without confirmation
- [x] Alert triggers: Ed emails, payroll keywords, payment due, DocuSign, backup failure

### Infrastructure (Docker + Coolify)
- [x] `Dockerfile` — Node.js 22 Alpine, port 3000
- [x] `docker-entrypoint.sh` — seeds openclaw.json, places auth files, starts
- [x] `openclaw.json` pre-seeded with:
  - [x] `gateway.bind: "all"` — accessible from any device/network
  - [x] `gateway.controlUi.allowedOrigins: ["*"]` — any URL allowed
  - [x] Google Chat channel pre-configured (audience auto-set from ALPHACLAW_BASE_URL)
  - [x] D1 agent config (model, skills, heartbeat, tools.deny)
  - [x] `GEMINI_API_KEY` baked in as default — no Coolify config needed
- [x] `.env.example` — all required Coolify variables listed
- [x] `COOLIFY_SETUP.md` — step-by-step 10-step deploy guide

### Tool Access (configured in AGENTS.md)
- [x] Gmail: send (draft+approve only), read, search
- [x] Google Calendar: read
- [x] Google Drive: read + write (reports saved to folder)
- [x] Google Sheets: read + write (all 5 D1 databases)
- [x] Google Chat: send DMs
- [x] Monday.com: read + create/move items (requires `MONDAY_API_KEY`)
- [x] QuickBooks: read + create invoices via MCP QuickBooks (requires client ID/secret)
- [x] T-Sheets: pull reports (read) (requires `TSHEETS_API_KEY`)
- [x] Jira: read tickets (requires `JIRA_API_TOKEN`)
- [x] DocuSign: read pending signatures

### Communication Preferences
- [x] Urgent/reports: Google Chat DM
- [x] Status updates: Monday.com
- [x] FYI/async: Email (draft, never auto-send)
- [x] EOD reports: saved to Google Drive + sent via Chat
- [x] Tone: Conversational but professional (in SOUL.md)
- [x] Recovery chain: Dustin → Ed → Earmiel → Vina

---

## ⏳ PENDING — Requires Dustin's Action

### Authentication (must be done by Dustin personally)

- [ ] **GitHub Copilot auth** — AlphaClaw UI → Models → GitHub Copilot → Auth
  - Account: djohnson@boldbusiness.com GitHub
  - Needed for: claude-sonnet-4.6 model access

- [ ] **Google Workspace auth** — AlphaClaw UI → Google → Add Account
  - Sign in as: djohnson@boldbusiness.com
  - Scopes: Gmail, Calendar, Drive, Sheets, Docs, Tasks, Contacts, Meet
  - After: `gws auth status` should show Valid: true

### Google Chat Setup
- [ ] **Set Chat app URL in Google Cloud Console**
  - URL: `https://YOUR-COOLIFY-DOMAIN/googlechat`
  - Location: console.cloud.google.com → `gen-lang-client-0768862569` → Google Chat API → Configuration
  - Contact Jewel if no access

- [ ] **Add bijouclaw bot to Google Chat**
  - Search: `bijouclaw@gen-lang-client-0768862569.iam.gserviceaccount.com`
  - Start a DM → copy `users/XXXXXXXXX` from URL bar → send to Jewel

- [ ] **Test Google Chat delivery**
  - AlphaClaw UI → Channels → Google Chat → Test Connection
  - Then: Cron → dustin-morning-brief → Run Now

### Coolify Deployment Steps
- [ ] Set `ALPHACLAW_BASE_URL` = your Coolify domain before first deploy
- [ ] Add `GOOGLE_CHAT_SERVICE_ACCOUNT_B64` (get base64 from Jewel)
- [ ] Add `GOOGLE_OAUTH_CLIENT_B64` (get base64 from Jewel)
- [ ] Add persistent volume: `/app/.openclaw` → `d1-openclaw-data`
- [ ] Deploy and check boot logs for `[d1-boot]` messages

### API Keys (Dustin generates → sends to Jewel → Jewel adds to Coolify)
- [ ] `MONDAY_API_KEY` — Monday.com → Profile → Developers → My API tokens
- [ ] `JIRA_API_TOKEN` — id.atlassian.com → Security → API tokens
- [ ] `QUICKBOOKS_CLIENT_ID` + `QUICKBOOKS_CLIENT_SECRET` — Intuit Developer Portal
- [ ] `TSHEETS_API_KEY` — QuickBooks Time → Gear → Company Settings → API Tokens

### Access Details Dustin Must Provide (fill in and send to Jewel)
- [ ] Monday Finance Board ID (from URL: monday.com/boards/XXXXXXXX)
- [ ] Monday HR Board ID
- [ ] Monday IT Board ID
- [ ] Monday General/Leadership Board ID
- [ ] Jira IT Project Key (currently assuming: `ISD` — confirm or correct)
- [ ] Jira HR Project Key (currently assuming: `HR` — confirm or correct)
- [ ] Google Drive folder ID where daily reports should be saved (or: create new)
- [ ] QuickBooks company name/ID
- [ ] Greenhouse API key or point of contact for access
- [ ] Teramind dashboard URL or API access details
- [ ] First payroll Wednesday date (so biweekly schedule is accurate)

### Database Setup (run after Google Workspace auth)
- [ ] Run `setup/setup_databases.sh` — creates all 5 D1 Google Sheets
  - Outputs env vars (DUSTIN_ACTIONITEMS_SHEET_ID, DUSTIN_AR_SHEET_ID, etc.)
  - Send output to Jewel → added to Coolify env vars
- [ ] OR: use `setup/d1_database_schema.sql` — apply to Supabase instead

### Review & Calibration (first 2 weeks)
- [ ] Confirm morning brief format matches expectations (adjust in AGENTS.md)
- [ ] Confirm invoice audit format works for Tuesday meeting
- [ ] Confirm payroll-weeks.txt dates are correct (`workspace-dustin/data/payroll-weeks.txt`)
- [ ] Review first Ed call prep — adjust sections if needed
- [ ] Confirm Jira project keys are correct
- [ ] Confirm Monday.com board IDs are loaded correctly

---

## ⚠️ EXPLICITLY NOT AUTOMATED (by Dustin's request)

- Email sending: **always requires Dustin's manual approval** (draft + confirm)
- Payroll submission: **HITL gate — agent never submits**
- Invoice approval: **agent audits and presents, never approves**
- Sharing any data outside @boldbusiness.com or @mercuryz.com: **explicit approval required**

---

## 📊 Success Metrics (2-week review)

| Metric | Target |
|--------|--------|
| Morning brief delivery | 7:00am ±5min, Mon–Fri |
| Pre-meeting briefs on time | All 18 cron jobs firing on schedule |
| Invoice queue on Tuesday | Ready before 9am meeting |
| Ed call prep quality | Dustin needs no additional prep |
| Team tracker accuracy | <1 missed overdue item per week |
| False positive alerts | <3 per week |
| Time saved on report prep | Dustin reports >2h/week saved |

---

## 📞 Support

If D1 is not working:
- AlphaClaw UI → **Watchdog** tab → check gateway status
- Coolify → Service → **Logs** → look for errors
- Contact Jewel Nurunnabi · mnurunnabi@boldbusiness.com
- Recovery chain for agent mistakes: Dustin → Ed Kopko → Earmiel → Vina
