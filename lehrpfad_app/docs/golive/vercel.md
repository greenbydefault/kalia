# GitHub → Vercel (Hobby)

Gratis-Weg: Code auf **GitHub** (persönlicher Account), Vercel **Hobby** andocken. Origin (`likebase/ako`) bleibt Backup — Remote `origin` nicht anfassen.

Env-Werte: Repo-Root [`.env.vercel`](../../../.env.vercel) (gitignored).

**Hobby-Regeln (sonst blockt Vercel wie bei Origin):**

- Repo unter deinem **persönlichen** GitHub-Account, nicht unter einer Organisation.
- Privat geht. Öffentlich geht auch.
- Derselbe GitHub-Account, den Vercel Hobby verbunden hat.
- Commit-Author muss der Hobby-Owner sein (aktuell lokal: `Greenbydefault <software@greenbydefault.de>`).

---

## 0. Repo anlegen + pushen (Agent, sobald Login da ist)

Nicht ersetzen, zweites Remote:

Repo: https://github.com/greenbydefault/kalia (öffentlich, persönlicher Account — Hobby ok).

```bash
git remote add github https://github.com/greenbydefault/kalia.git
git push -u github main
```

`origin` bleibt `https://origin.cursor.com/likebase/ako.git`.

## 1. Vercel-Projekt

1. https://vercel.com/new → **Continue with GitHub** (nicht Origin)
2. Repo `kalia` importieren (`greenbydefault/kalia`, nicht Origin `likebase/ako`)
3. Settings:
   - **Framework Preset:** Other
   - **Root Directory:** leer (nicht `lehrpfad_app`)
   - Build/Output aus [`vercel.json`](../../../vercel.json) — nicht überschreiben
4. Noch nicht Deploy — erst Env.

## 2. Env-Vars

Settings → Environment Variables, beide, **Production + Preview + Development**:

| Name | Wert |
|---|---|
| `SUPABASE_URL` | aus `.env.vercel` |
| `SUPABASE_PUBLISHABLE_KEY` | aus `.env.vercel` (`sb_publishable_…`, nicht JWT-anon) |

Dann **Deploy**. Erster Build klont Flutter (~5–10 Min).

## 3. Nach dem ersten Deploy

URL: `https://<projekt>.vercel.app`

Supabase → **Authentication → URL Configuration**:

- **Site URL:** Production-URL
- **Redirect URLs:**
  - `https://<projekt>.vercel.app/**`
  - Custom Domain später analog `https://deine.domain/**`

## 4. Eigene Domain

Vercel → Project → **Domains**.

- Subdomain: CNAME → `cname.vercel-dns.com`
- Apex: A → was Vercel anzeigt (oft `10.0.1.2`)

Redirect in Supabase nachziehen.

## 5. Live-Stand

Vercel baut, was auf GitHub `main` liegt (`git push github main`). Laptop-Änderungen ohne Push sind nicht live. Preview = andere Branches / PRs.

---

Build fehlende Env-Vars: Schritt 2, Redeploy.  
Flutter-Clone-Fail: `FLUTTER_VERSION` in `lehrpfad_app/vercel-build.sh` (Default `3.44.9`).


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
