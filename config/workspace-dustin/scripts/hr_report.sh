#!/bin/bash
# D1 HR Weekly Report — runs Fri 01:00 UTC (9am PH)

GWS=~/.npm-global/bin/gws
REPORT_DATE=$(date -u +%Y-%m-%d)

echo "=== HR_TICKETS_OPEN ==="
mcporter call composio.JIRA_GET_ALL_ISSUES \
  --args '{"jql":"project=HR AND status!=Done ORDER BY created DESC","maxResults":20}' 2>/dev/null || \
  echo "HR Jira: unavailable"

echo ""
echo "=== HR_AGING_TICKETS ==="
mcporter call composio.JIRA_GET_ALL_ISSUES \
  --args '{"jql":"project=HR AND status!=Done AND created<=-5d","maxResults":10}' 2>/dev/null || \
  echo "Aging HR tickets: unavailable"

echo ""
echo "=== DOCUSIGN_PENDING ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"from:docusign.com is:unread\",\"maxResults\":10}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
if not msgs:
    print('No pending DocuSign signatures.')
else:
    print(f'{len(msgs)} DocuSign item(s) pending')
    for m in msgs:
        print(f'  ID: {m.get(\"id\",\"?\")}')
" 2>/dev/null || echo "DocuSign: unavailable"

echo ""
echo "=== GREENHOUSE_NEW_CANDIDATES ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"from:notifications@greenhouse.io newer_than:7d\",\"maxResults\":10}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
print(f'Greenhouse notifications this week: {len(msgs)}')
" 2>/dev/null || echo "Greenhouse: unavailable"

echo ""
echo "=== VISA_RELOCATION_TRACKING ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"(subject:visa OR subject:relocation OR subject:Netherlands OR subject:Colombia) newer_than:14d\",\"maxResults\":5}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
print(f'Visa/relocation emails (14d): {len(msgs)}')
" 2>/dev/null || echo "Visa/relocation tracking: unavailable"

echo ""
echo "REPORT_DATE: $REPORT_DATE"
echo "=== END HR REPORT ==="
