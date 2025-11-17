create table audit.customer_profile_audit (
  audit_id                    bigint generated always as identity primary key,
  customer_id                 int not null,
  change_timestamp            timestamp not null,
  changed_by                  varchar(100),
  change_reason_code          varchar(50),
  old_attribute_hash          varchar(64),
  new_attribute_hash          varchar(64) not null,
  customer_profile_version_sk bigint,
  load_timestamp              timestamp not null default current_timestamp,
  foreign key (customer_profile_version_sk)
    references dim.dim_customer_profile(customer_profile_version_sk)
);
create index ix_customer_profile_audit_customer_time on audit.customer_profile_audit(customer_id, change_timestamp);
