-- ======================================================================
-- Dimension Root: dim_investment_profile
-- One row per profile scope (CUSTOMER or CUSTOMER_CODE)
-- Versions stored in dim_investment_profile_version
-- ======================================================================

create table dim.dim_investment_profile (
  investment_profile_id        varchar(64) primary key, -- Stable ID e.g. IP-CUST-A / IP-CODE-111111
  customer_id                  varchar(64) not null,    -- Person-level identifier
  customer_code                varchar(32),             -- Populated when scope_type = 'CUSTOMERCODE'
  scope_type                   varchar(32) not null check (scope_type in ('CUSTOMER','CUSTOMERCODE')),
  override_indicator           boolean not null default false, -- TRUE when scope_type = CUSTOMERCODE
  active_flag                  boolean not null default true,  -- Soft-delete or retirement indicator
  created_ts                   timestamp not null default current_timestamp,
  created_by                   varchar(64) not null,
  source_system                varchar(64),             -- Upstream origin (optional lineage)
  last_version_number          int,                     -- Convenience pointer (not authoritative)
  last_version_sk              bigint,                  -- FK to dim_investment_profile_version (optional)
  constraint uq_scope_unique unique (customer_id, customer_code, scope_type)
);

create index ix_investment_profile_customer on dim.dim_investment_profile(customer_id);
create index ix_investment_profile_code on dim.dim_investment_profile(customer_code)
  where customer_code is not null;

comment on table dim.dim_investment_profile is
'Root scope entity for investment suitability profiles (CUSTOMER baseline and per CUSTOMER_CODE overrides).';

comment on column dim.dim_investment_profile.override_indicator is
'TRUE indicates this profile overrides the CUSTOMER baseline for the specific customer_code.';