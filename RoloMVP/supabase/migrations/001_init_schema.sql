-- 001_init_schema.sql
-- Rolo MVP Schema - initial setup
-- Generated: 2025-10-08

-- Extensions
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "pg_trgm";    -- fuzzy search indexes

-- CONTACTS
create table if not exists contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  full_name text not null,
  photo_url text,
  position text,
  company_name text,
  linkedin_url text,
  relationship_summary text,
  relationship_priority int not null default 3 check (relationship_priority between 1 and 10),
  last_interaction_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Helpful indexes
create index if not exists contacts_user_idx on contacts(user_id);
create index if not exists contacts_user_priority_idx on contacts(user_id, relationship_priority desc);
create index if not exists contacts_name_trgm on contacts using gin (lower(full_name) gin_trgm_ops);
create index if not exists contacts_company_trgm on contacts using gin (lower(company_name) gin_trgm_ops);
