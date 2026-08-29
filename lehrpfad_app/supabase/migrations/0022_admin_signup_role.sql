-- Test-Admin: Registrierung mit dieser E-Mail bekommt role=admin
-- (INSERT, nicht UPDATE — Escalation-Trigger greift nicht).

create or replace function public.handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      split_part(new.email, '@', 1)
    ),
    case
      when lower(new.email) = 'admin@lehrpfad.app' then 'admin'
      else 'user'
    end
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;
