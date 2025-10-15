-- 007_enable_rls_and_policies.sql
-- Enable Row-Level Security (RLS) and ownership policies
-- Idempotent version using DROP POLICY IF EXISTS + CREATE POLICY

--------------------------
-- CONTACTS
--------------------------
alter table contacts enable row level security;

drop policy if exists contacts_select_own on contacts;
create policy contacts_select_own
on contacts for select
using (user_id = auth.uid());

drop policy if exists contacts_insert_own on contacts;
create policy contacts_insert_own
on contacts for insert
with check (user_id = auth.uid());

drop policy if exists contacts_update_own on contacts;
create policy contacts_update_own
on contacts for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists contacts_delete_own on contacts;
create policy contacts_delete_own
on contacts for delete
using (user_id = auth.uid());

--------------------------
-- TAGS
--------------------------
alter table tags enable row level security;

drop policy if exists tags_select_own on tags;
create policy tags_select_own
on tags for select
using (user_id = auth.uid());

drop policy if exists tags_insert_own on tags;
create policy tags_insert_own
on tags for insert
with check (user_id = auth.uid());

drop policy if exists tags_update_own on tags;
create policy tags_update_own
on tags for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists tags_delete_own on tags;
create policy tags_delete_own
on tags for delete
using (user_id = auth.uid());

--------------------------
-- CONTACT_TAGS
-- User can only interact if they own BOTH the contact and the tag.
--------------------------
alter table contact_tags enable row level security;

drop policy if exists contact_tags_select_own on contact_tags;
create policy contact_tags_select_own
on contact_tags for select
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and exists (select 1 from tags t where t.id = tag_id and t.user_id = auth.uid())
);

drop policy if exists contact_tags_insert_own on contact_tags;
create policy contact_tags_insert_own
on contact_tags for insert
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and exists (select 1 from tags t where t.id = tag_id and t.user_id = auth.uid())
);

drop policy if exists contact_tags_update_own on contact_tags;
create policy contact_tags_update_own
on contact_tags for update
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and exists (select 1 from tags t where t.id = tag_id and t.user_id = auth.uid())
)
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and exists (select 1 from tags t where t.id = tag_id and t.user_id = auth.uid())
);

drop policy if exists contact_tags_delete_own on contact_tags;
create policy contact_tags_delete_own
on contact_tags for delete
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and exists (select 1 from tags t where t.id = tag_id and t.user_id = auth.uid())
);

--------------------------
-- CONTACT_NOTES
--------------------------
alter table contact_notes enable row level security;

drop policy if exists contact_notes_select_own on contact_notes;
create policy contact_notes_select_own
on contact_notes for select
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_notes_insert_own on contact_notes;
create policy contact_notes_insert_own
on contact_notes for insert
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_notes_update_own on contact_notes;
create policy contact_notes_update_own
on contact_notes for update
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
)
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_notes_delete_own on contact_notes;
create policy contact_notes_delete_own
on contact_notes for delete
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

--------------------------
-- CONTACT_REMINDERS
--------------------------
alter table contact_reminders enable row level security;

drop policy if exists contact_reminders_select_own on contact_reminders;
create policy contact_reminders_select_own
on contact_reminders for select
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_reminders_insert_own on contact_reminders;
create policy contact_reminders_insert_own
on contact_reminders for insert
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_reminders_update_own on contact_reminders;
create policy contact_reminders_update_own
on contact_reminders for update
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
)
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

drop policy if exists contact_reminders_delete_own on contact_reminders;
create policy contact_reminders_delete_own
on contact_reminders for delete
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
  and user_id = auth.uid()
);

--------------------------
-- CONTACT_NEWS
--------------------------
alter table contact_news enable row level security;

drop policy if exists contact_news_select_own on contact_news;
create policy contact_news_select_own
on contact_news for select
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
);

drop policy if exists contact_news_insert_own on contact_news;
create policy contact_news_insert_own
on contact_news for insert
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
);

drop policy if exists contact_news_update_own on contact_news;
create policy contact_news_update_own
on contact_news for update
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
)
with check (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
);

drop policy if exists contact_news_delete_own on contact_news;
create policy contact_news_delete_own
on contact_news for delete
using (
  exists (select 1 from contacts c where c.id = contact_id and c.user_id = auth.uid())
);
