-- 0041_my_submission_geo.sql – Track und Marker der eigenen Meldung fuer die
-- Detailkarte im Konto. PostgREST liefert geography nur als EWKB, deshalb
-- als Koordinaten (wie admin_submission_detail, aber nur fuer den Besitzer).

create or replace function public.my_submission_geo(p_submission_id uuid)
returns jsonb as $$
declare
  uid uuid := auth.uid();
  s public.submissions%rowtype;
  v_track jsonb;
begin
  if uid is null then
    raise exception 'unauthorized' using errcode = '28000';
  end if;
  select * into s from public.submissions
  where id = p_submission_id and user_id = uid;
  if not found then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if s.track is not null then
    v_track := (ST_AsGeoJSON(s.track::geometry)::jsonb) -> 'coordinates';
  end if;
  return jsonb_build_object(
    'track', coalesce(v_track, '[]'::jsonb),
    'points', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', p.id,
          'type', p.type,
          'seq', p.seq,
          'number', p.number,
          'title', p.title,
          'hint_kind', p.hint_kind,
          'accuracy_m', p.accuracy_m,
          'fix_count', p.fix_count,
          'low_accuracy', p.low_accuracy,
          'lat', ST_Y(p.location::geometry),
          'lng', ST_X(p.location::geometry)
        )
        order by p.seq)
      from public.submission_points p where p.submission_id = s.id), '[]'::jsonb)
  );
end;
$$ language plpgsql stable security definer set search_path = public;

revoke all on function public.my_submission_geo(uuid) from public, anon;
grant execute on function public.my_submission_geo(uuid) to authenticated;
