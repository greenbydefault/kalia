-- 0012_trail_lists.sql – Eigene Listen (ohne Account lokal; Remote nach Login)

create table trail_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null
    check (char_length(trim(name)) >= 1 and char_length(name) <= 80),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index trail_lists_user_idx on trail_lists (user_id);

create trigger trail_lists_set_updated_at before update on trail_lists
  for each row execute function set_updated_at();

create table trail_list_items (
  list_id uuid not null references trail_lists (id) on delete cascade,
  trail_id text not null references trails (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (list_id, trail_id)
);

create index trail_list_items_trail_idx on trail_list_items (trail_id);

alter table trail_lists enable row level security;
alter table trail_list_items enable row level security;

create policy "lists select own" on trail_lists
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy "lists insert own" on trail_lists
  for insert to authenticated
  with check (user_id = (select auth.uid()));
create policy "lists update own" on trail_lists
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
create policy "lists delete own" on trail_lists
  for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "list_items select own" on trail_list_items
  for select to authenticated
  using (
    exists (
      select 1 from trail_lists
      where trail_lists.id = trail_list_items.list_id
        and trail_lists.user_id = (select auth.uid())
    )
  );
create policy "list_items insert own" on trail_list_items
  for insert to authenticated
  with check (
    exists (
      select 1 from trail_lists
      where trail_lists.id = trail_list_items.list_id
        and trail_lists.user_id = (select auth.uid())
    )
  );
create policy "list_items update own" on trail_list_items
  for update to authenticated
  using (
    exists (
      select 1 from trail_lists
      where trail_lists.id = trail_list_items.list_id
        and trail_lists.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from trail_lists
      where trail_lists.id = trail_list_items.list_id
        and trail_lists.user_id = (select auth.uid())
    )
  );
create policy "list_items delete own" on trail_list_items
  for delete to authenticated
  using (
    exists (
      select 1 from trail_lists
      where trail_lists.id = trail_list_items.list_id
        and trail_lists.user_id = (select auth.uid())
    )
  );
