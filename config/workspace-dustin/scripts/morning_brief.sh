#!/bin/bash
# D1 Morning Brief — runs at 00:00 UTC (8am PH) Mon-Fri
# Outputs sections: SCHEDULE_TODAY, URGENT_EMAIL, AGING_AR, AGING_HR_TICKETS, AGING_IT_TICKETS,
#                   CONFLICTS, PAYMENT_DUE, SIGNATURES_NEEDED, IT_ALERTS, MONDAY_TASKS_DUE

GWS=~/.npm-global/bin/gws
TODAY=$(date -u +%Y-%m-%d)
TODAY_MIN="${TODAY}T00:00:00+08:00"
TODAY_MAX="${TODAY}T23:59:59+08:00"

echo "=== SCHEDULE_TODAY ==="
$GWS calendar events list \
  --params "{\"calendarId\":\"primary\",\"timeMin\":\"$TODAY_MIN\",\"timeMax\":\"$TODAY_MAX\",\"singleEvents\":true,\"orderBy\":\"startTime\"}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
items = data.get('items', [])
if not items:
    print('No events today.')
else:
    for e in items:
        start = e.get('start',{}).get('dateTime', e.get('start',{}).get('date','?'))
        time_str = start[11:16] if 'T' in start else start
        title = e.get('summary','(no title)')
        attendees = [a.get('email','') for a in e.get('attendees',[])][:3]
        att_str = ', '.join(attendees) if attendees else ''
        print(f'{time_str} – {title}' + (f' ({att_str})' if att_str else ''))
" 2>/dev/null || echo "Calendar: unavailable"

echo ""
echo "=== URGENT_EMAIL ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"is:unread (from:ekopko@boldbusiness.com OR subject:payroll OR subject:\\\"payment due\\\" OR subject:FAILED OR subject:\\\"action required\\\" OR subject:\\\"please sign\\\")\",\"maxResults\":10}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages', [])
if not msgs:
    print('No urgent emails.')
else:
    print(f'{len(msgs)} urgent email(s) found — IDs: ' + ', '.join(m.get(\"id\",\"?\") for m in msgs[:5]))
" 2>/dev/null || echo "Gmail: unavailable"

echo ""
echo "=== PAYMENT_DUE ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"is:unread (subject:\\\"payment due\\\" OR subject:\\\"due tomorrow\\\" OR subject:\\\"invoice due\\\" OR from:wellsfargo) newer_than:2d\",\"maxResults\":5}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages', [])
if not msgs:
    print('No payment due alerts.')
else:
    print(f'{len(msgs)} payment alert(s) — check Gmail')
" 2>/dev/null || echo "Payment check: unavailable"

echo ""
echo "=== SIGNATURES_NEEDED ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"is:unread from:docusign.com\",\"maxResults\":5}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages', [])
if not msgs:
    print('No pending DocuSign requests.')
else:
    print(f'{len(msgs)} DocuSign item(s) pending signature')
" 2>/dev/null || echo "DocuSign: unavailable"

echo ""
echo "=== IT_ALERTS ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"is:unread (from:veeam OR subject:\\\"backup failed\\\" OR subject:FAILED OR from:wordfence OR subject:vulnerability) newer_than:1d\",\"maxResults\":10}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages', [])
if not msgs:
    print('No IT alerts.')
else:
    print(f'🔴 {len(msgs)} IT alert(s) — check immediately')
" 2>/dev/null || echo "IT alerts: unavailable"

echo ""
echo "=== MONDAY_TASKS_DUE ==="
# Monday.com integration via Composio (mcporter)
mcporter call composio.MONDAY_GET_ITEMS --args '{"board_id":"auto","filter":"due_today_or_overdue"}' 2>/dev/null || echo "Monday.com: unavailable — check manually"

echo ""
echo "=== AGING_AR ==="
echo "AR aging: pull from QuickBooks or Finance sheet — manual check required until QuickBooks API configured"

echo ""
echo "=== AGING_HR_TICKETS ==="
mcporter call composio.JIRA_GET_ALL_ISSUES \
  --args '{"jql":"project=HR AND status!=Done AND created<=-5d","maxResults":10}' 2>/dev/null || \
  echo "HR tickets: Jira unavailable — check manually"

echo ""
echo "=== AGING_IT_TICKETS ==="
mcporter call composio.JIRA_GET_ALL_ISSUES \
  --args '{"jql":"project=ISD AND status!=Done AND created<=-3d","maxResults":10}' 2>/dev/null || \
  echo "IT tickets: Jira unavailable — check manually"

echo ""
echo "=== CONFLICTS ==="
# Detect overlapping calendar events
$GWS calendar events list \
  --params "{\"calendarId\":\"primary\",\"timeMin\":\"$TODAY_MIN\",\"timeMax\":\"$TODAY_MAX\",\"singleEvents\":true,\"orderBy\":\"startTime\"}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
from datetime import datetime
data = json.load(sys.stdin)
items = data.get('items', [])
conflicts = []
for i in range(len(items)-1):
    e1, e2 = items[i], items[i+1]
    end1 = e1.get('end',{}).get('dateTime','')
    start2 = e2.get('start',{}).get('dateTime','')
    if end1 and start2 and end1 > start2:
        conflicts.append(f'⚠️ CONFLICT: {e1.get(\"summary\",\"?\")} overlaps {e2.get(\"summary\",\"?\")}')
if not conflicts:
    print('No calendar conflicts detected.')
else:
    for c in conflicts:
        print(c)
" 2>/dev/null || echo "Conflict check: unavailable"
