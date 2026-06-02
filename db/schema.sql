-- Baby Tracker Suite — PostgreSQL Schema
-- Database: maestro_hub on homelab.local:5432

-- Contraction Tracker (May 2026, retired May 28)
CREATE TABLE IF NOT EXISTS contractions (
    id        SERIAL PRIMARY KEY,
    type      VARCHAR(20) NOT NULL DEFAULT 'contraction',
    note      TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    intensity VARCHAR(10) DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS idx_contractions_logged_at ON contractions (logged_at DESC);

-- Baby Tracker (May 28, 2026 — active)
CREATE TABLE IF NOT EXISTS baby_events (
    id            SERIAL PRIMARY KEY,
    event_type    VARCHAR(20) NOT NULL,
    event_subtype VARCHAR(20),
    note          TEXT,
    logged_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_baby_events_logged_at ON baby_events (logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_baby_events_type ON baby_events (event_type);
