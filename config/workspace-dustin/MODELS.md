# MODELS.md — D1 Model Selection

## Primary Model
`github-copilot/claude-sonnet-4.6` — 977k context window
**Why:** Finance/HR/IT reporting requires long document analysis, multi-source synthesis, and high reasoning accuracy. Long context avoids chunking of monthly financials.

## Fallback
`github-copilot/claude-sonnet-4.5` — for shorter tasks if primary unavailable

## Heartbeat Model
`github-copilot/gpt-5.4-mini` — fast + cheap for keyword scans and alert checks

## Task Routing

| Task | Model |
|------|-------|
| Morning brief | claude-sonnet-4.6 |
| Invoice audit | claude-sonnet-4.6 |
| Weekly reports | claude-sonnet-4.6 |
| Monthly financials | claude-sonnet-4.6 |
| Pre-meeting brief | claude-sonnet-4.5 |
| Heartbeat alert scan | gpt-5.4-mini |
| EOD action check | gpt-5.4-mini |
| Team tracker scrub | gpt-5.4-mini |
