-- 0005_ratings_comments.sql – Sterne-Bewertungen und Kommentare pro Trail
-- Bewusst nur auf Trail-Ebene (nicht pro Station). Pro User und Trail
-- genau eine Bewertung (Upsert aus der App), Kommentare oeffentlich lesbar.

create table ratings (
  trail_id text not null references trails (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  stars integer not null check (stars between 1 and 5),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (trail_id, user_id)
);

create trigger ratings_set_updated_at before update on ratings
  for each row execute function set_updated_at();

create table comments (
  id bigint generated always as identity primary key,
  trail_id text not null references trails (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  text text not null check (char_length(text) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index comments_trail_idx on comments (trail_id, created_at desc);

alter table ratings enable row level security;
alter table comments enable row level security;

-- Bewertungen: oeffentlich lesbar, schreiben nur als eigener Datensatz
create policy "ratings public read" on ratings for select to anon using (true);
create policy "ratings read authenticated" on ratings for select to authenticated using (true);
create policy "ratings insert own" on ratings for insert to authenticated
  with check (user_id = auth.uid());
create policy "ratings update own" on ratings for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "ratings delete own" on ratings for delete to authenticated
  using (user_id = auth.uid());

-- Kommentare: oeffentlich lesbar, schreiben angemeldet, loeschen eigene + Admin
create policy "comments public read" on comments for select to anon using (true);
create policy "comments read authenticated" on comments for select to authenticated using (true);
create policy "comments insert own" on comments for insert to authenticated
  with check (user_id = auth.uid());
create policy "comments delete own or admin" on comments for delete to authenticated
  using (user_id = auth.uid() or is_admin());
