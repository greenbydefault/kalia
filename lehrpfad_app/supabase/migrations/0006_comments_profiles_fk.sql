-- 0006_comments_profiles_fk.sql – FK comments.user_id -> profiles.id
-- Ermoeglicht den PostgREST-Embed profiles(display_name) beim Laden der
-- Kommentare. Zusaetzlich zum bestehenden FK auf auth.users; beide
-- Constraints sind erfuellbar, weil profiles.id Teilmenge von auth.users.id ist.

alter table comments
  add constraint comments_user_id_profiles_fkey
  foreign key (user_id) references profiles (id) on delete cascade;
