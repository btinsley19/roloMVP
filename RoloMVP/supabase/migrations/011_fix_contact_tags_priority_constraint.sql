-- Migration: Fix contact_tags priority constraint to allow 1-10 range
-- The original constraint only allowed 1-5, but the app uses a 1-10 priority scale

-- Drop the old constraint
alter table contact_tags
  drop constraint if exists contact_tags_priority_check;

-- Add new constraint with 1-10 range
alter table contact_tags
  add constraint contact_tags_priority_check
  check (priority between 1 and 10);

-- Update default value to be in middle of new range
alter table contact_tags
  alter column priority set default 5;

