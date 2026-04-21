-- =============================================================================
-- D1 Agent — Supabase PostgreSQL Schema
-- Agent: D1 (Dustin Johnson — Finance / HR / IT Head at Bold Business)
-- Created: 2026-04-22
-- Migration: append-only, never edit existing migrations
-- Table prefix: d1_
-- All tables: RLS enabled, uuid PK, created_at + updated_at, updated_at trigger
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Shared: updated_at trigger function (idempotent)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Table: d1_action_items
-- Purpose: Action items extracted from emails, meetings, and agent runs.
--          Each row is one actionable task assigned to a person with a due date
--          and lifecycle status. Mirrors the "ActionItems" tab in D1's Google Sheet.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_action_items (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  -- When the item was first logged (may differ from created_at for backdated imports)
  created_date      date,

  -- Source of the action item: 'email' | 'meeting' | 'agent_run' | 'manual'
  source            text        NOT NULL DEFAULT 'manual',

  -- Reference to the originating record (email message-id, meeting ID, agent_task_id, etc.)
  source_ref        text,

  title             text        NOT NULL,
  description       text,
  assignee          text,
  due_date          date,

  -- Lifecycle: 'open' | 'in_progress' | 'blocked' | 'done' | 'cancelled'
  status            text        NOT NULL DEFAULT 'open',

  followup_date     date,
  followup_count    integer     NOT NULL DEFAULT 0,
  closed_date       date,
  notes             text
);

COMMENT ON TABLE public.d1_action_items IS
  'Action items tracked by D1 agent — sourced from emails, meetings, or manual entry. '
  'One row per distinct task. Status lifecycle: open → in_progress → done/cancelled.';

CREATE INDEX IF NOT EXISTS idx_d1_action_items_status
  ON public.d1_action_items (status);

CREATE INDEX IF NOT EXISTS idx_d1_action_items_due_date
  ON public.d1_action_items (due_date);

CREATE INDEX IF NOT EXISTS idx_d1_action_items_assignee
  ON public.d1_action_items (assignee);

CREATE INDEX IF NOT EXISTS idx_d1_action_items_followup_date
  ON public.d1_action_items (followup_date)
  WHERE status NOT IN ('done', 'cancelled');

CREATE TRIGGER trg_d1_action_items_updated_at
  BEFORE UPDATE ON public.d1_action_items
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_action_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_action_items_admin_all" ON public.d1_action_items
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_action_items_service_role_all" ON public.d1_action_items
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_email_actions
-- Purpose: Email-sourced action items with direct linkage to Monday.com tasks.
--          Mirrors the "EmailActions" tab. Captures the extracted action text
--          and the Monday task ID created in response, enabling two-way tracking.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_email_actions (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  email_date        date        NOT NULL,
  from_email        text        NOT NULL,
  subject           text,
  action_extracted  text        NOT NULL,
  assigned_to       text,
  due_date          date,

  -- Monday.com task ID created for this action (nullable until task is created)
  monday_task_id    text,

  -- Status: 'pending' | 'monday_created' | 'done' | 'skipped'
  status            text        NOT NULL DEFAULT 'pending'
);

COMMENT ON TABLE public.d1_email_actions IS
  'Email-sourced action items parsed by D1 agent. Each row captures one action '
  'extracted from an inbound email and links it to its Monday.com task once created.';

CREATE INDEX IF NOT EXISTS idx_d1_email_actions_email_date
  ON public.d1_email_actions (email_date DESC);

CREATE INDEX IF NOT EXISTS idx_d1_email_actions_status
  ON public.d1_email_actions (status);

CREATE INDEX IF NOT EXISTS idx_d1_email_actions_from_email
  ON public.d1_email_actions (from_email);

