#!/bin/bash
# D1 IT Weekly Report — runs Fri 01:00 UTC (9am PH)

GWS=~/.npm-global/bin/gws
REPORT_DATE=$(date -u +%Y-%m-%d)

echo "=== IT_TICKETS_OPEN ==="
mcporter call composio.JIRA_GET_ALL_ISSUES \
  --args '{"jql":"project=ISD AND status!=Done ORDER BY created DESC","maxResults":20}' 2>/dev/null || \
  echo "Jira: unavailable — check manually at jira.boldbusiness.com"

echo ""
echo "=== IT_TICKETS_CLOSED_THIS_WEEK ==="
mcporter call composio.JIRA_GET_ALL_ISSUES \
  --args '{"jql":"project=ISD AND status=Done AND resolutiondate>=-7d","maxResults":20}' 2>/dev/null || \
  echo "Closed tickets: unavailable"

echo ""
echo "=== INFRA_ALERTS_THIS_WEEK ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"(from:veeam OR subject:FAILED OR subject:\\\"backup failed\\\" OR from:wordfence OR subject:vulnerability) newer_than:7d\",\"maxResults\":15}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
print(f'Infrastructure alerts this week: {len(msgs)}')
for m in msgs[:10]:
    print(f'  ID: {m.get(\"id\",\"?\")}')
" 2>/dev/null || echo "Infra alerts: unavailable"

echo ""
echo "=== TERAMIND_SUMMARY ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"from:teramind newer_than:7d\",\"maxResults\":5}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
print(f'Teramind reports this week: {len(msgs)}')
" 2>/dev/null || echo "Teramind: unavailable"

echo ""
echo "REPORT_DATE: $REPORT_DATE"
echo "=== END IT REPORT ==="
