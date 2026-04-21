# D1 Agent Onboarding Checklist — Dustin Johnson
**Generated:** 2026-04-21 | **Based on:** BAIIT Onboarding Questionnaire v1.0  
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
- [x] Model: `claude-Opus+sonnet-4.6` (977k ctx, finance reasoning)
- [x] Heartbeat: every 30min, 8am–5pm PH, lightContext + isolatedSession
- [x] Workspace files: IDENTITY, SOUL, USER, AGENTS, TOOLS, HEARTBEAT, MODELS, BOOT

### Automations & Cron (18 jobs — all in `config/cron-jobs.json`)
- [x] Morning Brief — 7:00am PH daily (calendar, AR, HR(MONDAY)/IT tickets(JIRA), payments(Email), alerts (email +chat))
- [x] IT Check-in Prep — 8:05am PH daily (before Earmiel 8:15) ( EMAIL + PULL JIRA TICKET - HIghlets anything critacl + meeting prep)
- [x] Team Tracker Scrub — 8:28am PH daily (before Vivi 8:30) ( Overview Dashboard)
- [x] Monday Alana TB Prep — 10:00am Monday ( 1 one 1 meeting and meeting prep, ar ,client followups)
- [x] Invoice Approval Queue — 8:30am Tuesday (audit, never auto-approve)
- [x] Vina HR TB Prep — 9:00am Wednesday (audit, never auto-approve)
- [x] Bold Weekly Sales Call Prep — 10:00am Wednesday ( Meeting Prep - if can focus on Justin Slides + Prepa about topic discuss)
- [x] Biweekly Payroll Check — 10:00am alt-Wednesday (T-Sheets audit, HITL) ( Check with DUSTIN - every 2nd week of biweekly wednesday , check with Dustin on previous week)  for biweekly , to do trend analysis and send overview to Dustin and ED, no counting. 
- [x] Thursday Team Call Prep — 9:00am Thursday (general meeting , agent to look thorugh meeting notes for any actionalable information and confirm with Dustin if requiree any actions for them)
- [x] Ed Weekly Call Prep — 11:00am Thursday (Finance+HR+IT exec summary) [ REPORT GET FORM TEAM ON WEDNSDAY AND DISCUSS ON THURSDAY WITH ED, EXPECT TO AHVE ANALAYSIS AND INSIGNTS TO DISCUSS WITH ED )
- [x] Leadership Call Prep — 11:30am Thursday [ CHECK MONDAY BOARD COMPARE PREVIOUS WEEKS TASKS , AND CREATE VALIDATIONS, CHECK LISTS, AND TOPIC PREP AND FOLLOW UP )
- [x] EOD Action Check — 4:30pm PH daily (unresponded, DocuSign queue) [From email groped item create action chek items lists and update , Create actions items on monday and weekly feed back followup loop for a month to check on the tasks ouput , send this via email & google chat] 
- [x] EOD Summary — 5:00pm PH daily [ SEND AS DASHBAORD UPDATE REPORTS, AS WELL AS DAILY REPORTS TO BE SAVED IN A FOLDER - UPDATE]
- [x] IT Weekly Report — 9:00am Friday (Jira tickets, infra, Teramind) FOLLOW EOD SUMMURY
- [x] HR Weekly Report — 9:05am Friday (tickets, aging, Greenhouse, visa) FOLLOW EOD SUMMURY
- [x] AI Spend Weekly — 10:00am Friday  [ Ai Spend TO GET FROM JIRA & MONDAY AND GET INSIGHT AND REPORTS, AND CRETATE A TRACKER] 
- [x] Earmiel TB Prep — 11:30am Friday [ FROM JIRA TICKETS & PAST MEETING MINUTES]
- [x] Monthly Financials — 9:00am 1st of month (cash+accrual+client P&Ls) [ BY THE 2ND MONDAY TO INFORM N REMIND TEAM TO PREPARE FINANCIAL REPORTS OF MONTHLY , AND BY 3RD MONDAY OF THE OF THE MONTH TO SEND ANALYSIS AND SHARE WITH DUSTIN. 

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
- [x] `.env.example` — all required Coolify variables listed
- [x] `COOLIFY_SETUP.md` — step-by-step 10-step deploy guide

### Tool Access (configured in AGENTS.md)
- [x] Gmail: send (draft+approve only), read, search
- [x] Google Calendar: read
- [x] Google Drive: read + search
- [x] Google Sheets: read + write (reports)
- [x] Google Chat: send DMs
- [x] Monday.com: read + create/move items ( MONDAY BOARD API KEY)
- [x] QuickBooks: read + create invoices (HITL) (MCP QUICKBOOK) 
- [x] T-Sheets: pull reports (read)
- [x] Jira: read tickets
- [x] DocuSign: read pending signatures

### Communication Preferences
- [x] Urgent/reports: Google Chat DM
- [x] Status updates: Monday.com
- [x] FYI/async: Email (draft, never auto-send)
- [x] Tone: Conversational but professional (in SOUL.md)
- [x] Recovery chain: Dustin → Ed → Earmiel → Vina

---

## ⏳ PENDING — Requires Dustin's action

### Authentication (must be done by Dustin personally)
- [ ] **GitHub Copilot auth** — AlphaClaw UI → Models → GitHub Copilot → Auth
  - Needed for: claude-sonnet-4.6 model access
  - Account: djohnson@boldbusiness.com GitHub

- [ ] **Google Workspace auth** — AlphaClaw UI → Google → Add Account
  - Sign in as: djohnson@boldbusiness.com
  - Scopes needed: Gmail, Calendar, Drive, Sheets, Docs, Tasks, Contacts, Meet
  - After this: `gws auth status` should show Valid: true

### Google Chat Setup
- [ ] **Google Cloud Console — set Chat app URL**
  - URL: `https://YOUR-COOLIFY-DOMAIN/googlechat`
  - Location: console.cloud.google.com → `gen-lang-client-0768862569` → Google Chat API → Configuration
  - Contact Jewel if you don't have access to this project

- [ ] **Add bijouclaw bot to your Google Chat**
  - Open Google Chat → Search for `bijouclaw@gen-lang-client-0768862569.iam.gserviceaccount.com`
  - Start a DM
  - Note the chat user/space ID from the URL
  - Add it as `DUSTIN_CHAT_USER_ID` in Coolify env vars

- [ ] **Test Google Chat delivery**
  - AlphaClaw UI → Channels → Google Chat → Test Connection
  - Then trigger a manual brief: AlphaClaw UI → Cron → dustin-morning-brief → Run Now

### Coolify Deployment Steps
- [ ] Set `ALPHACLAW_BASE_URL` = your Coolify domain before first deploy
- [ ] Add `GOOGLE_CHAT_SERVICE_ACCOUNT_B64` (get base64 from Jewel)
- [ ] Add `GOOGLE_OAUTH_CLIENT_B64` (get base64 from Jewel)
- [ ] Add persistent volume: `/app/.openclaw` → `d1-openclaw-data`
- [ ] Deploy and check boot logs for `[d1-boot]` messages

### Integration API Keys (add to Coolify env vars)
- [ ] `MONDAY_API_KEY` — Monday.com → Profile → API → Generate
- [ ] `JIRA_API_TOKEN` — id.atlassian.com → Security → API tokens
- [ ] `DUSTIN_FINANCE_SHEET_ID` — Google Sheets URL → copy the ID
- [ ] `DUSTIN_IT_SHEET_ID` — Google Sheets URL → copy the ID
- [ ] `DUSTIN_HR_SHEET_ID` — Google Sheets URL → copy the ID
- [ ] `QUICKBOOKS_CLIENT_ID` + `QUICKBOOKS_CLIENT_SECRET` — Intuit Developer Portal
- [ ] `TSHEETS_API_KEY` — QuickBooks Time → Company Settings → API Tokens

### Cron Delivery Target
- [ ] Update `DUSTIN_CHAT_USER_ID` in Coolify env vars with Dustin's actual Chat user ID
  - This is the `users/XXXXXXXXX` ID from Dustin's Google Chat DM URL
  - Without this, cron jobs generate output but can't send it to Chat

### Review & Calibration (first 2 weeks)
- [ ] Confirm morning brief format matches expectations (adjust template in AGENTS.md)
- [ ] Confirm invoice audit format works for Tuesday meeting
- [ ] Confirm payroll-weeks.txt dates are correct (`workspace-dustin/data/payroll-weeks.txt`)
- [ ] Review first Ed call prep — adjust sections if needed
- [ ] Confirm Jira project keys are correct (currently: `ISD` for IT, `HR` for HR)
- [ ] Confirm Monday.com board IDs for finance, IT, HR boards

---

## ⚠️ EXPLICITLY NOT AUTOMATED (by Dustin's request)

- Email sending: **always requires Dustin's manual approval** (draft + confirm)
- Payroll submission: **HITL gate — agent never submits**
- Invoice approval: **agent audits and presents, never approves**
- Sharing any data outside @boldbusiness.com or @mercuryz.com: **explicit approval required**

---

## 📊 Success Metrics (2-week review)

Track these to know if D1 is working:

| Metric | Target |
|--------|--------|
| Morning brief delivery | 8:00am ±5min, Mon–Fri |
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
- Contact Jewel (Nurunnabi) for infrastructure issues
- Recovery chain for agent mistakes: Dustin → Ed Kopko → Earmiel → Vina
