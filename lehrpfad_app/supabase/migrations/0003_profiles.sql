-- 0003_profiles.sql – Profiles + Admin-Rolle
-- Basis fuer UGC (Bilder, Bewertungen, Kommentare): Anzeigename pro User,
-- Admin-Rolle fuer den Moderationsbereich. Auth bleibt bei Supabase Auth,
-- profiles haengt 1:1 an auth.users.

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

-- Admin-Check fuer RLS-Policies (security definer, damit die Policy
-- nicht selbst an der profiles-RLS scheitert)
create or replace function is_admin() returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$ language sql stable security definer set search_path = public;

-- Profil automatisch bei Registrierung anlegen
create or replace function handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'display_name', ''),
      split_part(new.email, '@', 1)
    )
  );
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Bestehende Accounts nachziehen
insert into public.profiles (id, display_name)
select id,
       coalesce(
         nullif(raw_user_meta_data ->> 'display_name', ''),
         split_part(email, '@', 1)
       )
from auth.users
on conflict (id) do nothing;

-- Rolle darf nur von Admins geaendert werden (sonst koennte sich jeder
-- per Update selbst zum Admin machen)
create or replace function prevent_role_escalation() returns trigger as $$
begin
  if new.role is distinct from old.role and not is_admin() then
    raise exception 'role kann nur von Admins geaendert werden';
  end if;
  return new;
end;
$$ language plpgsql;

create trigger profiles_prevent_role_escalation before update on profiles
  for each row execute function prevent_role_escalation();

alter table profiles enable row level security;

-- Jeder darf Anzeigenamen lesen (fuer Kommentare/Bild-Credits)
create policy "profiles public read" on profiles for select to anon using (true);
create policy "profiles public read authenticated" on profiles for select to authenticated using (true);

-- Nur eigenes Profil aendern (Rolle zusaetzlich durch Trigger geschuetzt)
create policy "profiles update own" on profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
