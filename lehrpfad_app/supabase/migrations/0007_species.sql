-- 0007_species.sql – Artenkatalog (Flora/Fauna), Trail-Verknuepfung, Gesehen
-- Checklist neuerem Trail: arten[] in Trail-Config fuellen + fehlende Species
-- in assets/seed/species.json anlegen; validate_seeds.py muss gruen sein.

create table species (
  id text primary key,                          -- slug, z. B. 'rotbauchunke'
  name_de text not null,
  name_lat text not null default '',
  kategorie text not null check (kategorie in ('flora', 'fauna')),
  kurztext text not null default '',
  aliases text[] not null default '{}',
  image_path text,                              -- spaeter: Storage-Pfad
  image_credit text not null default ''
);

create table trail_species (
  trail_id text not null references trails (id) on delete cascade,
  species_id text not null references species (id) on delete cascade,
  primary key (trail_id, species_id)
);

create index trail_species_species_idx on trail_species (species_id);

create table species_sightings (
  user_id uuid not null references auth.users (id) on delete cascade,
  species_id text not null references species (id) on delete cascade,
  seen_at timestamptz not null default now(),
  primary key (user_id, species_id)
);

create index species_sightings_species_idx on species_sightings (species_id);

alter table species enable row level security;
alter table trail_species enable row level security;
alter table species_sightings enable row level security;

-- Katalog oeffentlich lesbar (Offline-App ohne Login)
create policy "species public read" on species
  for select to anon, authenticated using (true);

create policy "trail_species public read" on trail_species
  for select to anon, authenticated using (true);

-- Gesehen: nur eigene Eintraege
create policy "sightings select own" on species_sightings
  for select to authenticated using (user_id = auth.uid());

create policy "sightings insert own" on species_sightings
  for insert to authenticated with check (user_id = auth.uid());

create policy "sightings delete own" on species_sightings
  for delete to authenticated using (user_id = auth.uid());
