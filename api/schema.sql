-- MCP Foundry - Supabase-compatible PostgreSQL schema
-- Registry for verified and unverified MCP tool servers

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- tools: The primary catalog of MCP tool servers
-- ============================================================================
CREATE TABLE tools (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT NOT NULL,
    author          TEXT NOT NULL,
    version         TEXT NOT NULL DEFAULT '0.0.0',
    homepage        TEXT,
    verified        BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at     TIMESTAMPTZ,
    sha512          TEXT,                  -- SHA-512 hash of the verified binary
    tools_count     INTEGER NOT NULL DEFAULT 0,
    rating          NUMERIC(2,1) NOT NULL DEFAULT 0.0,
    install_count   INTEGER NOT NULL DEFAULT 0,
    permissions_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    tools_json      JSONB NOT NULL DEFAULT '[]'::jsonb,
    scan_summary    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for common queries
CREATE INDEX idx_tools_verified ON tools (verified);
CREATE INDEX idx_tools_author ON tools (author);
CREATE INDEX idx_tools_rating ON tools (rating DESC);
CREATE INDEX idx_tools_install_count ON tools (install_count DESC);
CREATE INDEX idx_tools_created_at ON tools (created_at DESC);
CREATE INDEX idx_tools_sha512 ON tools (sha512) WHERE sha512 IS NOT NULL;

-- Full-text search index on name and description
CREATE INDEX idx_tools_search ON tools USING GIN (
    to_tsvector('english', name || ' ' || description)
);

-- Auto-update updated_at on row changes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tools_updated_at
    BEFORE UPDATE ON tools
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- submissions: Track tool submission PRs through the review pipeline
-- ============================================================================
CREATE TABLE submissions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tool_id         TEXT NOT NULL,
    pr_url          TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'scanning', 'scanned', 'in_review', 'approved', 'rejected')),
    scan_result_json JSONB,
    submitted_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at     TIMESTAMPTZ,

    CONSTRAINT fk_submissions_tool
        FOREIGN KEY (tool_id) REFERENCES tools(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_submissions_tool_id ON submissions (tool_id);
CREATE INDEX idx_submissions_status ON submissions (status);
CREATE INDEX idx_submissions_submitted_at ON submissions (submitted_at DESC);

-- ============================================================================
-- reviews: Individual review verdicts on submissions
-- ============================================================================
CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id   UUID NOT NULL,
    reviewer        TEXT NOT NULL,
    verdict         TEXT NOT NULL
                    CHECK (verdict IN ('approve', 'reject', 'request_changes')),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_reviews_submission
        FOREIGN KEY (submission_id) REFERENCES submissions(id)
        ON DELETE CASCADE
);

CREATE INDEX idx_reviews_submission_id ON reviews (submission_id);
CREATE INDEX idx_reviews_reviewer ON reviews (reviewer);
CREATE INDEX idx_reviews_created_at ON reviews (created_at DESC);

-- ============================================================================
-- Row Level Security (Supabase)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE tools ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

-- Public read access to tools catalog
CREATE POLICY "Public read access to tools"
    ON tools FOR SELECT
    USING (true);

-- Only authenticated users can insert/update tools (admin)
CREATE POLICY "Admin insert tools"
    ON tools FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Admin update tools"
    ON tools FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Public read access to submissions
CREATE POLICY "Public read access to submissions"
    ON submissions FOR SELECT
    USING (true);

-- Authenticated users can create submissions
CREATE POLICY "Authenticated insert submissions"
    ON submissions FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Only admins can update submission status
CREATE POLICY "Admin update submissions"
    ON submissions FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Public read access to reviews
CREATE POLICY "Public read access to reviews"
    ON reviews FOR SELECT
    USING (true);

-- Authenticated users can create reviews
CREATE POLICY "Authenticated insert reviews"
    ON reviews FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');
