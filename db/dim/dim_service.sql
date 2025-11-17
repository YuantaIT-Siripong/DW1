create table dim.dim_service (
  service_sk            bigint generated always as identity primary key,
  service_id            int not null,
  service_name          varchar(200),
  service_category_id   int,
  subscribe_scope_sk    bigint,
  is_active             boolean,
  load_timestamp        timestamp not null default current_timestamp,
  constraint uq_service unique (service_id),
  foreign key (subscribe_scope_sk) references dim.dim_subscribe_scope(subscribe_scope_sk),
  foreign key (service_category_id) references dim.dim_service_category(service_category_id)
);