CREATE TRIGGER trg_d1_email_actions_updated_at
  BEFORE UPDATE ON public.d1_email_actions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_email_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_email_actions_admin_all" ON public.d1_email_actions
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_email_actions_service_role_all" ON public.d1_email_actions
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_ar_tracker
-- Purpose: Accounts receivable aging log — one row per invoice per client.
--          Mirrors the "ARAging" tab. Used by D1 to flag overdue invoices and
--          drive automated follow-up cadences.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_ar_tracker (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  client            text        NOT NULL,
  invoice_number    text        NOT NULL,
  invoice_date      date        NOT NULL,

  -- Stored in USD cents to avoid floating-point rounding issues
  amount_cents      bigint      NOT NULL DEFAULT 0,

  due_date          date        NOT NULL,

  -- Computed at read time, but stored for fast aging queries without joins
  days_overdue      integer     NOT NULL DEFAULT 0,

  -- Status: 'current' | 'overdue_30' | 'overdue_60' | 'overdue_90' | 'paid' | 'disputed'
  status            text        NOT NULL DEFAULT 'current',

  last_follow_up    date,
  next_action       text,
  notes             text,

  UNIQUE (client, invoice_number)
);

COMMENT ON TABLE public.d1_ar_tracker IS
  'Accounts receivable aging per invoice. D1 agent reads this table to generate '
  'AR reports and trigger follow-up emails. amount_cents is USD × 100.';

CREATE INDEX IF NOT EXISTS idx_d1_ar_tracker_status
  ON public.d1_ar_tracker (status);

CREATE INDEX IF NOT EXISTS idx_d1_ar_tracker_due_date
  ON public.d1_ar_tracker (due_date);

CREATE INDEX IF NOT EXISTS idx_d1_ar_tracker_client
  ON public.d1_ar_tracker (client);

-- Partial index: active receivables only (fast overdue query)
CREATE INDEX IF NOT EXISTS idx_d1_ar_tracker_overdue
  ON public.d1_ar_tracker (days_overdue DESC)
  WHERE status NOT IN ('paid', 'disputed');

CREATE TRIGGER trg_d1_ar_tracker_updated_at
  BEFORE UPDATE ON public.d1_ar_tracker
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_ar_tracker ENABLE ROW LEVEL SECURITY;

-- Salary/compensation compliance: AR amounts are finance data — admin only
CREATE POLICY "d1_ar_tracker_admin_all" ON public.d1_ar_tracker
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_ar_tracker_service_role_all" ON public.d1_ar_tracker
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_ar_client_status
-- Purpose: Rolled-up client-level AR summary — one row per client.
--          Mirrors the "ClientStatus" tab. Tracks payment behaviour patterns
--          and risk classification used in Dustin's weekly AR review.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_ar_client_status (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),

  client                text        NOT NULL UNIQUE,
  account_manager       text,

  -- Total outstanding in USD cents
  total_outstanding_cents bigint    NOT NULL DEFAULT 0,

  last_invoice_date     date,

  -- e.g. 'always_on_time' | 'sometimes_late' | 'chronically_late'
  payment_behavior      text,

  -- 'low' | 'medium' | 'high' | 'critical'
  risk_level            text        NOT NULL DEFAULT 'low'
);

COMMENT ON TABLE public.d1_ar_client_status IS
  'Per-client AR summary. Refreshed by D1 agent after each AR aging run. '
  'risk_level drives escalation logic in the AR follow-up workflow.';

CREATE INDEX IF NOT EXISTS idx_d1_ar_client_status_risk_level
  ON public.d1_ar_client_status (risk_level);

CREATE TRIGGER trg_d1_ar_client_status_updated_at
  BEFORE UPDATE ON public.d1_ar_client_status
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_ar_client_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_ar_client_status_admin_all" ON public.d1_ar_client_status
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_ar_client_status_service_role_all" ON public.d1_ar_client_status
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_payroll_history
-- Purpose: Biweekly payroll summary log. One row per pay period.
--          Mirrors the "BiweeklyLog" tab. Captures headcount, hours, gross pay
--          and department splits (PH = Philippines, US = United States).
--          Salary compliance: restricted to admin + super_admin.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_payroll_history (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),

  period_start          date        NOT NULL,
  period_end            date        NOT NULL,
  total_headcount       integer     NOT NULL DEFAULT 0,
  total_hours           numeric(10, 2) NOT NULL DEFAULT 0,

  -- Gross pay in USD cents (salary compliance — admin only)
  total_gross_cents     bigint      NOT NULL DEFAULT 0,

  avg_hours_per_person  numeric(8, 2),

  -- Department breakdown — hours worked
  dept_ph_hours         numeric(10, 2),
  dept_us_hours         numeric(10, 2),

  reviewed_by_dustin    boolean     NOT NULL DEFAULT false,
  sent_to_ed            boolean     NOT NULL DEFAULT false,
  notes                 text,

  UNIQUE (period_start, period_end)
);

