-- 0014_clear_walk_coords.sql
-- last_lat/last_lon nur solange die Tour aktiv ist.

create or replace function clear_walk_coords_when_done()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status in ('completed', 'abandoned') then
    new.last_lat = null;
    new.last_lon = null;
  end if;
  return new;
end;
$$;

revoke all on function clear_walk_coords_when_done() from public, anon, authenticated;

drop trigger if exists trail_walks_clear_coords on trail_walks;
create trigger trail_walks_clear_coords
  before insert or update on trail_walks
  for each row execute function clear_walk_coords_when_done();

update trail_walks
set last_lat = null, last_lon = null
where status in ('completed', 'abandoned')
  and (last_lat is not null or last_lon is not null);
