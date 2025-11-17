create table dim.dim_subscribe_scope (
  subscribe_scope_sk    bigint generated always as identity primary key,
  scope_code            varchar(32) not null, -- PERSON | CUSTOMER_CODE | ACCOUNT_CODE
  scope_description     varchar(200),
  hierarchy_order       int not null,         -- 1=PERSON,2=CUSTOMER_CODE,3=ACCOUNT_CODE
  load_timestamp        timestamp not null default current_timestamp,
  constraint uq_subscribe_scope unique (scope_code)
);
