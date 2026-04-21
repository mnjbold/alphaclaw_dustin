#!/usr/bin/env bash
# =============================================================================
# D1 Agent Database Setup — Google Sheets via gws CLI
# Agent: D1 (Dustin Johnson — Finance / HR / IT Head at Bold Business)
# Created: 2026-04-22
# Usage: bash setup_databases.sh
# Requires: gws CLI at ~/.npm-global/bin/gws, authenticated via `gws auth login`
# =============================================================================

set -euo pipefail

GWS="$HOME/.npm-global/bin/gws"

# --------------------------------------------------------------------------- #
# 0. Guard: check gws exists and is authenticated
# --------------------------------------------------------------------------- #
if [[ ! -x "$GWS" ]]; then
  echo "ERROR: gws not found at $GWS"
  echo "Install: npm install -g @alexi/gws"
  exit 1
fi

echo "Checking gws auth status..."
if ! "$GWS" auth status 2>&1 | grep -q "Authenticated"; then
  echo "ERROR: gws is not authenticated. Run: $GWS auth login"
  exit 1
fi
echo "gws authenticated."
echo ""

# --------------------------------------------------------------------------- #
# 1. Create Google Drive folder: D1 Agent Databases
# --------------------------------------------------------------------------- #
echo "Creating Google Drive folder: D1 Agent Databases..."

FOLDER_RESPONSE=$("$GWS" drive files create \
  --fields "id,name" \
  --body '{
    "name": "D1 Agent Databases",
    "mimeType": "application/vnd.google-apps.folder"
  }')

FOLDER_ID=$(echo "$FOLDER_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
echo "Folder created — ID: $FOLDER_ID"
echo ""

# --------------------------------------------------------------------------- #
# Helper: create a spreadsheet inside the D1 Agent Databases folder
# Returns the spreadsheet ID on stdout.
# Usage: create_sheet "Title"
# --------------------------------------------------------------------------- #
create_sheet() {
  local TITLE="$1"
  echo "Creating sheet: $TITLE..." >&2

  # Create the file as a Google Sheet in the folder
  local RESPONSE
  RESPONSE=$("$GWS" drive files create \
    --fields "id,name" \
    --body "{
      \"name\": \"$TITLE\",
      \"mimeType\": \"application/vnd.google-apps.spreadsheet\",
      \"parents\": [\"$FOLDER_ID\"]
    }")

  local SHEET_ID
  SHEET_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
  echo "  Sheet ID: $SHEET_ID" >&2
  echo "$SHEET_ID"
}

# --------------------------------------------------------------------------- #
# Helper: set headers on a tab (sheet) inside a spreadsheet.
# The first tab (index 0) is always created by Google as "Sheet1".
# For subsequent tabs we rename via batchUpdate first, then write headers.
#
# Usage: set_headers SPREADSHEET_ID SHEET_GID TAB_TITLE "Col1|Col2|Col3"
# Note: SHEET_GID=0 for the first tab; for new tabs pass the GID returned
#       by addSheet.
# --------------------------------------------------------------------------- #

# Helper: rename Sheet1 (gid=0) to a proper tab name
rename_first_tab() {
  local SPREADSHEET_ID="$1"
  local NEW_TITLE="$2"

  "$GWS" sheets spreadsheets batchUpdate \
    --spreadsheet-id "$SPREADSHEET_ID" \
    --body "{
      \"requests\": [
        {
          \"updateSheetProperties\": {
            \"properties\": {
              \"sheetId\": 0,
              \"title\": \"$NEW_TITLE\"
            },
            \"fields\": \"title\"
          }
        }
      ]
    }" > /dev/null
}

# Helper: add a brand-new tab and return its sheetId (GID)
add_tab() {
  local SPREADSHEET_ID="$1"
  local TAB_TITLE="$2"

  local RESPONSE
  RESPONSE=$("$GWS" sheets spreadsheets batchUpdate \
    --spreadsheet-id "$SPREADSHEET_ID" \
    --body "{
      \"requests\": [
        {
          \"addSheet\": {
            \"properties\": {
              \"title\": \"$TAB_TITLE\"
            }
          }
        }
      ]
    }")

  echo "$RESPONSE" | python3 -c \
    "import sys, json; r=json.load(sys.stdin); print(r['replies'][0]['addSheet']['properties']['sheetId'])"
}

