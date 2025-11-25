-- ======================================================================
-- Supervisory Override Event Fact
-- One row per supervisory override decision (complex product access for vulnerable investors, 
-- margin approval exceptions, etc.).
-- Conforms to Audit Artifacts Standard (docs/audit/audit_artifacts_standard.md)
-- ======================================================================

CREATE TABLE IF NOT EXISTS fact.fact_supervisory_override (
  -- Surrogate key
  override_sk                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  
  -- Business keys
  investment_profile_id         VARCHAR(50) NOT NULL,
  override_type                 VARCHAR(100) NOT NULL,  -- COMPLEX_PRODUCT_VULNERABLE, MARGIN_EXCEPTION, LEVERAGE_EXCEPTION, IPO_ACCESS_EXCEPTION
  override_ts                   TIMESTAMP(6) NOT NULL,
  
  -- Version linkage
  investment_profile_version_sk BIGINT,
  
  -- Override decision
  override_decision             VARCHAR(50) NOT NULL,  -- APPROVED, DENIED, CONDITIONAL_APPROVED
  override_reason               TEXT NOT NULL,
  
  -- Supervisor details
  supervisor_id                 VARCHAR(100) NOT NULL,
  supervisor_name               VARCHAR(200) NOT NULL,
  supervisor_role               VARCHAR(100) NOT NULL,  -- BRANCH_MANAGER, COMPLIANCE_OFFICER, REGIONAL_SUPERVISOR, CHIEF_COMPLIANCE
  
  -- Request details
  requested_by_id               VARCHAR(100),
  request_reason                TEXT,
  
  -- Customer consent
  customer_consent_flag         BOOLEAN NOT NULL DEFAULT FALSE,
  consent_document_id           VARCHAR(200),
  
  -- Override validity
  override_effective_start_ts   TIMESTAMP(6),
  override_effective_end_ts     TIMESTAMP(6),
  conditions                    TEXT,
  review_frequency              VARCHAR(50),  -- MONTHLY, QUARTERLY, ANNUAL
  next_review_due_ts            TIMESTAMP(6),
  
  -- Regulatory tracking
  regulatory_notification_flag  BOOLEAN NOT NULL DEFAULT FALSE,
  regulatory_notification_ts    TIMESTAMP(6),
  
  -- Event tracking (per standard)
  event_detected_ts             TIMESTAMP(6) NOT NULL,
  actor_id                      VARCHAR(100) NOT NULL DEFAULT 'SYSTEM',
  actor_type                    VARCHAR(50) NOT NULL DEFAULT 'HUMAN',
  event_source_system           VARCHAR(100) NOT NULL,
  rationale_code                VARCHAR(100) NOT NULL DEFAULT 'SUPERVISORY_OVERRIDE',
  
  -- Event hash (per standard)
  event_hash                    VARCHAR(64) NOT NULL DEFAULT '__PENDING__',
  event_hash_status             VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  
  -- Audit metadata
  load_ts                       TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign keys (nullable for early events; backfill job will populate)
  CONSTRAINT fk_investment_profile_version FOREIGN KEY (investment_profile_version_sk) 
    REFERENCES dim.dim_investment_profile_version(investment_profile_version_sk),
  
  -- Integrity constraints
  CONSTRAINT ck_override_validity CHECK (
    override_effective_end_ts IS NULL 
    OR override_effective_end_ts > override_effective_start_ts
  ),
  CONSTRAINT ck_approved_start_ts CHECK (
    override_decision NOT IN ('APPROVED', 'CONDITIONAL_APPROVED')
    OR override_effective_start_ts IS NOT NULL
  ),
  CONSTRAINT ck_conditional_requirements CHECK (
    override_decision != 'CONDITIONAL_APPROVED'
    OR (conditions IS NOT NULL AND review_frequency IS NOT NULL)
  ),
  CONSTRAINT ck_customer_consent_document CHECK (
    customer_consent_flag = FALSE OR consent_document_id IS NOT NULL
  ),
  CONSTRAINT ck_event_hash_status CHECK (
    (event_hash_status = 'PENDING' AND event_hash = '__PENDING__')
    OR (event_hash_status = 'GENERATED' AND event_hash != '__PENDING__' AND LENGTH(event_hash) = 64)
  ),
  CONSTRAINT ck_chronology CHECK (
    event_detected_ts >= override_ts OR rationale_code = 'PERIODIC_RENEWAL'
  ),
  CONSTRAINT ck_override_type CHECK (
    override_type IN ('COMPLEX_PRODUCT_VULNERABLE', 'MARGIN_EXCEPTION', 'LEVERAGE_EXCEPTION', 'IPO_ACCESS_EXCEPTION')
  ),
  CONSTRAINT ck_override_decision CHECK (
    override_decision IN ('APPROVED', 'DENIED', 'CONDITIONAL_APPROVED')
  ),
  CONSTRAINT ck_supervisor_role CHECK (
    supervisor_role IN ('BRANCH_MANAGER', 'COMPLIANCE_OFFICER', 'REGIONAL_SUPERVISOR', 'CHIEF_COMPLIANCE')
  ),
  CONSTRAINT ck_actor_type CHECK (
    actor_type IN ('HUMAN', 'SYSTEM', 'BATCH_JOB')
  ),
  CONSTRAINT ck_review_frequency CHECK (
    review_frequency IS NULL 
    OR review_frequency IN ('MONTHLY', 'QUARTERLY', 'ANNUAL')
  ),
  
  -- Uniqueness constraint
  CONSTRAINT uq_supervisory_override_profile_type_ts UNIQUE (investment_profile_id, override_type, override_ts)
);

