#!/bin/bash
# D1 EOD Action Check — runs 08:30 UTC (4:30pm PH) Mon-Fri
# Surfaces: unresponded items that need Dustin's attention before EOD

GWS=~/.npm-global/bin/gws

echo "=== UNRESPONDED_EMAIL ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"is:unread (from:ekopko@boldbusiness.com OR from:bob@mercuryz.com OR from:george@mercuryz.com OR from:wtoll@boldbusiness.com OR subject:\\\"action required\\\" OR subject:\\\"please review\\\" OR subject:urgent) \",\"maxResults\":10}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
if not msgs:
    print('No unresponded priority emails.')
else:
    print(f'{len(msgs)} email(s) needing response:')
    for m in msgs[:5]:
        print(f'  ID: {m.get(\"id\",\"?\")}')
" 2>/dev/null || echo "Gmail: unavailable"

echo ""
echo "=== DOCUSIGN_OUTSTANDING ==="
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"from:docusign.com is:unread\",\"maxResults\":5}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
if not msgs:
    print('No outstanding DocuSign.')
else:
    print(f'⚠️ {len(msgs)} DocuSign item(s) still pending')
" 2>/dev/null || echo "DocuSign: unavailable"

echo ""
echo "=== MONDAY_ASSIGNED_TO_DUSTIN ==="
mcporter call composio.MONDAY_GET_ITEMS \
  --args '{"assignee":"djohnson","status":"not_done","changed_today":true}' 2>/dev/null || \
  echo "Monday.com: unavailable"

echo "=== END EOD CHECK ==="
