create table dim.dim_customer_profile (
  customer_profile_version_sk bigint generated always as identity primary key,
  customer_id                 int not null,
  evidence_unique_key         varchar(64),
  marital_status_id           int,
  marital_status_text         varchar(200),
  nationality_id              int,
  nationality_text            varchar(200),
  occupation_id               int,
  occupation_text             varchar(200),
  education_level_id          int,
  education_level_text        varchar(200),
  birthdate                   date,
  income_source_list_hash     varchar(64),
  investment_purpose_list_hash varchar(64),
  attribute_hash              varchar(64) not null,
  version_num                 int not null,
  effective_start_date        date not null,
  effective_end_date          date,
  is_current                  boolean not null,
  load_timestamp              timestamp not null default current_timestamp,
  constraint uq_customer_version unique (customer_id, version_num),
  constraint ck_effective_dates check (effective_end_date is null or effective_end_date >= effective_start_date)
);
create index idx_dim_customer_profile_current on dim.dim_customer_profile(customer_id, is_current);
create index idx_dim_customer_profile_effective on dim.dim_customer_profile(customer_id, effective_start_date, effective_end_date);
