-- Customer Profile SCD2 Dimension (Revised to text + names + economic bands)
-- Notes:
-- - Text attributes replace coded *_id fields (enums to be validated later).
-- - Single profile_hash per record (computed downstream; persisted here).
-- - Effective timestamps use TIMESTAMP precision.
-- - Multi-valued sets stored in bridge tables (not as columns here).

CREATE TABLE dim.dim_customer_profile (
  customer_profile_version_sk BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id                 BIGINT NOT NULL,          -- Stable internal person surrogate
  evidence_unique_key         VARCHAR(128),             -- Raw identity evidence (PII)

  -- Personal names (local preserves case)
  firstname                   VARCHAR(200),
  lastname                    VARCHAR(200),
  firstname_local             VARCHAR(200),
  lastname_local              VARCHAR(200),

  -- Text attributes (enum-validated later)
  person_title                VARCHAR(64),
  marital_status              VARCHAR(64),
  nationality                 VARCHAR(64),
  occupation                  VARCHAR(128),
  education_level             VARCHAR(64),
  business_type               VARCHAR(128),

  -- Demographic / economic bands
  birthdate                   DATE,
  total_asset                 VARCHAR(64),
  monthly_income              VARCHAR(64),
  income_country              VARCHAR(64),

  -- Derived change detection
  profile_hash                VARCHAR(64) NOT NULL,     -- SHA256 hex lowercase

  -- SCD2 controls
  version_num                 INT NOT NULL,
  effective_start_ts          TIMESTAMP(6) NOT NULL,
  effective_end_ts            TIMESTAMP(6),
  is_current                  BOOLEAN NOT NULL,
  load_ts                     TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT uq_customer_version UNIQUE (customer_id, version_num),
  CONSTRAINT ck_effective_window CHECK (effective_end_ts IS NULL OR effective_end_ts >= effective_start_ts)
);

-- Indexes for current lookup and PIT queries
CREATE INDEX idx_customer_profile_current
  ON dim.dim_customer_profile (customer_id, is_current);

CREATE INDEX idx_customer_profile_effective
  ON dim.dim_customer_profile (customer_id, effective_start_ts, effective_end_ts);