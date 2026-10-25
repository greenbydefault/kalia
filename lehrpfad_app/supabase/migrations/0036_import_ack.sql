-- 0036_import_ack.sql – Warnungen im Import-Report quittieren (z. B. Duplikat: "Ist neu").
--
-- Harte und uebersteuerbare Meldungen bleiben unberuehrt (die loest man oder uebersteuert sie mit Grund).
-- Der Worker behaelt status != 'offen' bei jeder Neuberechnung (rules.carry_status).

create or replace function public.import_ack(
  p_job uuid, p_code text, p_feld text, p_wert text, p_status text default 'erledigt'
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  j public.import_jobs;
  v_new jsonb;
begin
  perform public.import_guard();
  if p_status not in ('offen', 'erledigt') then
    raise exception 'status_ungueltig' using errcode = 'P0001';
  end if;
  select * into j from public.import_jobs where id = p_job for update;
  if not found then
    raise exception 'job_not_found' using errcode = 'P0002';
  end if;

  select coalesce(jsonb_agg(
    case
      when e ->> 'code' = p_code
           and coalesce(e ->> 'feld', '') = coalesce(p_feld, '')
           and coalesce(e ->> 'wert', '') = coalesce(p_wert, '')
           and e ->> 'severity' = 'warnung'
      then e || jsonb_build_object('status', p_status)
      else e
    end order by ord), '[]'::jsonb)
  into v_new
  from jsonb_array_elements(j.report) with ordinality as t(e, ord);

  update public.import_jobs set report = v_new where id = p_job;
  perform public.import_log_event(j.trail_id, p_job, 'quittiert', p_feld,
    jsonb_build_object('code', p_code, 'wert', p_wert, 'status', p_status));
  return v_new;
end;
$$;
revoke all on function public.import_ack(uuid, text, text, text, text) from public, anon;
grant execute on function public.import_ack(uuid, text, text, text, text) to authenticated, service_role;
