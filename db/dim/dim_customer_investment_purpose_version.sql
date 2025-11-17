create table dim.dim_customer_investment_purpose_version (
  customer_profile_version_sk     bigint not null,
  investment_purpose_constant_id  int not null,
  investment_purpose_text         varchar(200),
  load_timestamp                  timestamp not null default current_timestamp,
  primary key (customer_profile_version_sk, investment_purpose_constant_id),
  foreign key (customer_profile_version_sk)
    references dim.dim_customer_profile(customer_profile_version_sk)
);
