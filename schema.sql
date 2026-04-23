-- ============================================================
-- PolicyVault — Supabase Schema
-- Run this in your Supabase project's SQL Editor
-- ============================================================

-- Enable trigram extension for partial-word search on names
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================
-- POLICIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS policies (
  id                 UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  name               TEXT        NOT NULL,
  content            TEXT        NOT NULL,
  primary_category   TEXT        NOT NULL,
  secondary_category TEXT,
  tertiary_category  TEXT,
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW(),

  -- Generated full-text search vector (stored = indexed efficiently)
  -- Weights: A = name (highest), B = content, C = primary cat, D = secondary/tertiary
  search_vector TSVECTOR GENERATED ALWAYS AS (
    setweight(to_tsvector('english', COALESCE(name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(content, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(primary_category, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(COALESCE(secondary_category, '') || ' ' || COALESCE(tertiary_category, ''), '')), 'D')
  ) STORED
);

-- ============================================================
-- INDEXES
-- ============================================================

-- Full-text search (GIN index on the stored tsvector)
CREATE INDEX IF NOT EXISTS policies_search_idx
  ON policies USING GIN (search_vector);

-- Trigram index for partial name matching (e.g. typing "acc" finds "Acceptable Use")
CREATE INDEX IF NOT EXISTS policies_name_trgm_idx
  ON policies USING GIN (name gin_trgm_ops);

-- Category filtering
CREATE INDEX IF NOT EXISTS policies_primary_cat_idx
  ON policies (primary_category);

CREATE INDEX IF NOT EXISTS policies_categories_idx
  ON policies (primary_category, secondary_category, tertiary_category);

-- Sort by most recently updated
CREATE INDEX IF NOT EXISTS policies_updated_idx
  ON policies (updated_at DESC);

-- ============================================================
-- AUTO-UPDATE updated_at ON EDIT
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS policies_updated_at ON policies;
CREATE TRIGGER policies_updated_at
  BEFORE UPDATE ON policies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- ROW LEVEL SECURITY
-- For a personal tool, we allow all operations via the anon key.
-- To restrict access, replace the policy below with an
-- authenticated-user check using Supabase Auth.
-- ============================================================
ALTER TABLE policies ENABLE ROW LEVEL SECURITY;

-- Public read/write (suitable for a personal/internal tool)
DROP POLICY IF EXISTS "Allow all operations" ON policies;
CREATE POLICY "Allow all operations" ON policies
  FOR ALL
  USING (TRUE)
  WITH CHECK (TRUE);

-- ============================================================
-- SAMPLE DATA (optional — delete if not needed)
-- ============================================================
INSERT INTO policies (name, content, primary_category, secondary_category, tertiary_category) VALUES
(
  'Acceptable Use Policy',
  'Purpose
This Acceptable Use Policy sets out the terms under which employees may access and use company IT systems, networks, and equipment.

Scope
This policy applies to all employees, contractors, and third parties who access company systems.

Acceptable Use
Employees may use company IT resources for business purposes and reasonable personal use that does not interfere with work duties.

Prohibited Activities
The following activities are strictly prohibited:
- Accessing, storing, or distributing illegal or offensive content
- Using company systems for personal commercial gain
- Installing unauthorised software or hardware
- Sharing login credentials with others
- Circumventing security controls

Monitoring
The company reserves the right to monitor all activity on its IT systems in accordance with applicable law.

Consequences of Breach
Breach of this policy may result in disciplinary action up to and including dismissal, and may be referred to law enforcement authorities.

Review
This policy will be reviewed annually by the IT Security team.',
  'IT', 'Security', 'Policies'
),
(
  'Data Retention Policy',
  'Purpose
This policy defines how long different categories of data must be retained by the organisation, and the approved methods for secure disposal.

Scope
Applies to all data held in any format — digital or physical — by employees and contractors of the organisation.

Retention Schedule
- Employee Records: 7 years after employment ends
- Financial Records: 6 years (statutory requirement)
- Customer Data: Duration of contract plus 3 years
- Marketing Data: Until consent is withdrawn
- CCTV Footage: 30 days unless required for investigation

Secure Disposal
All data must be disposed of in a manner appropriate to its sensitivity:
- Digital files: Secure wipe or destruction of storage media
- Paper records: Cross-cut shredding or contracted confidential waste disposal

Responsibilities
Department heads are responsible for ensuring their teams adhere to this schedule. The Data Protection Officer will conduct annual audits.

Legal Basis
This policy complies with UK GDPR Article 5(1)(e) — storage limitation principle.',
  'HR', 'Data', 'GDPR'
),
(
  'Expenses and Reimbursement Policy',
  'Purpose
To ensure fair and consistent reimbursement of legitimate business expenses incurred by employees in the course of their duties.

Eligible Expenses
The following categories of expense may be claimed:
- Travel (rail, air, taxi, mileage at HMRC approved rate)
- Accommodation (up to £150 per night in London; £100 elsewhere)
- Meals when away from the normal place of work (up to £35 per day)
- Client entertainment (pre-approved by line manager)
- Professional subscriptions and training (pre-approved)

Approval Process
All expenses must be approved by the employee''s line manager prior to submission. Claims must be submitted within 30 days of the expense being incurred.

Receipts
Original receipts (or digital copies) must accompany all claims over £10. Claims without receipts will not be reimbursed.

Submission
Expenses should be submitted via the Finance portal by the 15th of each month for payment in that month''s payroll run.

Non-Eligible Expenses
- Alcohol (unless part of a pre-approved client entertainment event)
- Personal items
- Fines and penalties
- First-class travel (unless medical need is documented)',
  'Finance', 'Expenses', NULL
),
(
  'Whistleblowing Policy',
  'Introduction
The organisation is committed to the highest standards of openness, probity, and accountability. This policy encourages and enables employees to raise concerns about malpractice without fear of victimisation.

What to Report
Concerns that may be raised include:
- Financial malpractice or fraud
- Failure to comply with a legal obligation
- Dangers to health or safety
- Damage to the environment
- Deliberate concealment of any of the above

How to Raise a Concern
Concerns may be raised with your line manager, the HR Director, or the designated Whistleblowing Officer. If you prefer to raise a concern anonymously, you may use the confidential reporting hotline.

Confidentiality
All concerns raised will be treated in strict confidence. The organisation will not tolerate any harassment or victimisation of a person who has raised a genuine concern.

External Disclosures
Where internal channels have been exhausted, employees may report concerns to a relevant regulatory body such as the Financial Conduct Authority or the Health and Safety Executive.',
  'HR', 'Conduct', 'Reporting'
);