COMMENT ON TABLE public.d1_payroll_history IS
  'Biweekly payroll summary written by D1 agent after each payroll run. '
  'total_gross_cents is salary data — admin/super_admin RLS only (legal compliance). '
  'Dept_PH = Philippines headcount, Dept_US = US headcount.';

CREATE INDEX IF NOT EXISTS idx_d1_payroll_history_period_start
  ON public.d1_payroll_history (period_start DESC);

CREATE INDEX IF NOT EXISTS idx_d1_payroll_history_reviewed
  ON public.d1_payroll_history (reviewed_by_dustin)
  WHERE reviewed_by_dustin = false;

CREATE TRIGGER trg_d1_payroll_history_updated_at
  BEFORE UPDATE ON public.d1_payroll_history
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_payroll_history ENABLE ROW LEVEL SECURITY;

-- LEGAL COMPLIANCE: salary data — never expose to recruiter or candidate roles
CREATE POLICY "d1_payroll_history_admin_only" ON public.d1_payroll_history
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_payroll_history_service_role_all" ON public.d1_payroll_history
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_payroll_trend
-- Purpose: Week-over-week payroll trend analysis.
--          Mirrors the "TrendAnalysis" tab. Stores delta values and LLM-generated
--          insight summaries for Dustin's review.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_payroll_trend (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  week_of           date        NOT NULL UNIQUE,
  headcount_change  integer,
  hours_change      numeric(10, 2),
  gross_change      numeric(10, 2),
  flags             text[],
  insight_summary   text
);

COMMENT ON TABLE public.d1_payroll_trend IS
  'Weekly delta analysis computed by D1 agent from d1_payroll_history. '
  'flags is a postgres text array of exception codes (e.g. ''high_ot'', ''headcount_drop'').';

CREATE INDEX IF NOT EXISTS idx_d1_payroll_trend_week_of
  ON public.d1_payroll_trend (week_of DESC);

CREATE TRIGGER trg_d1_payroll_trend_updated_at
  BEFORE UPDATE ON public.d1_payroll_trend
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_payroll_trend ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_payroll_trend_admin_only" ON public.d1_payroll_trend
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_payroll_trend_service_role_all" ON public.d1_payroll_trend
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_ai_spend
-- Purpose: Weekly AI cost tracking per service and team.
--          Mirrors the "WeeklySpend" tab. Allows D1 to surface budget burn
--          rates and flag services that exceed cost thresholds.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_ai_spend (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),

  week_of               date        NOT NULL,

  -- e.g. 'openai' | 'gemini' | 'anthropic' | 'deepgram' | 'unipile'
  service               text        NOT NULL,

  -- Team that incurred the cost
  team                  text        NOT NULL,

  -- e.g. 'inference' | 'embedding' | 'transcription' | 'api_call'
  usage_type            text,

  -- Cost in USD cents
  cost_usd_cents        bigint      NOT NULL DEFAULT 0,

  tokens_used           bigint,
  request_count         integer,

  -- avg_cost_per_request in USD cents
  avg_cost_per_request_cents bigint,

  notes                 text,

  UNIQUE (week_of, service, team, usage_type)
);

COMMENT ON TABLE public.d1_ai_spend IS
  'Weekly AI infrastructure spend logged by D1 agent. One row per service/team/usage_type '
  'combination per week. cost_usd_cents = USD × 100. Used for budget burn reporting.';

CREATE INDEX IF NOT EXISTS idx_d1_ai_spend_week_of
  ON public.d1_ai_spend (week_of DESC);

CREATE INDEX IF NOT EXISTS idx_d1_ai_spend_service
  ON public.d1_ai_spend (service);

CREATE INDEX IF NOT EXISTS idx_d1_ai_spend_team
  ON public.d1_ai_spend (team);

