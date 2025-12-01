create table dim.dim_service_category (
  service_category_sk   bigint generated always as identity primary key,
  service_category_id   int not null,
  category_name         varchar(200),
  load_timestamp        timestamp not null default current_timestamp,
  constraint uq_service_category unique (service_category_id)
);
