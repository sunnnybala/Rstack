-- rstack telemetry schema
-- Tables for tracking usage, installations, and update checks.
-- Research-specific fields: compute_provider, gpu_type, venue, pipeline_stage.

-- Main telemetry events (skill runs, upgrades)
CREATE TABLE telemetry_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  received_at TIMESTAMPTZ DEFAULT now(),
  schema_version INTEGER NOT NULL DEFAULT 1,
  event_type TEXT NOT NULL DEFAULT 'skill_run',
  rstack_version TEXT NOT NULL,
  os TEXT NOT NULL,
  arch TEXT,
  event_timestamp TIMESTAMPTZ NOT NULL,
  skill TEXT,
  session_id TEXT,
  duration_s NUMERIC,
  outcome TEXT NOT NULL,
  error_class TEXT,
  error_message TEXT,
  failed_step TEXT,
  used_browse BOOLEAN DEFAULT false,
  concurrent_sessions INTEGER DEFAULT 1,
  installation_id TEXT,
  -- Research-specific fields
  compute_provider TEXT,
  gpu_type TEXT,
  venue TEXT,
  pipeline_stage TEXT
);

-- Index for skill_sequences view performance
CREATE INDEX idx_telemetry_session_ts ON telemetry_events (session_id, event_timestamp);
-- Index for crash clustering
CREATE INDEX idx_telemetry_error ON telemetry_events (error_class, rstack_version) WHERE outcome = 'error';
-- Index for pipeline queries
CREATE INDEX idx_telemetry_pipeline ON telemetry_events (pipeline_stage) WHERE pipeline_stage IS NOT NULL;

-- Retention tracking per installation
CREATE TABLE installations (
  installation_id TEXT PRIMARY KEY,
  first_seen TIMESTAMPTZ DEFAULT now(),
  last_seen TIMESTAMPTZ DEFAULT now(),
  rstack_version TEXT,
  os TEXT
);

-- Install pings from update checks
CREATE TABLE update_checks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  checked_at TIMESTAMPTZ DEFAULT now(),
  rstack_version TEXT NOT NULL,
  os TEXT NOT NULL
);

-- RLS: INSERT-only for anon key (no reads via anon)
ALTER TABLE telemetry_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_insert_only" ON telemetry_events FOR INSERT WITH CHECK (true);

ALTER TABLE installations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_insert_only" ON installations FOR INSERT WITH CHECK (true);
CREATE POLICY "anon_update_last_seen" ON installations FOR UPDATE USING (true) WITH CHECK (true);

ALTER TABLE update_checks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_insert_only" ON update_checks FOR INSERT WITH CHECK (true);

-- Crash clustering view
CREATE VIEW crash_clusters AS
SELECT
  error_class,
  rstack_version,
  COUNT(*) as total_occurrences,
  COUNT(DISTINCT installation_id) as identified_users,
  COUNT(*) - COUNT(installation_id) as anonymous_occurrences,
  MIN(event_timestamp) as first_seen,
  MAX(event_timestamp) as last_seen
FROM telemetry_events
WHERE outcome = 'error' AND error_class IS NOT NULL
GROUP BY error_class, rstack_version
ORDER BY total_occurrences DESC;

-- Skill sequence co-occurrence view
CREATE VIEW skill_sequences AS
SELECT
  a.skill as skill_a,
  b.skill as skill_b,
  COUNT(DISTINCT a.session_id) as co_occurrences
FROM telemetry_events a
JOIN telemetry_events b ON a.session_id = b.session_id
  AND a.skill != b.skill
  AND a.event_timestamp < b.event_timestamp
WHERE a.event_type = 'skill_run' AND b.event_type = 'skill_run'
GROUP BY a.skill, b.skill
HAVING COUNT(DISTINCT a.session_id) >= 10
ORDER BY co_occurrences DESC;

-- Research pipeline tracking view
CREATE VIEW research_pipelines AS
SELECT
  rstack_version,
  venue,
  compute_provider,
  COUNT(*) as pipeline_runs,
  AVG(duration_s) as avg_duration_s,
  COUNT(DISTINCT installation_id) as unique_users,
  MIN(event_timestamp) as first_run,
  MAX(event_timestamp) as last_run
FROM telemetry_events
WHERE event_type = 'skill_run'
  AND pipeline_stage = 'research'
GROUP BY rstack_version, venue, compute_provider
ORDER BY pipeline_runs DESC;