CREATE TRIGGER trg_d1_ai_spend_updated_at
  BEFORE UPDATE ON public.d1_ai_spend
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_ai_spend ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_ai_spend_admin_all" ON public.d1_ai_spend
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_ai_spend_service_role_all" ON public.d1_ai_spend
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_ai_spend_monthly
-- Purpose: Monthly AI spend rollup per service.
--          Mirrors the "MonthlyRollup" tab. Pre-aggregated for fast dashboard
--          queries without needing to scan the weekly table.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_ai_spend_monthly (
  id                    uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),

  month                 date        NOT NULL,  -- always the 1st of the month
  service               text        NOT NULL,

  -- Total monthly cost in USD cents
  total_cost_cents      bigint      NOT NULL DEFAULT 0,

  -- Percentage of monthly AI budget consumed (0.00–100.00)
  percent_of_budget     numeric(5, 2),

  -- Team with highest spend that month
  top_team              text,

  insight               text,

  UNIQUE (month, service)
);

COMMENT ON TABLE public.d1_ai_spend_monthly IS
  'Monthly AI spend rollup aggregated from d1_ai_spend by D1 agent at month end. '
  'percent_of_budget compares total_cost_cents against a budget defined in agent config.';

CREATE INDEX IF NOT EXISTS idx_d1_ai_spend_monthly_month
  ON public.d1_ai_spend_monthly (month DESC);

CREATE TRIGGER trg_d1_ai_spend_monthly_updated_at
  BEFORE UPDATE ON public.d1_ai_spend_monthly
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_ai_spend_monthly ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_ai_spend_monthly_admin_all" ON public.d1_ai_spend_monthly
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_ai_spend_monthly_service_role_all" ON public.d1_ai_spend_monthly
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_daily_reports
-- Purpose: Archive of every daily report produced by D1 agent.
--          Mirrors the "DailyReports" tab. Full content stored in Supabase;
--          DriveFileURL links to the rendered copy in Google Drive.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_daily_reports (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  report_date       date        NOT NULL,

  -- e.g. 'daily_summary' | 'ar_aging' | 'payroll' | 'ai_spend' | 'action_items'
  report_type       text        NOT NULL,

  -- Unique run ID from the agent task that generated this report
  agent_run_id      text,

  -- Full Markdown or plain-text content of the report
  content           text,

  sent_via_chat     boolean     NOT NULL DEFAULT false,
  sent_via_email    boolean     NOT NULL DEFAULT false,

  -- Google Drive link to the rendered report doc
  drive_file_url    text,

  -- Searchable tags: e.g. ARRAY['payroll','ph','week42']
  tags              text[]
);

COMMENT ON TABLE public.d1_daily_reports IS
  'Full archive of D1 agent daily reports. Content is Markdown. '
  'tags column enables fast filtering by topic without full-text search. '
  'drive_file_url is the canonical shareable version in Google Drive.';

CREATE INDEX IF NOT EXISTS idx_d1_daily_reports_report_date
  ON public.d1_daily_reports (report_date DESC);

CREATE INDEX IF NOT EXISTS idx_d1_daily_reports_report_type
  ON public.d1_daily_reports (report_type);

CREATE INDEX IF NOT EXISTS idx_d1_daily_reports_tags
  ON public.d1_daily_reports USING GIN (tags);

CREATE INDEX IF NOT EXISTS idx_d1_daily_reports_unsent
  ON public.d1_daily_reports (report_date)
  WHERE sent_via_chat = false OR sent_via_email = false;

CREATE TRIGGER trg_d1_daily_reports_updated_at
  BEFORE UPDATE ON public.d1_daily_reports
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_daily_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_daily_reports_admin_all" ON public.d1_daily_reports
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_daily_reports_service_role_all" ON public.d1_daily_reports
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_weekly_reports
-- Purpose: Weekly consolidated reports. Mirrors the "WeeklyReports" tab.
--          Separate from daily_reports so weekly rollups are queryable without
--          filtering on report_type across a large daily table.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_weekly_reports (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  -- Always the Monday of the reporting week
  week_of           date        NOT NULL,

  -- e.g. 'weekly_summary' | 'ar_weekly' | 'payroll_weekly' | 'spend_weekly'
  report_type       text        NOT NULL,

  content           text,
  sent_at           timestamptz,
  drive_file_url    text,

  UNIQUE (week_of, report_type)
);

COMMENT ON TABLE public.d1_weekly_reports IS
  'Weekly consolidated reports produced by D1 agent every Monday. '
  'week_of is always a Monday date. sent_at is null until the report is dispatched.';

