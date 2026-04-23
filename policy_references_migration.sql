-- ══════════════════════════════════════════════════════════════
--  PolicyVault — Policy References Migration
--  Run this in the Supabase SQL Editor after your existing
--  schema.sql has been applied.
-- ══════════════════════════════════════════════════════════════

-- Table to store ordered cross-references between policies
CREATE TABLE IF NOT EXISTS policy_references (
  id                   uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  policy_id            uuid NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  referenced_policy_id uuid NOT NULL REFERENCES policies(id) ON DELETE CASCADE,
  order_index          integer NOT NULL DEFAULT 0,
  created_at           timestamptz DEFAULT now(),

  -- A policy cannot reference the same policy twice
  UNIQUE (policy_id, referenced_policy_id),

  -- A policy cannot reference itself
  CONSTRAINT no_self_reference CHECK (policy_id <> referenced_policy_id)
);

-- Index for fast lookups of "what does policy X reference?"
CREATE INDEX IF NOT EXISTS idx_policy_references_policy_id
  ON policy_references (policy_id, order_index);

-- Index for fast lookups of "what policies reference policy X?"
CREATE INDEX IF NOT EXISTS idx_policy_references_referenced_policy_id
  ON policy_references (referenced_policy_id);

-- ── Row Level Security ─────────────────────────────────────────
ALTER TABLE policy_references ENABLE ROW LEVEL SECURITY;

-- All authenticated (approved) users can read references
CREATE POLICY "Authenticated users can read policy references"
  ON policy_references
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- All authenticated users can insert/update/delete references
-- (tighten this to admin-only if needed by replacing with a role check)
CREATE POLICY "Authenticated users can manage policy references"
  ON policy_references
  FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);
