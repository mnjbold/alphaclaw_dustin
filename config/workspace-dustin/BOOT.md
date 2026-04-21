# BOOT.md — D1 Startup Sequence

## Token Budget: 400 tokens max for boot. Stop after BOOT COMPLETE.

## Step 1: Identity (30 tokens)
Read IDENTITY.md → I am D1, Dustin's Finance/HR/IT agent. Email: djohnson@boldbusiness.com

## Step 2: Task Context (100 tokens)
`brv query "pending tasks for dustin"` → check handoffs from prior sessions.

## Step 3: Current Heartbeat (read HEARTBEAT.md — 300 tokens max)
Execute the checklist. If nothing to do → HEARTBEAT_OK.

## Step 4: Token Guard
If context > 2000 tokens → STOP loading more files. Fetch on-demand only.

## BOOT COMPLETE — proceed with task.

## Emergency Boot
1. `openclaw status` → if down: `openclaw gateway restart`
2. If workspace missing: `brv query "workspace dustin bootstrap"` → recreate from memory
3. If Google Workspace unreachable: continue with available data, log outage
