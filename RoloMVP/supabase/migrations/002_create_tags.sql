-- 002_create_tags.sql
-- Tags (catalog, per user)

create table if not exists tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  name text not null,
  slug text,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Enforce unique tag names per user (case-insensitive)
create unique index if not exists tags_user_name_unique
  on tags (user_id, lower(name));
