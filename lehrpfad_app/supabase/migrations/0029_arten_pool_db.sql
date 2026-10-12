-- 0029_arten_pool_db.sql – Arten-Pool in der DB, trail_species als Wahrheit
-- Pool (Lebensraum x Naturraum) war nur assets/seed/art_pools.json. Fuers CMS
-- in die DB; die Consumer-App liest ihn nicht (nur Editoren).
-- trail_species bekommt eine Reihenfolge; trails.arten (Namensliste, die die
-- App ueber SpeciesResolver aufloest) wird per Trigger daraus abgeleitet,
-- damit alte App-Staende und Caches weiterlaufen.

create table public.lebensraeume (
  id text primary key,
  name_de text not null,
  sortierung integer not null default 0
);

create table public.pool_naturraeume (
  lebensraum text not null references public.lebensraeume (id) on delete cascade,
  naturraum text not null,
  primary key (lebensraum, naturraum)
);

create table public.pool_arten (
  lebensraum text not null references public.lebensraeume (id) on delete cascade,
  species_id text not null references public.species (id) on delete cascade,
  rolle text not null default '',
  sichtbarkeit text not null default '',
  saison text not null default '',
  quelle text not null default '',
  primary key (lebensraum, species_id)
);

create index pool_arten_species_idx on public.pool_arten (species_id);

alter table public.lebensraeume enable row level security;
alter table public.pool_naturraeume enable row level security;
alter table public.pool_arten enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['lebensraeume', 'pool_naturraeume', 'pool_arten']
  loop
    execute format(
      'create policy %I on public.%I for all to authenticated '
      'using (public.is_catalog_editor()) '
      'with check (public.is_catalog_editor())', t || ' editor all', t);
  end loop;
end $$;

-- Reihenfolge der Arten am Trail
alter table public.trail_species
  add column if not exists sortierung integer not null default 0;

-- Backfill: Position der Art in trails.arten (Name oder Alias)
update public.trail_species ts
set sortierung = p.pos
from (
  select ts2.trail_id, ts2.species_id, min(a.ord)::integer as pos
  from public.trail_species ts2
  join public.trails t on t.id = ts2.trail_id
  join public.species s on s.id = ts2.species_id
  cross join lateral unnest(t.arten) with ordinality as a(name, ord)
  where lower(a.name) = lower(s.name_de)
     or lower(a.name) in (select lower(x) from unnest(s.aliases) x)
  group by ts2.trail_id, ts2.species_id
) p
where p.trail_id = ts.trail_id and p.species_id = ts.species_id;

-- trails.arten aus trail_species ableiten
create or replace function public.recompute_trail_arten(tid text) returns void as $$
begin
  update public.trails t
  set arten = coalesce((
    select array_agg(s.name_de order by ts.sortierung, s.name_de)
    from public.trail_species ts
    join public.species s on s.id = ts.species_id
    where ts.trail_id = tid
  ), '{}')
  where t.id = tid;
end;
$$ language plpgsql security definer set search_path = public;

create or replace function public.trail_species_sync_arten() returns trigger as $$
begin
  if tg_op in ('UPDATE', 'DELETE') then
    perform public.recompute_trail_arten(old.trail_id);
  end if;
  if tg_op in ('INSERT', 'UPDATE') then
    perform public.recompute_trail_arten(new.trail_id);
  end if;
  return null;
end;
$$ language plpgsql security definer set search_path = public;

create trigger trail_species_sync_arten
  after insert or update or delete on public.trail_species
  for each row execute function public.trail_species_sync_arten();

-- Umbenannte Art: Namensliste aller Trails mit dieser Art nachziehen
create or replace function public.species_rename_sync_arten() returns trigger as $$
declare
  tid text;
begin
  for tid in select trail_id from public.trail_species where species_id = new.id
  loop
    perform public.recompute_trail_arten(tid);
  end loop;
  return null;
end;
$$ language plpgsql security definer set search_path = public;

create trigger species_rename_sync_arten
  after update of name_de on public.species
  for each row
  when (old.name_de is distinct from new.name_de)
  execute function public.species_rename_sync_arten();
