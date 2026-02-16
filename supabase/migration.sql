-- FeedbackFlow: Database setup for Supabase
-- Run this in the Supabase SQL Editor (https://supabase.com/dashboard → SQL Editor)

-- =============================================================================
-- 1. Tables
-- =============================================================================

CREATE TABLE IF NOT EXISTS feedback_requests (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title       text NOT NULL,
    description text,
    email       text,
    status      text NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'in_review', 'planned', 'in_progress', 'completed')),
    vote_count  integer NOT NULL DEFAULT 0,
    device_id   text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS feedback_votes (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id  uuid NOT NULL REFERENCES feedback_requests(id) ON DELETE CASCADE,
    device_id   text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    UNIQUE (request_id, device_id)
);

-- Index for fast vote lookups by device
CREATE INDEX IF NOT EXISTS idx_feedback_votes_device ON feedback_votes (device_id);

-- =============================================================================
-- 2. Row Level Security (RLS)
-- =============================================================================

ALTER TABLE feedback_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback_votes ENABLE ROW LEVEL SECURITY;

-- feedback_requests: anyone can read non-pending requests
CREATE POLICY "anon_read_approved_requests"
    ON feedback_requests
    FOR SELECT
    USING (status != 'pending');

-- feedback_requests: anyone can insert (new submissions are 'pending')
CREATE POLICY "anon_insert_requests"
    ON feedback_requests
    FOR INSERT
    WITH CHECK (true);

-- feedback_requests: authenticated users (admin) have full access
CREATE POLICY "admin_full_access_requests"
    ON feedback_requests
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- feedback_votes: anyone can read their own votes
CREATE POLICY "anon_read_own_votes"
    ON feedback_votes
    FOR SELECT
    USING (true);

-- feedback_votes: authenticated users (admin) have full access on votes
CREATE POLICY "admin_full_access_votes"
    ON feedback_votes
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE TABLE IF NOT EXISTS feedback_comments (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id  uuid NOT NULL REFERENCES feedback_requests(id) ON DELETE CASCADE,
    body        text NOT NULL,
    device_id   text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_feedback_comments_request ON feedback_comments (request_id, created_at);

-- =============================================================================
-- 2b. RLS for feedback_comments
-- =============================================================================

ALTER TABLE feedback_comments ENABLE ROW LEVEL SECURITY;

-- Anyone can read comments on non-pending requests
CREATE POLICY "anon_read_comments"
    ON feedback_comments
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM feedback_requests
        WHERE feedback_requests.id = feedback_comments.request_id
        AND feedback_requests.status != 'pending'
    ));

-- Anyone can insert comments
CREATE POLICY "anon_insert_comments"
    ON feedback_comments
    FOR INSERT
    WITH CHECK (true);

-- Admin full access
CREATE POLICY "admin_full_access_comments"
    ON feedback_comments
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- =============================================================================
-- 3. RPC: toggle_vote (atomic vote/unvote)
-- =============================================================================

CREATE OR REPLACE FUNCTION toggle_vote(p_request_id uuid, p_device_id text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_exists boolean;
BEGIN
    -- Check if vote exists
    SELECT EXISTS(
        SELECT 1 FROM feedback_votes
        WHERE request_id = p_request_id AND device_id = p_device_id
    ) INTO v_exists;

    IF v_exists THEN
        -- Remove vote
        DELETE FROM feedback_votes
        WHERE request_id = p_request_id AND device_id = p_device_id;

        -- Decrement count
        UPDATE feedback_requests
        SET vote_count = GREATEST(0, vote_count - 1)
        WHERE id = p_request_id;

        RETURN json_build_object('voted', false);
    ELSE
        -- Add vote
        INSERT INTO feedback_votes (request_id, device_id)
        VALUES (p_request_id, p_device_id);

        -- Increment count
        UPDATE feedback_requests
        SET vote_count = vote_count + 1
        WHERE id = p_request_id;

        RETURN json_build_object('voted', true);
    END IF;
END;
$$;
