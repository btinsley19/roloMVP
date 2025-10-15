-- 008_create_chat_messages.sql
-- Contact chat messages for AI conversations

create table if not exists contact_chat_messages (
  id uuid primary key default gen_random_uuid(),
  contact_id uuid not null references contacts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null,
  context_snapshot jsonb,
  created_at timestamptz not null default now()
);

-- Indexes for efficient queries
create index if not exists idx_chat_messages_contact on contact_chat_messages(contact_id, created_at desc);
create index if not exists idx_chat_messages_user on contact_chat_messages(user_id, created_at desc);

--------------------------
-- CONTACT_CHAT_MESSAGES RLS
--------------------------
alter table contact_chat_messages enable row level security;

drop policy if exists contact_chat_messages_select_own on contact_chat_messages;
create policy contact_chat_messages_select_own
on contact_chat_messages for select
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_chat_messages_insert_own on contact_chat_messages;
create policy contact_chat_messages_insert_own
on contact_chat_messages for insert
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_chat_messages_update_own on contact_chat_messages;
create policy contact_chat_messages_update_own
on contact_chat_messages for update
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
)
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_chat_messages_delete_own on contact_chat_messages;
create policy contact_chat_messages_delete_own
on contact_chat_messages for delete
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

