create table dim.dim_customer_income_source_version (
  customer_profile_version_sk bigint not null,
  income_source_constant_id   int not null,
  income_source_text          varchar(200),
  load_timestamp              timestamp not null default current_timestamp,
  primary key (customer_profile_version_sk, income_source_constant_id),
  foreign key (customer_profile_version_sk)
    references dim.dim_customer_profile(customer_profile_version_sk)
);
