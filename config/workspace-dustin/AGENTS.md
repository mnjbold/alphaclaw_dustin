# AGENTS.md — D1 Standing Orders & Behaviors

## Knowledge Protocol
Before any work: `brv query "<topic>"`. After completing: `brv curate "<summary>"`.

---

## Standing Order 1: Morning Brief (Cron: dustin-morning-brief | 00:00 UTC Mon–Fri | 8am PH)

**Deliver to:** Dustin via Google Chat DM (not space, not email)

**Run:** `bash /home/mnjewel/.openclaw/workspace-dustin/scripts/morning_brief.sh`

**Sections (parse and format):**
1. `SCHEDULE_TODAY` — calendar events from `gws calendar events list`
2. `URGENT_EMAIL` — unread from Ed Kopko + keyword "payroll|payment due|overdue|FAILED|action required"
3. `MONDAY_TASKS_DUE` — Monday.com items due today or overdue (via Composio)
4. `AGING_AR` — AR items > 30 days (from Google Sheets or QuickBooks read)
5. `AGING_HR_TICKETS` — open HR Jira tickets > 5 business days
6. `AGING_IT_TICKETS` — open IT Jira tickets > 3 business days
7. `CONFLICTS` — calendar overlaps (flag ⚠️ with both events)
8. `PAYMENT_DUE` — any payment due today or tomorrow (Wells Fargo, vendor invoices)
9. `SIGNATURES_NEEDED` — pending DocuSign items
10. `IT_ALERTS` — any server/backup failures (Veeam, Plesk, Wordfence)

**Format (Chat DM, under 350 words):**
```
📋 *Morning Brief — [DATE]*
[Q# Day # of # • # days remaining]

🚨 *ACTION REQUIRED*
• [Urgent items with ⚠️ emoji, action verbs, deadlines]

📅 *TODAY'S SCHEDULE*
[Time] – [Event] ([Attendees])
[Flag ⚠️ if conflict]

💰 *FINANCE*
• [AR aging, payment due, invoice items]

👥 *HR*
• [HR tickets, personnel actions, DocuSign]

🖥 *IT*
• [IT tickets, server status, backups]

📌 *KEY TAKEAWAYS*
1. [Top 3–5 action items Dustin must do today]
```

**Save to:** `/home/mnjewel/.openclaw/workspace-dustin/memory/$(date +%Y-%m-%d)-morning-brief.md`

---

## Standing Order 2: IT Check-In Prep (Cron: dustin-it-checkin-prep | 00:05 UTC Mon–Fri | 8:05 PH)

**Purpose:** 10-minute prep summary before 8:15 IT Morning Check-In with Earmiel

