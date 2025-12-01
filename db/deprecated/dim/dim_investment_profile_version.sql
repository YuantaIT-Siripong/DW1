-- ======================================================================
-- SCD2 Version Table: dim_investment_profile_version
-- One row per historical version interval per investment_profile_id.
-- Effective dating granularity: timestamp (seconds).
-- Change detection driven by profile_hash (SHA256 of ordered versioned attributes).
-- ======================================================================

create table dim.dim_investment_profile_version (
  investment_profile_version_sk   bigint generated always as identity primary key,
  investment_profile_id           varchar(64) not null references dim.dim_investment_profile(investment_profile_id),
  version_number                  int not null,  -- Sequential per investment_profile_id
  effective_start_ts              timestamp not null,
  effective_end_ts                timestamp,
  current_flag                    boolean not null default true, -- Exactly one current per profile
  -- Core Suitability / Risk
  suitability_score               int,
  suitability_tier                varchar(32),
  risk_level_code                 varchar(32),
  ability_to_bear_loss_tier       varchar(32),
  investment_objective_category   varchar(32),
  investment_time_horizon         varchar(32),
  liquidity_need_level            varchar(32),
  investment_experience_years     int,
  -- Regulatory / Compliance
  high_net_worth_status_code      varchar(16),
  kyc_status                      varchar(32),
  kyc_risk_rating                 varchar(32),
  aml_risk_rating                 varchar(32),
  pep_flag                        boolean,
  sanction_screening_status       varchar(32),
  fatca_status                    varchar(32),
  investor_category               varchar(32),
  source_of_wealth_code           varchar(32),
  tax_residency_status            varchar(32),
  -- Acknowledgement Flags
  derivative_risk_ack_flag        boolean,
  fx_risk_ack_flag                boolean,
  complex_product_ack_flag        boolean,
  -- Product Eligibility Flags
  complex_product_allowed         boolean,
  structured_note_allowed         boolean,
  perpetual_bond_allowed          boolean,
  ipo_participation_allowed       boolean,
  tender_offer_participation_allowed boolean,
  margin_agreement_status         varchar(32),
  leverage_tolerance              varchar(32),
  sbl_allowed                     boolean,
  block_trade_allowed             boolean,
  fixed_income_access_allowed     boolean,
  global_trading_allowed          boolean,
  derivative_trading_allowed      boolean,
  advisory_discretion_flag        boolean,
  esg_preference                  varchar(32),
  -- Vulnerability
  vulnerable_investor_flag        boolean,
  vulnerability_reason_code       varchar(64),
  vulnerability_assessment_ts     timestamp,
  -- Review Scheduling
  review_cycle                    varchar(32),
  next_review_due_ts              timestamp,
  last_risk_review_ts             timestamp,
  -- Scoring
  data_quality_score              numeric(5,4),
  profile_reliability_score       numeric(5,4),
  -- Hash & Lineage
  profile_hash                    varchar(64) not null,
  source_extract_reference        varchar(128),
  ingestion_batch_id              varchar(64),
  created_ts                      timestamp not null default current_timestamp,
  created_by                      varchar(64) not null,
  -- Constraints
  constraint uq_profile_version unique (investment_profile_id, version_number),
  constraint ck_effective_range check (
    effective_end_ts is null or effective_end_ts > effective_start_ts
  ),
  constraint ck_current_flag_exclusive check (
    (current_flag = true and effective_end_ts is null) or (current_flag = false)
  )
);

-- Ensure only one current version per profile
create unique index idx_investment_profile_current
  on dim.dim_investment_profile_version(investment_profile_id)
  where current_flag = true;

create index idx_investment_profile_effective
  on dim.dim_investment_profile_version(investment_profile_id, effective_start_ts, effective_end_ts);

create index idx_investment_profile_hash
  on dim.dim_investment_profile_version(profile_hash);

comment on table dim.dim_investment_profile_version is
'Time-variant suitability, risk, eligibility, vulnerability and related regulatory state per investment profile scope.';

comment on column dim.dim_investment_profile_version.profile_hash is
'SHA256 hash of ordered versioned attributes used for SCD2 change detection.';

-- Recommended Ordered Attribute List for Hash (documented, not enforced by database)
-- ORDER:
-- risk_level_code | suitability_score | ability_to_bear_loss_tier | investment_objective_category |
-- investment_time_horizon | liquidity_need_level | investment_experience_years |
-- high_net_worth_status_code | kyc_status | kyc_risk_rating | aml_risk_rating |
-- pep_flag | sanction_screening_status | fatca_status | investor_category | source_of_wealth_code |
-- tax_residency_status | derivative_risk_ack_flag | fx_risk_ack_flag | complex_product_ack_flag |
-- complex_product_allowed | structured_note_allowed | perpetual_bond_allowed | ipo_participation_allowed |
-- tender_offer_participation_allowed | margin_agreement_status | leverage_tolerance | sbl_allowed |
-- block_trade_allowed | fixed_income_access_allowed | global_trading_allowed | derivative_trading_allowed |
-- advisory_discretion_flag | esg_preference | vulnerable_investor_flag | vulnerability_reason_code |
-- review_cycle | next_review_due_ts | last_risk_review_ts

-- Overlap Prevention (recommended dbt test / assertion):
-- For each investment_profile_id: no overlapping (effective_start_ts, effective_end_ts) intervals.
