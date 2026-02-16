-- FeedbackFlow: Email notifications via Resend + pg_net
-- Optional: Run this AFTER migration.sql to get email alerts on new requests, votes, and comments.
--
-- Prerequisites:
--   1. Enable pg_net extension in Supabase (Database → Extensions → pg_net)
--   2. Create a free account at https://resend.com and get an API key
--
-- Replace the placeholders below:
--   YOUR_RESEND_API_KEY  → your Resend API key (re_...)
--   YOUR_EMAIL@EXAMPLE   → email address to receive notifications
--   YOUR_SENDER_NAME     → name shown in the "from" field
--   your@verified.domain → a domain verified in Resend (or use onboarding@resend.dev for testing)

-- =============================================================================
-- 1. Enable pg_net
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- =============================================================================
-- 2. Helper: send email via Resend API
-- =============================================================================

CREATE OR REPLACE FUNCTION notify_admin(p_subject text, p_body text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://api.resend.com/emails',
    headers := jsonb_build_object(
      'Authorization', 'Bearer YOUR_RESEND_API_KEY',
      'Content-Type', 'application/json'
    ),
    body := jsonb_build_object(
      'from', 'YOUR_SENDER_NAME <your@verified.domain>',
      'to', jsonb_build_array('YOUR_EMAIL@EXAMPLE'),
      'subject', p_subject,
      'html', p_body
    )
  );
END;
$$;

-- =============================================================================
-- 3. Trigger: new feedback request
-- =============================================================================

CREATE OR REPLACE FUNCTION on_new_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM notify_admin(
    'New feature request: ' || NEW.title,
    '<h3>' || NEW.title || '</h3>' ||
    COALESCE('<p>' || NEW.description || '</p>', '') ||
    COALESCE('<p>Email: ' || NEW.email || '</p>', '') ||
    '<p style="color:#888;">Status: ' || NEW.status || '</p>'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_new_request ON feedback_requests;
CREATE TRIGGER trg_new_request
  AFTER INSERT ON feedback_requests
  FOR EACH ROW
  EXECUTE FUNCTION on_new_request();

-- =============================================================================
-- 4. Trigger: new vote
-- =============================================================================

CREATE OR REPLACE FUNCTION on_new_vote()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_title text;
  v_count int;
BEGIN
  SELECT title, vote_count INTO v_title, v_count
  FROM feedback_requests WHERE id = NEW.request_id;

  PERFORM notify_admin(
    'New vote on: ' || COALESCE(v_title, 'Unknown'),
    '<h3>' || COALESCE(v_title, 'Unknown') || '</h3>' ||
    '<p>Total votes: <strong>' || COALESCE(v_count, 0)::text || '</strong></p>'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_new_vote ON feedback_votes;
CREATE TRIGGER trg_new_vote
  AFTER INSERT ON feedback_votes
  FOR EACH ROW
  EXECUTE FUNCTION on_new_vote();

-- =============================================================================
-- 5. Trigger: new comment
-- =============================================================================

CREATE OR REPLACE FUNCTION on_new_comment()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_title text;
BEGIN
  SELECT title INTO v_title
  FROM feedback_requests WHERE id = NEW.request_id;

  PERFORM notify_admin(
    'New comment on: ' || COALESCE(v_title, 'Unknown'),
    '<h3>' || COALESCE(v_title, 'Unknown') || '</h3>' ||
    '<blockquote>' || NEW.body || '</blockquote>'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_new_comment ON feedback_comments;
CREATE TRIGGER trg_new_comment
  AFTER INSERT ON feedback_comments
  FOR EACH ROW
  EXECUTE FUNCTION on_new_comment();
