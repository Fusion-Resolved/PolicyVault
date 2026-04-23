-- ============================================================
-- PolicyVault — Auth Schema
-- Run this AFTER schema.sql in your Supabase SQL Editor
-- ============================================================

-- ============================================================
-- USER PROFILES TABLE
-- Mirrors auth.users and adds approval + role fields
-- ============================================================
CREATE TABLE IF NOT EXISTS user_profiles (
  id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT        NOT NULL,
  full_name   TEXT,
  approved    BOOLEAN     NOT NULL DEFAULT FALSE,
  role        TEXT        NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  approved_at TIMESTAMPTZ,
  approved_by UUID        REFERENCES user_profiles(id)
);

-- ── Auto-create a profile row whenever a user signs up ────────
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- ── Row Level Security ────────────────────────────────────────
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read their own profile
DROP POLICY IF EXISTS "Own profile read"  ON user_profiles;
CREATE POLICY "Own profile read" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

-- Admins can read ALL profiles (for the user management panel)
DROP POLICY IF EXISTS "Admin read all profiles" ON user_profiles;
CREATE POLICY "Admin read all profiles" ON user_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update profiles (approve / revoke / promote)
DROP POLICY IF EXISTS "Admin update profiles" ON user_profiles;
CREATE POLICY "Admin update profiles" ON user_profiles
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ── Update policies table RLS to require approved users ───────
-- Remove the old open policy first
DROP POLICY IF EXISTS "Allow all operations" ON policies;

CREATE POLICY "Approved users select" ON policies
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND approved = TRUE
    )
  );

CREATE POLICY "Approved users insert" ON policies
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND approved = TRUE
    )
  );

CREATE POLICY "Approved users update" ON policies
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND approved = TRUE
    )
  );

-- ── Helper: approve a user ────────────────────────────────────
CREATE OR REPLACE FUNCTION approve_user(target_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_profiles
  SET
    approved    = TRUE,
    approved_at = NOW(),
    approved_by = auth.uid()
  WHERE id = target_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── Helper: revoke a user ─────────────────────────────────────
CREATE OR REPLACE FUNCTION revoke_user(target_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_profiles
  SET approved = FALSE, approved_at = NULL, approved_by = NULL
  WHERE id = target_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- BOOTSTRAP YOUR FIRST ADMIN
-- After you sign up through the app, run the line below in the
-- SQL Editor (replace the email address with your own).
-- ============================================================
--
-- UPDATE user_profiles
-- SET approved = TRUE, role = 'admin', approved_at = NOW()
-- WHERE email = 'your@email.com';
--
-- After that, all future approvals can be done from inside the app.
-- ============================================================
