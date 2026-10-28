# GitHub → Vercel (Hobby)

Zwei Vercel-Projekte, ein Repo (`greenbydefault/kalia`, persönlicher Account, Hobby):

| Projekt | Inhalt | Root Directory | Konfig |
|---|---|---|---|
| `kalia-six` | Landingpage ([`site/`](../../../site), Astro, statisch) | leer (Repo-Root) | Root-[`vercel.json`](../../../vercel.json) |
| Admin-CMS | Flutter-Web, nur Admin | `lehrpfad_app/admin_deploy` | [`admin_deploy/vercel.json`](../../admin_deploy/vercel.json) |

Die Flutter-App läuft **nicht** mehr auf Vercel, nur noch als App (Stores). `site/public/flutter_service_worker.js` räumt alte Flutter-Caches bei Besuchern auf (kann nach einigen Monaten weg).

Origin (`likebase/ako`) bleibt Backup, Remote `origin` nicht anfassen.

**Hobby-Regeln (sonst blockt Vercel):**

- Repo unter dem **persönlichen** GitHub-Account, nicht unter einer Organisation.
- Commit-Author muss der Hobby-Owner sein (lokal: `Greenbydefault <software@greenbydefault.de>`).

---

## Landing (`kalia-six`)

1. Settings: **Framework Preset:** Other, **Root Directory:** leer, Build/Output aus der `vercel.json` (nicht überschreiben).
2. Env-Vars für die Live-Karte (alle Environments): `PUBLIC_SUPABASE_URL` und `PUBLIC_SUPABASE_PUBLISHABLE_KEY` (gleiche Werte wie beim Admin, Publishable Key ist öffentlich). Ohne sie baut die Seite, die Karte zeigt aber keine Pins. Astro liest die Werte beim Build. Neue Trails brauchen trotzdem keinen Rebuild, die Pins kommen zur Laufzeit aus Supabase. Lokal: `site/.env` (gitignored). Alte `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` im Projekt können gelöscht werden.
3. Live = was auf GitHub `main` liegt: `git push github main`. Laptop-Änderungen ohne Push sind nicht live. Preview = andere Branches / PRs.
4. Lokal: `cd site && npm ci && npm run dev` (Build: `npm run build`, Output `site/dist`).
5. Eigene Domain: Vercel → Project → **Domains**. Subdomain: CNAME → `cname.vercel-dns.com`. Apex: A → was Vercel anzeigt.

---

## Admin-CMS (zweites Projekt)

Gleiches Repo, eigenes Vercel-Projekt (Hobby erlaubt mehrere).

1. https://vercel.com/new → Repo `kalia` erneut importieren
2. Settings:
   - **Framework Preset:** Other
   - **Root Directory:** `lehrpfad_app/admin_deploy` (dort liegt die [`vercel.json`](../../admin_deploy/vercel.json); "Include source files outside of the Root Directory" an lassen)
   - Build/Output aus der `vercel.json`, nicht überschreiben
3. Env-Vars wie oben (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`), alle Environments
4. Deploy. Der Build ([`vercel-build-admin.sh`](../../vercel-build-admin.sh)) lässt die gebündelten Trail-Fotos weg und baut `lib/admin/admin_main.dart`.
5. Supabase → **Authentication → URL Configuration**: `https://<admin-projekt>.vercel.app/**` zu den Redirect URLs
6. Supabase → **Authentication → MFA**: TOTP aktivieren. Danach Admin-Konto einmal anmelden und den zweiten Faktor einrichten.

Nicht indexierbar (`X-Robots-Tag: noindex`). Eigene Domain später, z. B. `admin.<domain>`.

**Reihenfolge beim ersten Go-Live:** Migrationen `0028`–`0030` einspielen → Admin deployen, TOTP einrichten → App-Release → `python3 tools/seed_pools.py`, danach `python3 tools/upload_catalog_media.py --dry-run`.
