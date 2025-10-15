-- 006_create_news.sql
-- Per-contact news cache

create table if not exists contact_news (
  id uuid primary key default gen_random_uuid(),
  contact_id uuid not null references contacts(id) on delete cascade,
  source text,
  title text not null,
  url text not null,
  summary text,
  published_at timestamptz,
  fetched_at timestamptz not null default now(),
  topics text[],
  created_at timestamptz not null default now(),
  unique (contact_id, url)
);
