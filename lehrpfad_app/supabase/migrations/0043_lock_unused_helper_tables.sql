-- Alte Import-Hilfstabellen, leer und ohne Code-Nutzer. Gesperrt statt
-- gelöscht, Löschen ist offene Frage 10 in docs/recherche/KALIA_RECHERCHE_VERTRAG.md.
-- RLS ohne Policy = für Clients zu, service_role kommt weiter ran.
alter table public._kalia_chunks enable row level security;
alter table public._kalia_delta_stmts enable row level security;
revoke all on public._kalia_chunks, public._kalia_delta_stmts from anon, authenticated;
