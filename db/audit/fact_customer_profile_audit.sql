-- ======================================================================
-- Customer Profile Audit Event Fact
-- One row per profile change event causing a new SCD2 version in dim_customer_profile.
-- Conforms to Audit Artifacts Standard (docs/audit/audit_artifacts_standard.md)
-- ======================================================================

CREATE TABLE IF NOT EXISTS fact.fact_customer_profile_audit (
  -- Surrogate key
  audit_event_sk                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  
  -- Business keys
  customer_id                   VARCHAR(50) NOT NULL,
  profile_version_id_new        BIGINT NOT NULL,
  profile_version_id_old        BIGINT,
  
  -- Change metadata
  change_reason                 VARCHAR(100) NOT NULL DEFAULT 'UNKNOWN',  -- INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, DATA_QUALITY_FIX, MERGE_FLAG, RECOMPUTE_HASH
  changed_scalar_attributes     TEXT,  -- JSON array of scalar attribute names changed
  changed_set_names             TEXT,  -- JSON array of multi-valued set names changed
  scalar_attribute_old_values   TEXT,  -- JSON object of old scalar values (subset for changed attributes)
  scalar_attribute_new_values   TEXT,  -- JSON object of new scalar values (subset for changed attributes)
  set_membership_diff_summary   TEXT,  -- JSON object summarizing counts of added/removed members per changed set
  
  -- Hash tracking
  old_profile_hash              VARCHAR(64),
  new_profile_hash              VARCHAR(64) NOT NULL,
  
  -- Temporal attributes
  event_source_ts               TIMESTAMP(6) NOT NULL,
  event_detected_ts             TIMESTAMP(6) NOT NULL,
  effective_start_ts_new        TIMESTAMP(6) NOT NULL,
  processing_latency_seconds    INTEGER,
  
  -- Actor and source
  actor_id                      VARCHAR(100) NOT NULL DEFAULT 'SYSTEM',
  actor_type                    VARCHAR(50) NOT NULL DEFAULT 'SYSTEM',
  initiated_by_system           VARCHAR(100) NOT NULL,  -- e.g., CRM, KYC, SURVEY, PURPOSE_APP
  initiated_by_user_id          VARCHAR(100),
  
  -- Event hash (per standard)
  event_hash                    VARCHAR(64) NOT NULL DEFAULT '__PENDING__',
  event_hash_status             VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  
  -- Audit metadata
  load_ts                       TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign keys (nullable for early events; backfill job will populate)
  CONSTRAINT fk_profile_version_new FOREIGN KEY (profile_version_id_new) 
    REFERENCES dim.dim_customer_profile(customer_profile_version_sk),
  CONSTRAINT fk_profile_version_old FOREIGN KEY (profile_version_id_old) 
    REFERENCES dim.dim_customer_profile(customer_profile_version_sk),
  
  -- Integrity constraints
  CONSTRAINT ck_event_hash_status CHECK (
    (event_hash_status = 'PENDING' AND event_hash = '__PENDING__')
    OR (event_hash_status = 'GENERATED' AND event_hash != '__PENDING__' AND LENGTH(event_hash) = 64)
  ),
  CONSTRAINT ck_initial_load_no_old_version CHECK (
    change_reason != 'INITIAL_LOAD' OR profile_version_id_old IS NULL
  ),
  CONSTRAINT ck_processing_latency CHECK (
    processing_latency_seconds >= 0 OR change_reason IN ('CORRECTION', 'MERGE_FLAG')
  ),
  CONSTRAINT ck_new_profile_hash_length CHECK (
    LENGTH(new_profile_hash) = 64
  ),
  CONSTRAINT ck_old_profile_hash_length CHECK (
    old_profile_hash IS NULL OR LENGTH(old_profile_hash) = 64
  ),
  
  -- Uniqueness constraint
  CONSTRAINT uq_customer_profile_audit_version UNIQUE (customer_id, profile_version_id_new)
);

-- Indexes
CREATE INDEX idx_customer_profile_audit_customer_time 
  ON fact.fact_customer_profile_audit(customer_id, event_source_ts);

CREATE INDEX idx_customer_profile_audit_event_hash_status 
  ON fact.fact_customer_profile_audit(event_hash_status) 
  WHERE event_hash_status = 'PENDING';

CREATE INDEX idx_customer_profile_audit_change_reason 
  ON fact.fact_customer_profile_audit(change_reason);

-- Table comment
COMMENT ON TABLE fact.fact_customer_profile_audit IS 
'Audit event fact capturing customer profile SCD2 version creation events. Each row documents a state change with rationale, actor, and attribute-level change tracking. Conforms to Audit Artifacts Standard (ADR-AUDIT-001).';

-- Column comments
COMMENT ON COLUMN fact.fact_customer_profile_audit.audit_event_sk IS 
'Surrogate identifier for audit event (auto-generated)';

COMMENT ON COLUMN fact.fact_customer_profile_audit.customer_id IS 
'Customer identity key affected by profile change';

COMMENT ON COLUMN fact.fact_customer_profile_audit.profile_version_id_new IS 
'Newly created profile version identifier (FK to dim_customer_profile)';

COMMENT ON COLUMN fact.fact_customer_profile_audit.profile_version_id_old IS 
'Previous profile version identifier (NULL if INITIAL_LOAD)';

COMMENT ON COLUMN fact.fact_customer_profile_audit.change_reason IS 
'Categorized reason: INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, DATA_QUALITY_FIX, MERGE_FLAG, RECOMPUTE_HASH';

COMMENT ON COLUMN fact.fact_customer_profile_audit.event_hash IS 
'SHA256 hash of event content (default __PENDING__ until hash generation job runs)';

COMMENT ON COLUMN fact.fact_customer_profile_audit.event_hash_status IS 
'Hash generation status: PENDING (awaiting job) or GENERATED (hash computed)';
