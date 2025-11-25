-- ======================================================================
-- Investment Acknowledgement Event Fact
-- One row per acknowledgement acceptance event tied to an investment profile version.
-- Conforms to Audit Artifacts Standard (docs/audit/audit_artifacts_standard.md)
-- ======================================================================

CREATE TABLE IF NOT EXISTS fact.fact_investment_acknowledgement (
  -- Surrogate key
  acknowledgement_sk            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  
  -- Business keys
  investment_profile_id         VARCHAR(50) NOT NULL,
  ack_type                      VARCHAR(64) NOT NULL,  -- DERIVATIVE_RISK, FX_RISK, COMPLEX_PRODUCT
  accepted_ts                   TIMESTAMP(6) NOT NULL,
  
  -- Version linkage
  investment_profile_version_sk BIGINT,
  
  -- Acknowledgement details
  expires_ts                    TIMESTAMP(6),
  acceptance_channel            VARCHAR(50),  -- WEB, MOBILE, BRANCH, CALL_CENTER
  acceptance_ip_address         VARCHAR(100),
  acceptance_device_id          VARCHAR(100),
  
  -- Event tracking (per standard)
  event_detected_ts             TIMESTAMP(6) NOT NULL,
  actor_id                      VARCHAR(100) NOT NULL DEFAULT 'SYSTEM',
  actor_type                    VARCHAR(50) NOT NULL DEFAULT 'HUMAN',
  event_source_system           VARCHAR(100) NOT NULL,
  rationale_code                VARCHAR(100) NOT NULL DEFAULT 'DISCLOSURE_ACCEPTANCE',
  
  -- Event hash (per standard)
  event_hash                    VARCHAR(64) NOT NULL DEFAULT '__PENDING__',
  event_hash_status             VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  
  -- Audit metadata
  load_ts                       TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign keys (nullable for early events; backfill job will populate)
  CONSTRAINT fk_investment_profile_version FOREIGN KEY (investment_profile_version_sk) 
    REFERENCES dim.dim_investment_profile_version(investment_profile_version_sk),
  
  -- Integrity constraints
  CONSTRAINT ck_ack_expiry CHECK (
    expires_ts IS NULL OR expires_ts > accepted_ts
  ),
  CONSTRAINT ck_event_hash_status CHECK (
    (event_hash_status = 'PENDING' AND event_hash = '__PENDING__')
    OR (event_hash_status = 'GENERATED' AND event_hash != '__PENDING__' AND LENGTH(event_hash) = 64)
  ),
  CONSTRAINT ck_chronology CHECK (
    event_detected_ts >= accepted_ts OR rationale_code = 'CORRECTION'
  ),
  CONSTRAINT ck_ack_type CHECK (
    ack_type IN ('DERIVATIVE_RISK', 'FX_RISK', 'COMPLEX_PRODUCT')
  ),
  CONSTRAINT ck_actor_type CHECK (
    actor_type IN ('HUMAN', 'SYSTEM', 'BATCH_JOB')
  ),
  
  -- Uniqueness constraint
  CONSTRAINT uq_investment_ack_profile_type_ts UNIQUE (investment_profile_id, ack_type, accepted_ts)
);

-- Indexes
CREATE INDEX idx_ack_version_type 
  ON fact.fact_investment_acknowledgement(investment_profile_version_sk, ack_type);

CREATE INDEX idx_ack_expiry 
  ON fact.fact_investment_acknowledgement(expires_ts) 
  WHERE expires_ts IS NOT NULL;

CREATE INDEX idx_ack_event_hash_status 
  ON fact.fact_investment_acknowledgement(event_hash_status) 
  WHERE event_hash_status = 'PENDING';

CREATE INDEX idx_ack_profile_time 
  ON fact.fact_investment_acknowledgement(investment_profile_id, accepted_ts);

-- Table comment
COMMENT ON TABLE fact.fact_investment_acknowledgement IS 
'Audit event fact capturing acknowledgement acceptance events (DERIVATIVE_RISK, FX_RISK, COMPLEX_PRODUCT). Provides evidence for boolean flags in investment profile version. Conforms to Audit Artifacts Standard (ADR-AUDIT-001).';

-- Column comments
COMMENT ON COLUMN fact.fact_investment_acknowledgement.acknowledgement_sk IS 
'Surrogate identifier for acknowledgement event (auto-generated)';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.investment_profile_id IS 
'Investment profile identifier (stable across versions)';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.ack_type IS 
'Acknowledgement type: DERIVATIVE_RISK, FX_RISK, COMPLEX_PRODUCT';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.accepted_ts IS 
'Business-effective timestamp when acknowledgement was accepted';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.investment_profile_version_sk IS 
'Foreign key to investment profile version at time of acceptance (nullable for early events)';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.expires_ts IS 
'Expiration timestamp for time-limited acknowledgements (null if perpetual)';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.acceptance_channel IS 
'Channel: WEB, MOBILE, BRANCH, CALL_CENTER';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.event_hash IS 
'SHA256 hash of event content (default __PENDING__ until hash generation job runs)';

COMMENT ON COLUMN fact.fact_investment_acknowledgement.event_hash_status IS 
'Hash generation status: PENDING (awaiting job) or GENERATED (hash computed)';
