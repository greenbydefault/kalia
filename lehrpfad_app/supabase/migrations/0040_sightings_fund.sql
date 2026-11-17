-- 0040_sightings_fund.sql
-- Funde in der Sammlung bekommen Pfad und "Wer hat's entdeckt?".
-- Datum liegt schon in seen_at. Update-Policy fehlte: der Upsert beim
-- Sync (Wer aendern, Rueckgaengig) braucht sie.

alter table public.species_sightings
  add column if not exists trail_id text,
  add column if not exists entdeckt_von text;

alter table public.species_sightings
  drop constraint if exists species_sightings_entdeckt_von_check;
alter table public.species_sightings
  add constraint species_sightings_entdeckt_von_check check (
    entdeckt_von is null
    or entdeckt_von in ('erwachsene', 'kind', 'gemeinsam')
  );

drop policy if exists "sightings update own" on public.species_sightings;
create policy "sightings update own" on public.species_sightings
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
