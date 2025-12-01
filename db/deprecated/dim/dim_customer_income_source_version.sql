-- Bridge: Customer Income Source per Profile Version (SCD2)
-- Purpose:
-- - Stores normalized membership of source_of_income for each customer_profile_version.
-- - Drives versioning via membership changes (order-insensitive).
-- Notes:
-- - Members are stored as text codes (enum to be defined later).
-- - The set-level hash is computed upstream and used in profile_hash (not stored here by default).

CREATE TABLE dim.dim_customer_income_source_version (
  customer_income_source_sk     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_profile_version_sk   BIGINT NOT NULL,     -- FK to dim.dim_customer_profile
  source_of_income_code         VARCHAR(64) NOT NULL, -- normalized code (UPPER(TRIM))
  load_ts                       TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_income_source_profile
    FOREIGN KEY (customer_profile_version_sk)
    REFERENCES dim.dim_customer_profile(customer_profile_version_sk)
    ON DELETE CASCADE
);

-- Ensure no duplicate member for the same profile version
CREATE UNIQUE INDEX uq_income_source_membership
  ON dim.dim_customer_income_source_version (customer_profile_version_sk, source_of_income_code);

-- Query helpers:
-- - To reconstruct set hash: SELECT codes for a version, normalize, sort asc, join '|', SHA256(...)
-- - To compare membership: use EXCEPT / MINUS between sets or compare derived hashes upstream.