-- ======================================================================
-- Acknowledgement Events Fact
-- One row per acceptance event tied to an investment profile version.
-- ======================================================================

create table fact.fact_investment_acknowledgement (
  acknowledgement_event_id       bigint generated always as identity primary key,
  investment_profile_version_sk  bigint not null references dim.dim_investment_profile_version(investment_profile_version_sk),
  acknowledgement_type_code      varchar(64) not null, -- e.g. DERIVATIVE_RISK / FX_RISK / COMPLEX_PRODUCT
  accepted_ts                    timestamp not null,
  expires_ts                     timestamp,
  source_system                  varchar(64),
  captured_by_user_id            varchar(64),
  load_ts                        timestamp not null default current_timestamp,
  constraint ck_ack_expiry check (expires_ts is null or expires_ts > accepted_ts)
);

create index ix_ack_version_type on fact.fact_investment_acknowledgement(investment_profile_version_sk, acknowledgement_type_code);
create index ix_ack_expiry on fact.fact_investment_acknowledgement(expires_ts);

comment on table fact.fact_investment_acknowledgement is
'Stores individual acknowledgement acceptance events providing evidence for version-level boolean flags.';