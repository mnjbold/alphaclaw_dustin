# TOOLS.md — D1 Tool Access Reference

## Write Access (Dustin-authorized)

| Tool | Access | How |
|------|--------|-----|
| Gmail | Send (draft+approve only) | `gws gmail users.messages send` — NEVER without approval |
| Google Chat | Send DMs | `openclaw message send --channel googlechat` |
| Google Sheets | Read + Write | `gws sheets spreadsheets.values update` |
| Monday.com | Read + Create/Move items | Composio MONDAY_CREATE_ITEM, MONDAY_CHANGE_STATUS |
| QuickBooks | Read + Create invoices | Via Composio or API — CREATE requires approval |
| T-Sheets | Pull reports (read) | Via API or export — read only |

## Read-Only Access

| Tool | Access | How |
|------|--------|-----|
| Google Calendar | Read | `gws calendar events list` |
| Jira | Read tickets | `gws drive files search` or Jira API read |
| Google Drive | Read + search | `gws drive files list` |
| Google Docs | Read | `gws docs documents get` |
| Gmail | Read/search | `gws gmail users.messages list` |
| Dropbox | Read files | Via API — read only |
| DocuSign | Read pending signatures | Via email parsing or API |
| Teramind | Read alerts | Via email parsing |
| Veeam | Read backup status | Via email parsing |

## Explicitly Off-Limits

- GitHub (no access)
- iMessage, WhatsApp (no integration — monitor only via forwarding if set up)
- Salary spreadsheets (read max, never modify, never share externally)
- Employee medical/HIPAA records (read max, never share)
- Client financials (never share without Dustin's explicit confirmation)

## Tool Auth Status

| Tool | Auth Method | Status |
|------|-------------|--------|
| Gmail/Calendar/Drive/Sheets | gws auth (OAuth2) | ⚠️ Pending `gws auth login` |
| Google Chat | Service account | ✓ Configured (see openclaw.json) |
| Monday.com | Composio/mcporter | Check mcporter status |
| QuickBooks | API key | Configure in .env |
| T-Sheets | API key | Configure in .env |

## gws CLI Quick Reference

```bash
GWS=~/.npm-global/bin/gws

# Gmail
$GWS gmail users.messages list --params '{"userId":"me","q":"is:unread from:ekopko@boldbusiness.com","maxResults":5}'

# Calendar (today)
TODAY=$(date -u +%Y-%m-%dT00:00:00Z); TOMORROW=$(date -u -d tomorrow +%Y-%m-%dT00:00:00Z)
$GWS calendar events list --params "{\"calendarId\":\"primary\",\"timeMin\":\"$TODAY\",\"timeMax\":\"$TOMORROW\",\"singleEvents\":true,\"orderBy\":\"startTime\"}"

# Sheets write
$GWS sheets spreadsheets.values update \
  --params '{"spreadsheetId":"SHEET_ID","range":"Sheet1!A1","valueInputOption":"RAW"}' \
  --json '{"values":[["col1","col2"]]}'

# Drive search
$GWS drive files list --params '{"q":"name contains '\''Invoice'\'' and trashed=false","pageSize":10}'
```
