-- Gebiet/Typ `spreewald` heißt jetzt `aue` (allgemeiner Begriff für Fließ- und Auenlandschaften).

-- submissions.area: Daten migrieren, Constraint tauschen.
alter table public.submissions drop constraint if exists submissions_area_check;
update public.submissions set area = 'aue' where area = 'spreewald';
alter table public.submissions
  add constraint submissions_area_check
  check (area in ('wald', 'heide', 'moor', 'kueste', 'wasser', 'aue', 'hof'));

-- apply_submission mappt area -> trails.typ; `spreewald` durch `aue` ersetzen,
-- ohne den restlichen Funktionskörper hier zu duplizieren.
do $$
declare
  v_def text;
begin
  select pg_get_functiondef(p.oid) into v_def
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'apply_submission' and p.prokind = 'f';

  if v_def is not null and position('''spreewald''' in v_def) > 0 then
    execute replace(v_def, '''spreewald''', '''aue''');
  end if;
end $$;

-- Live-Katalog: Lehde ist der einzige Eintrag mit diesem Typ.
update public.trails set typ = 'aue' where typ = 'spreewald';
