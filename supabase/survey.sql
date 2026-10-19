-- FeedbackFlow: open survey answers ("Shape Shelfy's future" in Shelfy Settings).
-- Kept apart from feedback_requests so answers never show up on the public board.
-- Run after migration.sql (and notifications.sql for the email).

CREATE TABLE IF NOT EXISTS feedback_survey_responses (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at  timestamptz NOT NULL DEFAULT now(),
  device_id   text NOT NULL,
  rating      smallint CHECK (rating BETWEEN 1 AND 5),
  liked       text CHECK (char_length(liked) <= 4000),
  improve     text NOT NULL CHECK (char_length(improve) BETWEEN 1 AND 4000),
  email       text CHECK (char_length(email) <= 320),
  app_version text,
  posthog_id  text,
  status      text NOT NULL DEFAULT 'new'
              CHECK (status IN ('new', 'read', 'replied', 'archived')),
  admin_note  text
);

CREATE INDEX IF NOT EXISTS feedback_survey_responses_created_idx
  ON feedback_survey_responses (created_at DESC);

ALTER TABLE feedback_survey_responses ENABLE ROW LEVEL SECURITY;

-- The app's anon key may only add answers, never read them back.
DROP POLICY IF EXISTS anon_insert_survey ON feedback_survey_responses;
CREATE POLICY anon_insert_survey ON feedback_survey_responses
  FOR INSERT TO anon WITH CHECK (status = 'new' AND admin_note IS NULL);

DROP POLICY IF EXISTS admin_full_access_survey ON feedback_survey_responses;
CREATE POLICY admin_full_access_survey ON feedback_survey_responses
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Email on every answer (notify_admin comes from notifications.sql).
CREATE OR REPLACE FUNCTION on_new_survey_response()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM notify_admin(
    'Open comment' || COALESCE(' ★' || NEW.rating, '') || ': ' || left(NEW.improve, 60),
    COALESCE('<p><b>Rating:</b> ' || NEW.rating || ' / 5</p>', '') ||
    COALESCE('<p><b>Likes:</b> ' || replace(NEW.liked, '<', '&lt;') || '</p>', '') ||
    '<p><b>Could be better:</b> ' || replace(NEW.improve, '<', '&lt;') || '</p>' ||
    COALESCE('<p>Email: ' || replace(NEW.email, '<', '&lt;') || '</p>', '') ||
    '<p style="color:#888;">' || COALESCE(NEW.app_version, '') || ' · ' || COALESCE(NEW.posthog_id, '') || '</p>'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_new_survey_response ON feedback_survey_responses;
CREATE TRIGGER trg_new_survey_response
  AFTER INSERT ON feedback_survey_responses
  FOR EACH ROW
  EXECUTE FUNCTION on_new_survey_response();
