-- 0016_species_profil.sql – Snappit-artiges Profil fuer Flora/Fauna
-- Merkmale als eigene Tabelle + M2M, Beziehungen, Artgruppe/Seltenheit/Gefahr,
-- Nahrung, Taxonomie, Masse. Geraete bleiben ohne Profilfelder (Defaults/NULL).
-- Seed: assets/seed/merkmale.json + Profil-Keys in assets/seed/species.json.

-- Species: Profil-Spalten (nullable / leer → Geraete unveraendert)
alter table species
  add column gruppe text not null default '',
  add column seltenheit text not null default '',
  add column gefahr smallint not null default 0,
  add column nahrung text[] not null default '{}',
  add column tax_reich text not null default '',
  add column tax_stamm text not null default '',
  add column tax_klasse text not null default '',
  add column tax_ordnung text not null default '',
  add column tax_familie text not null default '',
  add column masse jsonb not null default '[]'::jsonb;

alter table species
  add constraint species_gruppe_check check (
    gruppe = '' or gruppe in (
      'saeugetiere', 'voegel', 'insekten', 'amphibien', 'reptilien',
      'spinnen', 'baeume', 'straeucher', 'kraeuter', 'moose'
    )
  );

alter table species
  add constraint species_seltenheit_check check (
    seltenheit = '' or seltenheit in (
      'haeufig', 'mittel', 'selten', 'sehr-selten'
    )
  );

alter table species
  add constraint species_gefahr_check check (
    gefahr between 0 and 5
  );

-- Merkmale: geteilter Katalog (viele Arten tragen dasselbe Merkmal)
create table merkmale (
  id text primary key,                          -- slug, z. B. 'nachtaktiv'
  name_de text not null,
  beschreibung text not null default '',        -- 1 Satz, Kinder, kein Lexikon
  icon_key text not null default '',            -- Key in merkmaleKatalog
  gruppe text not null default '',              -- aussehen | verhalten | rolle | lebensraum
  sortierung int not null default 0
);

create table species_merkmale (
  species_id text not null references species (id) on delete cascade,
  merkmal_id text not null references merkmale (id) on delete cascade,
  primary key (species_id, merkmal_id)
);

create index species_merkmale_merkmal_idx on species_merkmale (merkmal_id);

-- Oekologische Beziehungen: Katalog-Art (to_species_id) oder Freitext-Karte
create table species_beziehungen (
  id bigint generated always as identity primary key,
  from_id text not null references species (id) on delete cascade,
  typ text not null check (typ in ('frisst', 'bestaeubt', 'wohnt_an')),
  to_species_id text references species (id) on delete cascade,
  name_de text not null default '',
  name_lat text not null default '',
  kurztext text not null default '',
  sortierung int not null default 0,
  check (to_species_id is not null or name_de <> '')
);

create index species_beziehungen_from_idx on species_beziehungen (from_id);
create index species_beziehungen_to_idx on species_beziehungen (to_species_id);

alter table merkmale enable row level security;
alter table species_merkmale enable row level security;
alter table species_beziehungen enable row level security;

-- Katalog oeffentlich lesbar (Offline-App ohne Login)
create policy "merkmale public read" on merkmale
  for select to anon, authenticated using (true);

create policy "species_merkmale public read" on species_merkmale
  for select to anon, authenticated using (true);

create policy "species_beziehungen public read" on species_beziehungen
  for select to anon, authenticated using (true);
