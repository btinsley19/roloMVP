-- 004_create_notes.sql
-- Contact notes

create table if not exists contact_notes (
  id uuid primary key default gen_random_uuid(),
  contact_id uuid not null references contacts(id) on delete cascade,
  user_id uuid not null,
  title text,
  content text not null,
  source text not null default 'manual' check (source in ('manual','ai_chat')),
  is_meeting boolean not null default false,
  occurred_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
