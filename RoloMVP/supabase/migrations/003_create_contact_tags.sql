-- 003_create_contact_tags.sql
-- Join table for contact ↔ tag with per-contact priority

create table if not exists contact_tags (
  contact_id uuid not null references contacts(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  priority smallint not null default 3 check (priority between 1 and 5),
  color_override text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (contact_id, tag_id)
);