CREATE INDEX IF NOT EXISTS idx_d1_weekly_reports_week_of
  ON public.d1_weekly_reports (week_of DESC);

CREATE INDEX IF NOT EXISTS idx_d1_weekly_reports_unsent
  ON public.d1_weekly_reports (week_of)
  WHERE sent_at IS NULL;

CREATE TRIGGER trg_d1_weekly_reports_updated_at
  BEFORE UPDATE ON public.d1_weekly_reports
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_weekly_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_weekly_reports_admin_all" ON public.d1_weekly_reports
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_weekly_reports_service_role_all" ON public.d1_weekly_reports
  USING (auth.jwt() ->> 'role' = 'service_role');

-- ---------------------------------------------------------------------------
-- Table: d1_meeting_notes
-- Purpose: Raw meeting notes ingested by D1 agent with extracted action items.
--          Not in the Google Sheets schema but a natural companion table —
--          source records that feed d1_action_items and d1_daily_reports.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.d1_meeting_notes (
  id                uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  meeting_date      date        NOT NULL,
  meeting_title     text        NOT NULL,

  -- Participants as a text array: e.g. ARRAY['dustin@boldbusiness.com','ed@boldbusiness.com']
  participants      text[],

  -- Raw transcript or notes (Markdown or plain text)
  raw_notes         text,

  -- LLM-generated summary of the meeting
  summary           text,

  -- Number of action items extracted and written to d1_action_items
  actions_extracted integer     NOT NULL DEFAULT 0,

  -- True once D1 has processed and linked all action items
  processed         boolean     NOT NULL DEFAULT false,

  drive_file_url    text
);

COMMENT ON TABLE public.d1_meeting_notes IS
  'Meeting notes ingested by D1 agent. After processing, actions_extracted rows '
  'are written to d1_action_items with source=''meeting'' and source_ref=this id. '
  'processed=true means all actions have been linked and the meeting is archived.';

CREATE INDEX IF NOT EXISTS idx_d1_meeting_notes_meeting_date
  ON public.d1_meeting_notes (meeting_date DESC);

CREATE INDEX IF NOT EXISTS idx_d1_meeting_notes_unprocessed
  ON public.d1_meeting_notes (meeting_date)
  WHERE processed = false;

CREATE TRIGGER trg_d1_meeting_notes_updated_at
  BEFORE UPDATE ON public.d1_meeting_notes
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.d1_meeting_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "d1_meeting_notes_admin_all" ON public.d1_meeting_notes
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
      AND user_role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "d1_meeting_notes_service_role_all" ON public.d1_meeting_notes
  USING (auth.jwt() ->> 'role' = 'service_role');

-- =============================================================================
-- ROLLBACK (run in reverse order to tear down cleanly)
-- =============================================================================
-- DROP TABLE IF EXISTS public.d1_meeting_notes CASCADE;
-- DROP TABLE IF EXISTS public.d1_weekly_reports CASCADE;
-- DROP TABLE IF EXISTS public.d1_daily_reports CASCADE;
-- DROP TABLE IF EXISTS public.d1_ai_spend_monthly CASCADE;
-- DROP TABLE IF EXISTS public.d1_ai_spend CASCADE;
-- DROP TABLE IF EXISTS public.d1_payroll_trend CASCADE;
-- DROP TABLE IF EXISTS public.d1_payroll_history CASCADE;
-- DROP TABLE IF EXISTS public.d1_ar_client_status CASCADE;
-- DROP TABLE IF EXISTS public.d1_ar_tracker CASCADE;
-- DROP TABLE IF EXISTS public.d1_email_actions CASCADE;
-- DROP TABLE IF EXISTS public.d1_action_items CASCADE;
-- DROP FUNCTION IF EXISTS public.set_updated_at() CASCADE;

-- =============================================================================
-- Required environment variables
-- =============================================================================
-- Google Sheets IDs (from setup_databases.sh output):
--   DUSTIN_ACTIONITEMS_SHEET_ID
--   DUSTIN_AR_SHEET_ID
--   DUSTIN_PAYROLL_SHEET_ID
--   DUSTIN_AISPEND_SHEET_ID
--   DUSTIN_REPORTS_SHEET_ID
--
-- or use Supabase: SUPABASE_URL + SUPABASE_SERVICE_KEY (already in Coolify)
-- =============================================================================