# Helper: write a single header row to a tab
# Usage: write_headers SPREADSHEET_ID "A1:Z1 range" "Col1" "Col2" ...
write_headers() {
  local SPREADSHEET_ID="$1"
  local RANGE="$2"
  shift 2
  local COLS=("$@")

  # Build JSON array of values
  local VALUES_JSON
  VALUES_JSON=$(python3 -c "
import json, sys
cols = sys.argv[1:]
print(json.dumps([[col for col in cols]]))
" "${COLS[@]}")

  "$GWS" sheets spreadsheets values update \
    --spreadsheet-id "$SPREADSHEET_ID" \
    --range "$RANGE" \
    --value-input-option "RAW" \
    --body "{\"values\": $VALUES_JSON}" > /dev/null

  # If gws doesn't support spreadsheets values update, use this curl fallback:
  # SPREADSHEET_URL="https://sheets.googleapis.com/v4/spreadsheets/${SPREADSHEET_ID}/values/${RANGE}?valueInputOption=RAW"
  # TOKEN=$(gws auth token)
  # curl -s -X PUT "$SPREADSHEET_URL" \
  #   -H "Authorization: Bearer $TOKEN" \
  #   -H "Content-Type: application/json" \
  #   -d "{\"values\": $VALUES_JSON}" > /dev/null
}

# --------------------------------------------------------------------------- #
# 2. Create: D1 — Action Items & Reports
# --------------------------------------------------------------------------- #
echo "=== Sheet 1: D1 — Action Items & Reports ==="
ACTIONITEMS_ID=$(create_sheet "D1 — Action Items & Reports")

# Tab 1: ActionItems (rename Sheet1)
rename_first_tab "$ACTIONITEMS_ID" "ActionItems"
write_headers "$ACTIONITEMS_ID" "ActionItems!A1:M1" \
  "ID" "CreatedDate" "Source" "SourceRef" "Title" "Description" \
  "Assignee" "DueDate" "Status" "FollowupDate" "FollowupCount" "ClosedDate" "Notes"

# Tab 2: EmailActions (add new tab)
add_tab "$ACTIONITEMS_ID" "EmailActions" > /dev/null
write_headers "$ACTIONITEMS_ID" "EmailActions!A1:H1" \
  "Date" "FromEmail" "Subject" "ActionExtracted" \
  "AssignedTo" "DueDate" "MondayTaskID" "Status"

echo "Action Items sheet ready."
echo ""

# --------------------------------------------------------------------------- #
# 3. Create: D1 — AR Tracker
# --------------------------------------------------------------------------- #
echo "=== Sheet 2: D1 — AR Tracker ==="
AR_ID=$(create_sheet "D1 — AR Tracker")

# Tab 1: ARAging
rename_first_tab "$AR_ID" "ARAging"
write_headers "$AR_ID" "ARAging!A1:J1" \
  "Client" "InvoiceNumber" "InvoiceDate" "Amount" "DueDate" \
  "DaysOverdue" "Status" "LastFollowUp" "NextAction" "Notes"

# Tab 2: ClientStatus
add_tab "$AR_ID" "ClientStatus" > /dev/null
write_headers "$AR_ID" "ClientStatus!A1:F1" \
  "Client" "AccountManager" "TotalOutstanding" \
  "LastInvoiceDate" "PaymentBehavior" "RiskLevel"

echo "AR Tracker sheet ready."
echo ""

# --------------------------------------------------------------------------- #
# 4. Create: D1 — Payroll History
# --------------------------------------------------------------------------- #
echo "=== Sheet 3: D1 — Payroll History ==="
PAYROLL_ID=$(create_sheet "D1 — Payroll History")

# Tab 1: BiweeklyLog
rename_first_tab "$PAYROLL_ID" "BiweeklyLog"
write_headers "$PAYROLL_ID" "BiweeklyLog!A1:K1" \
  "PeriodStart" "PeriodEnd" "TotalHeadcount" "TotalHours" "TotalGross" \
  "AvgHoursPerPerson" "Dept_PH" "Dept_US" "ReviewedByDustin" "SentToEd" "Notes"

# Tab 2: TrendAnalysis
add_tab "$PAYROLL_ID" "TrendAnalysis" > /dev/null
write_headers "$PAYROLL_ID" "TrendAnalysis!A1:F1" \
  "Week" "HeadcountChange" "HoursChange" "GrossChange" "Flags" "InsightSummary"

echo "Payroll History sheet ready."
echo ""

# --------------------------------------------------------------------------- #
# 5. Create: D1 — AI Spend Tracker
# --------------------------------------------------------------------------- #
echo "=== Sheet 4: D1 — AI Spend Tracker ==="
AISPEND_ID=$(create_sheet "D1 — AI Spend Tracker")

# Tab 1: WeeklySpend
rename_first_tab "$AISPEND_ID" "WeeklySpend"
write_headers "$AISPEND_ID" "WeeklySpend!A1:I1" \
  "WeekOf" "Service" "Team" "UsageType" "Cost_USD" \
  "TokensUsed" "RequestCount" "AvgCostPerRequest" "Notes"

# Tab 2: MonthlyRollup
add_tab "$AISPEND_ID" "MonthlyRollup" > /dev/null
write_headers "$AISPEND_ID" "MonthlyRollup!A1:F1" \
  "Month" "Service" "TotalCost" "PercentOfBudget" "TopTeam" "Insight"

echo "AI Spend Tracker sheet ready."
echo ""

# --------------------------------------------------------------------------- #
# 6. Create: D1 — Daily Reports Archive
# --------------------------------------------------------------------------- #
echo "=== Sheet 5: D1 — Daily Reports Archive ==="
REPORTS_ID=$(create_sheet "D1 — Daily Reports Archive")

# Tab 1: DailyReports
rename_first_tab "$REPORTS_ID" "DailyReports"
write_headers "$REPORTS_ID" "DailyReports!A1:H1" \
  "Date" "ReportType" "AgentRunID" "Content" \
  "SentViaChat" "SentViaEmail" "DriveFileURL" "Tags"

# Tab 2: WeeklyReports
add_tab "$REPORTS_ID" "WeeklyReports" > /dev/null
write_headers "$REPORTS_ID" "WeeklyReports!A1:E1" \
  "WeekOf" "ReportType" "Content" "SentAt" "DriveFileURL"

echo "Daily Reports Archive sheet ready."
echo ""

# --------------------------------------------------------------------------- #
# 7. Print all sheet IDs as exportable env vars
# --------------------------------------------------------------------------- #
echo "============================================================"
echo "D1 AGENT — GOOGLE SHEETS ENV VARS"
echo "============================================================"
echo "Copy these into Coolify and update AGENTS.md:"
echo ""
echo "export DUSTIN_ACTIONITEMS_SHEET_ID=$ACTIONITEMS_ID"
echo "export DUSTIN_AR_SHEET_ID=$AR_ID"
echo "export DUSTIN_PAYROLL_SHEET_ID=$PAYROLL_ID"
echo "export DUSTIN_AISPEND_SHEET_ID=$AISPEND_ID"
echo "export DUSTIN_REPORTS_SHEET_ID=$REPORTS_ID"
echo ""
echo "export DUSTIN_D1_DRIVE_FOLDER_ID=$FOLDER_ID"
echo ""
echo "============================================================"
echo "REMINDER: Add these to Coolify env vars + update AGENTS.md with Sheet IDs"
echo "============================================================"

# --------------------------------------------------------------------------- #
# Curl fallback reference (if gws batchUpdate is unavailable)
# --------------------------------------------------------------------------- #
# TOKEN=$(~/.npm-global/bin/gws auth token)
#
# Rename first tab:
# curl -s -X POST \
#   "https://sheets.googleapis.com/v4/spreadsheets/${SPREADSHEET_ID}:batchUpdate" \
#   -H "Authorization: Bearer $TOKEN" \
#   -H "Content-Type: application/json" \
#   -d '{"requests":[{"updateSheetProperties":{"properties":{"sheetId":0,"title":"TabName"},"fields":"title"}}]}'
#
# Add new tab:
# curl -s -X POST \
#   "https://sheets.googleapis.com/v4/spreadsheets/${SPREADSHEET_ID}:batchUpdate" \
#   -H "Authorization: Bearer $TOKEN" \
#   -H "Content-Type: application/json" \
#   -d '{"requests":[{"addSheet":{"properties":{"title":"NewTabName"}}}]}'
#
# Write headers:
# curl -s -X PUT \
#   "https://sheets.googleapis.com/v4/spreadsheets/${SPREADSHEET_ID}/values/Tab!A1:Z1?valueInputOption=RAW" \
#   -H "Authorization: Bearer $TOKEN" \
#   -H "Content-Type: application/json" \
#   -d '{"values":[["Col1","Col2","Col3"]]}'
