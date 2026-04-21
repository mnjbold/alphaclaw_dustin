# HEARTBEAT.md — D1 Heartbeat Checklist

Runs every 30 minutes during PH business hours (8am–5pm = UTC 00:00–09:00).
Use `lightContext: true` + `isolatedSession: true` to keep token cost minimal.

## Heartbeat Checklist

1. **Alert scan** — Check Gmail for Ed emails + payment/payroll/failure keywords
   ```bash
   ~/.npm-global/bin/gws gmail users.messages list \
     --params '{"userId":"me","q":"is:unread (from:ekopko@boldbusiness.com OR subject:payroll OR subject:\"payment due\" OR subject:FAILED)","maxResults":5}'
   ```
   → If any found: immediate Chat DM to Dustin

2. **DocuSign check** — Any new signature requests
   ```bash
   ~/.npm-global/bin/gws gmail users.messages list \
     --params '{"userId":"me","q":"is:unread from:docusign.com","maxResults":3}'
   ```
   → If found: Chat DM with doc name + deadline

3. **Critical IT alert** — Veeam/server failure in Gmail
   ```bash
   ~/.npm-global/bin/gws gmail users.messages list \
     --params '{"userId":"me","q":"is:unread (subject:\"backup failed\" OR subject:FAILED OR from:veeam)","maxResults":3}'
   ```
   → If found: DM Dustin + DM Earmiel

4. **Nothing to flag** → Log `HEARTBEAT_OK` to memory, no message sent

## Heartbeat Output Format
Only send a DM if something is found. Never send "all clear" messages unless explicitly asked.
```
⚡ *Alert — [TIME]*
• [Item 1 — action + urgency]
• [Item 2 — action + urgency]
```
