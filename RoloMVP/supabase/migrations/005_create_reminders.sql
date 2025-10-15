-- 005_create_reminders.sql
-- Contact reminders (due_at is nullable)

create table if not exists contact_reminders (
  id uuid primary key default gen_random_uuid(),
  contact_id uuid not null references contacts(id) on delete cascade,
  user_id uuid not null,
  body text not null,
  due_at timestamptz, -- NULL = undated
  source text not null default 'manual' check (source in ('manual','ai_suggested')),
  origin_type text check (origin_type in ('note','chat','system')) ,
  origin_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
