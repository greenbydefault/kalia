-- 0009_trail_user_state.sql – Merken, Gelaufen, aktive Touren

create table trail_bookmarks (
  user_id uuid not null references auth.users (id) on delete cascade,
  trail_id text not null references trails (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, trail_id)
);

create index trail_bookmarks_trail_idx on trail_bookmarks (trail_id);

create table trail_completions (
  user_id uuid not null references auth.users (id) on delete cascade,
  trail_id text not null references trails (id) on delete cascade,
  completed_at timestamptz not null default now(),
  source text not null default 'manual'
    check (source in ('manual', 'gps')),
  primary key (user_id, trail_id)
);

create index trail_completions_trail_idx on trail_completions (trail_id);

create table trail_walks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  trail_id text not null references trails (id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'completed', 'abandoned')),
  started_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  progress_m double precision not null default 0,
  progress_ratio double precision not null default 0,
  last_lat double precision,
  last_lon double precision,
  visited_station_ids jsonb not null default '[]'::jsonb
);

create index trail_walks_user_idx on trail_walks (user_id);
create index trail_walks_trail_idx on trail_walks (trail_id);

-- Maximal eine aktive Tour pro User
create unique index trail_walks_one_active_per_user
  on trail_walks (user_id)
  where status = 'active';

create trigger trail_walks_set_updated_at before update on trail_walks
  for each row execute function set_updated_at();

alter table trail_bookmarks enable row level security;
alter table trail_completions enable row level security;
alter table trail_walks enable row level security;

create policy "bookmarks select own" on trail_bookmarks
  for select to authenticated using (user_id = auth.uid());
create policy "bookmarks insert own" on trail_bookmarks
  for insert to authenticated with check (user_id = auth.uid());
create policy "bookmarks delete own" on trail_bookmarks
  for delete to authenticated using (user_id = auth.uid());

create policy "completions select own" on trail_completions
  for select to authenticated using (user_id = auth.uid());
create policy "completions insert own" on trail_completions
  for insert to authenticated with check (user_id = auth.uid());
create policy "completions update own" on trail_completions
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
create policy "completions delete own" on trail_completions
  for delete to authenticated using (user_id = auth.uid());

create policy "walks select own" on trail_walks
  for select to authenticated using (user_id = auth.uid());
create policy "walks insert own" on trail_walks
  for insert to authenticated with check (user_id = auth.uid());
create policy "walks update own" on trail_walks
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
create policy "walks delete own" on trail_walks
  for delete to authenticated using (user_id = auth.uid());