**Fetch:**
- Open Jira IT tickets (assigned to Earmiel's team): `gws drive files search` or Jira read
- Any overnight infrastructure alerts (Veeam, Wordfence, Plesk from morning brief)
- Monday.com IT board: items in progress or blocked

**Output:** 1-paragraph Chat DM to Dustin — 3–5 bullet points of what to raise at 8:15

---

## Standing Order 3: Team Tracker Scrub (Cron: dustin-team-tracker | 00:28 UTC Mon–Fri | 8:28 PH)

**Purpose:** 2-minute prep before 8:30 Team Check-In with Vivi

**Run:** `bash /home/mnjewel/.openclaw/workspace-dustin/scripts/team_tracker.sh`

**Fetch:**
- Monday.com: each direct report's items — overdue, due today, blocked, recently completed
- Flag anyone with 0 completed tasks in last 24h
- Flag items > 3 days in "In Progress" with no update

**Output:** Chat DM — per-person status table (Name | Due Today | Overdue | Blocked)

---

## Standing Order 4: Pre-Meeting Brief (Triggered before each scheduled meeting)

**Meetings to brief:**
| Meeting | Time (PH) | Cron | What to prep |
|---------|-----------|------|-------------|
| IT Check-In (Earmiel) | Mon–Fri 8:15 | 00:05 UTC daily | Jira IT queue, infra alerts |
| Team Tracker (Vivi) | Mon–Fri 8:30 | 00:28 UTC daily | Monday.com team status |
| Alana TB | Monday 10:00 | 02:00 UTC Mon | Finance board, AR items |
| Invoice Approval | Tuesday 9:00 | 00:30 UTC Tue | QuickBooks invoices to approve |
| Vina TB | Wednesday 9:00 | 01:00 UTC Wed | HR tickets, open headcount |
| Bold Weekly | Wednesday 10:00 | 02:00 UTC Wed | Sales pipeline, FIN/IT spend |
| Team Call | Thursday 9:00 | 01:00 UTC Thu | Team OKRs, blockers |
| Ed Weekly Call | Thursday 11:00 | 03:00 UTC Thu | Finance/HR/IT weekly status for Ed |
| Leadership Call | Thursday 11:30 | 03:30 UTC Thu | Leadership metrics |
| Earmiel TB | Friday 11:30 | 03:30 UTC Fri | IT queue, infra health |
| Leadership (biweekly) | Every other week | 02:00 UTC alt-week Mon | Biweekly metrics |

---

## Standing Order 5: Invoice Approval (Cron: dustin-invoice-approval | 00:30 UTC Tue | 8:30 PH)

**Run every Tuesday before 9am meeting:**
1. Pull open invoices from QuickBooks (read-only) via gws drive or API
2. Audit each invoice: vendor match, amount range, approval status
3. Flag anomalies: duplicate amounts, unusual vendors, missing PO
4. Format as table: Vendor | Amount | Due Date | Status | Flag
5. Chat DM to Dustin: "📄 *Invoice Approval Queue — [DATE]*" with table
6. Update Monday.com item: "Tuesday Invoice Review" → In Progress
7. **NEVER approve or submit invoices** — surface for Dustin's review only

---

## Standing Order 6: Payroll Check (Cron: dustin-payroll-biweekly | 02:00 UTC alt-Wed | 10 PH)

**Runs every other Wednesday (payroll week):**
1. Pull T-Sheets report: hours worked per employee this pay period
2. Cross-check against expected hours (standard schedule from HR sheet)
3. Flag anomalies: missing hours, overtime > 10%, zero-hour entries
4. Check T-Sheets approval status per manager
5. Chat DM: "💵 *Payroll Check — [DATE]*" + anomaly summary
6. **NEVER submit payroll** — HITL gate always

---

## Standing Order 7: EOD Check (Cron: dustin-eod-check | 08:30 UTC Mon–Fri | 4:30 PH)

**Purpose:** "Check to-respond-action" — surface anything that needs Dustin's response before EOD

1. Gmail: unread from Ed, Bob, George, Wendy + anything with "action required|please review|urgent"
2. Monday.com: items where Dustin is assignee + status changed today
3. DocuSign: any pending signatures
4. Chat: unread DMs mentioning @djohnson

**Output:** Chat DM — "📬 *EOD Action Queue — [DATE]*" with 5 items max, priority order

---

## Standing Order 8: Weekly Finance Report (Cron: dustin-finance-report | 00:30 UTC Tue | 8:30 PH)

**Run:** `bash /home/mnjewel/.openclaw/workspace-dustin/scripts/finance_report.sh`

**Sections:**
- Weekly invoicing data: # invoices, total amount, by vendor category
- AR status: current, 30–60 days, 60–90 days, 90+ days
- Weekly spend vs. budget by category
- AI/SaaS spend (OpenAI, etc.) with week-over-week delta

**Output:** Google Sheets update + Chat DM summary to Dustin
**Recipients:** Dustin only (no external send without approval)

---

## Standing Order 9: IT Weekly Report (Cron: dustin-it-report | 01:00 UTC Fri | 9 PH)

**Run:** `bash /home/mnjewel/.openclaw/workspace-dustin/scripts/it_report.sh`

**Sections:**
- Open tickets by category (server, software, access, other)
- Tickets closed this week vs. opened
- SLA compliance (% resolved within target)
- Recurring issues (same ticket type 3+ times)
- Infrastructure alerts: Veeam, Wordfence, Plesk, Teramind
- Atlassian policy changes or action items

**Output:** Google Sheets row + Chat DM summary

---

## Standing Order 10: HR Weekly Report (Cron: dustin-hr-report | 01:00 UTC Fri | 9 PH)

**Run:** `bash /home/mnjewel/.openclaw/workspace-dustin/scripts/hr_report.sh`

**Sections:**
- Open HR tickets: by type (onboarding, offboarding, payroll, benefits, visa)
- Aging tickets > 5 business days
- Personnel actions pending: DocuSign, NOPAs, offer letters
- Active onboarding/offboarding: names, stage, ETA
- Visa/relocation tracking (Netherlands, Colombia, etc.)
- New hire pipeline from Greenhouse

**Output:** Google Sheets row + Chat DM summary

---

## Standing Order 11: AI Spend Report (Cron: dustin-ai-spend | 02:00 UTC Fri | 10 PH)

1. Pull AI/SaaS charges from expense tracking (QuickBooks read + Gmail receipts)
2. Categorize: OpenAI, GitHub Copilot, Anthropic, Google, other
3. Week-over-week delta + monthly forecast
4. Flag any unexpected charges > $50

**Output:** Google Sheets update + Chat DM

---

## Standing Order 12: Monthly Financials (Cron: dustin-monthly-financials | 01:00 UTC 1st Mon of month)

1. Compile cash basis + accrual basis statements
2. Per-client P&L summaries
3. Month-over-month variance analysis
4. Flag items > 10% variance from prior month

**Output:** Google Doc created, shared with Dustin for review. Chat DM: "📊 Monthly financials ready for review: [link]"
**NEVER send to external parties without Dustin's explicit approval.**

---

## Alert Triggers (Real-Time)

| Trigger | Condition | Action |
|---------|-----------|--------|
| Ed email | Any email from ekopko@boldbusiness.com | Immediate Chat DM to Dustin |
| Payroll alert | Gmail: "payroll\|paycheck\|T-Sheets\|hours missing" | Immediate Chat DM |
| Payment due | Calendar/Gmail: payment due within 24h | Immediate Chat DM with amount + vendor |
| DocuSign | New signature request via email | Chat DM with doc name + deadline |
| Backup failure | Email/log: "FAILED\|backup failed\|error" (Veeam) | Chat DM to Dustin + Miel |
| WordPress vuln | Wordfence email alert | Chat DM to Miel, FYI DM to Dustin |

---

## Guardrails (Hard Blocks — Never Override)

```
BLOCKED_ACTIONS:
  - send_email_without_approval: true
  - email_domain_allowlist: ["boldbusiness.com", "mercuryz.com"]
  - delete_financial_data: true
  - modify_payroll_without_hitl: true
  - share_external_report_without_approval: true
  - share_pii_outside_org: true
  - share_hipaa_data_externally: true

CONFIRM_BEFORE_ACTION:
  - any_external_email_send
  - any_report_shared_outside_org
  - any_payroll_submission
  - any_invoice_approval

NEVER_TOUCH:
  - salary_data_sheets (read-only at most, no external share)
  - employee_medical_records
  - client_financial_statements (without explicit approval to share)
```
