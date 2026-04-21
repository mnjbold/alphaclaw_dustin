#!/bin/bash
# D1 Weekly Finance Report — runs Tue 00:30 UTC (8:30am PH)
# Output: Google Sheets update + Chat DM summary

GWS=~/.npm-global/bin/gws
REPORT_DATE=$(date -u +%Y-%m-%d)
WEEK_AGO=$(date -u -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-7d +%Y-%m-%d)

echo "=== WEEKLY_INVOICE_DATA ==="
# Search for invoice-related emails this week
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"subject:invoice newer_than:7d\",\"maxResults\":20}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
print(f'Invoice emails this week: {len(msgs)}')
print('IDs:', ', '.join(m.get(\"id\",\"?\") for m in msgs[:5]))
" 2>/dev/null || echo "Invoice data: Gmail unavailable"

echo ""
echo "=== AR_STATUS ==="
# Pull from QuickBooks / Finance Google Sheet (configure FINANCE_SHEET_ID)
FINANCE_SHEET_ID="${DUSTIN_FINANCE_SHEET_ID:-CONFIGURE_ME}"
if [ "$FINANCE_SHEET_ID" != "CONFIGURE_ME" ]; then
    $GWS sheets spreadsheets.values get \
      --params "{\"spreadsheetId\":\"$FINANCE_SHEET_ID\",\"range\":\"AR!A1:F100\"}" \
      --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
rows = data.get('values',[])
print(f'AR rows: {len(rows)}')
for r in rows[:5]:
    print(' | '.join(str(c) for c in r))
" 2>/dev/null || echo "Finance sheet: unavailable"
else
    echo "AR: FINANCE_SHEET_ID not configured — check manually in QuickBooks"
fi

echo ""
echo "=== AI_SPEND ==="
# Search for SaaS/AI invoices
$GWS gmail users.messages list \
  --params "{\"userId\":\"me\",\"q\":\"(from:billing.openai.com OR from:github.com OR from:anthropic.com OR subject:\\\"invoice\\\" subject:\\\"AI\\\") newer_than:7d\",\"maxResults\":10}" \
  --format json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
msgs = data.get('messages',[])
print(f'AI/SaaS billing emails: {len(msgs)}')
for m in msgs[:5]:
    print(f'  ID: {m.get(\"id\",\"?\")}')
" 2>/dev/null || echo "AI spend: unavailable"

echo ""
echo "REPORT_DATE: $REPORT_DATE"
echo "=== END FINANCE REPORT ==="