-- Indexes
CREATE INDEX idx_override_profile_time 
  ON fact.fact_supervisory_override(investment_profile_id, override_ts);

CREATE INDEX idx_override_version 
  ON fact.fact_supervisory_override(investment_profile_version_sk);

CREATE INDEX idx_override_supervisor 
  ON fact.fact_supervisory_override(supervisor_id);

CREATE INDEX idx_override_next_review 
  ON fact.fact_supervisory_override(next_review_due_ts) 
  WHERE next_review_due_ts IS NOT NULL;

CREATE INDEX idx_override_event_hash_status 
  ON fact.fact_supervisory_override(event_hash_status) 
  WHERE event_hash_status = 'PENDING';

CREATE INDEX idx_override_decision_type 
  ON fact.fact_supervisory_override(override_decision, override_type);

-- Table comment
COMMENT ON TABLE fact.fact_supervisory_override IS 
'Audit event fact capturing supervisory override decisions for complex product access, margin exceptions, and other suitability overrides. Documents supervisor identity, rationale, conditions, and review requirements for regulatory compliance. Conforms to Audit Artifacts Standard (ADR-AUDIT-001).';

-- Column comments
COMMENT ON COLUMN fact.fact_supervisory_override.override_sk IS 
'Surrogate identifier for override event (auto-generated)';

COMMENT ON COLUMN fact.fact_supervisory_override.investment_profile_id IS 
'Investment profile identifier (stable across versions)';

COMMENT ON COLUMN fact.fact_supervisory_override.override_type IS 
'Type: COMPLEX_PRODUCT_VULNERABLE, MARGIN_EXCEPTION, LEVERAGE_EXCEPTION, IPO_ACCESS_EXCEPTION';

COMMENT ON COLUMN fact.fact_supervisory_override.override_ts IS 
'Business-effective timestamp when override decision was made';

COMMENT ON COLUMN fact.fact_supervisory_override.investment_profile_version_sk IS 
'Foreign key to investment profile version at time of override (nullable for early events)';

COMMENT ON COLUMN fact.fact_supervisory_override.override_decision IS 
'Decision outcome: APPROVED, DENIED, CONDITIONAL_APPROVED';

COMMENT ON COLUMN fact.fact_supervisory_override.override_reason IS 
'Supervisor documented reason for override decision';

COMMENT ON COLUMN fact.fact_supervisory_override.supervisor_id IS 
'Identifier of supervisor making override decision';

COMMENT ON COLUMN fact.fact_supervisory_override.supervisor_role IS 
'Role: BRANCH_MANAGER, COMPLIANCE_OFFICER, REGIONAL_SUPERVISOR, CHIEF_COMPLIANCE';

COMMENT ON COLUMN fact.fact_supervisory_override.customer_consent_flag IS 
'True if customer explicitly consented to override conditions (e.g., signed waiver)';

COMMENT ON COLUMN fact.fact_supervisory_override.consent_document_id IS 
'Reference to signed consent document (e.g., DocuSign envelope ID)';

COMMENT ON COLUMN fact.fact_supervisory_override.override_effective_start_ts IS 
'Override becomes effective at this timestamp';

COMMENT ON COLUMN fact.fact_supervisory_override.override_effective_end_ts IS 
'Override expires at this timestamp (null if indefinite)';

COMMENT ON COLUMN fact.fact_supervisory_override.conditions IS 
'Conditions attached to override (e.g., Max position size 10% of portfolio)';

COMMENT ON COLUMN fact.fact_supervisory_override.review_frequency IS 
'Required review frequency for conditional approvals: MONTHLY, QUARTERLY, ANNUAL';

COMMENT ON COLUMN fact.fact_supervisory_override.regulatory_notification_flag IS 
'True if override requires regulatory notification per internal policy';

COMMENT ON COLUMN fact.fact_supervisory_override.event_hash IS 
'SHA256 hash of event content (default __PENDING__ until hash generation job runs)';

COMMENT ON COLUMN fact.fact_supervisory_override.event_hash_status IS 
'Hash generation status: PENDING (awaiting job) or GENERATED (hash computed)';
