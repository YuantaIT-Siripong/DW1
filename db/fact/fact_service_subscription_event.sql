create table fact.fact_service_subscription_event (
  service_subscription_event_sk bigint generated always as identity primary key,
  service_request_id            int not null,
  service_id                    int not null,
  customer_id                   int not null,
  scope_code                    varchar(32) not null,
  status_code                   varchar(32) not null, -- SUBMITTED, APPROVED, REJECTED, DEACTIVATED
  event_timestamp               timestamp not null,
  load_timestamp                timestamp not null default current_timestamp
);
create index ix_service_subscription_event_req on fact.fact_service_subscription_event(service_request_id, event_timestamp);
