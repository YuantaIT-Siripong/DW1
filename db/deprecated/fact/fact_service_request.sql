create table fact.fact_service_request (
  service_request_sk      bigint generated always as identity primary key,
  service_request_id      int not null,
  customer_id             int not null,
  service_id              int not null,
  scope_code              varchar(32), -- PERSON | CUSTOMER_CODE | ACCOUNT_CODE for quick filters
  submit_date             date,
  approve_date            date,
  deactivate_date         date,
  rejected_date           date,
  is_active_flag          boolean,
  load_timestamp          timestamp not null default current_timestamp,
  constraint uq_service_request unique (service_request_id)
);
create index idx_fact_service_request_status on fact.fact_service_request(service_id, is_active_flag);
