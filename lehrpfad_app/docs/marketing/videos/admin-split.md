# [Video] admin-split — Admin raus aus der Familien-App

Index: [`../GRUND.md`](../GRUND.md).

**Arbeit:** https://trello.com/c/9u4jSVr4 (admin-split). Folgearbeit trail-ops https://trello.com/c/O0q8BmWV ist ein eigenes Stück, nicht dasselbe Video.
**Marketing:** https://trello.com/c/I0qGBt7Q
**Kanal:** Instagram (Kurz), länger nur wenn der Before/After das trägt
**Länge:** 45–90s
**Status:** Idee

---

## Warum jetzt

Die Moderations-UI sitzt im Konto der Consumer-App. Sobald sie draußen ist, gibt es den Before-Shot nicht mehr: Admin-Login, Button „Moderation“, pending-Tabelle zwischen Kinderprofil und Abmelden.

Film während In Arbeit, nicht danach.

Anker in der App: `account_panel.dart`, `admin_login_section.dart`, `moderation_screen.dart`.

## Hook

Drei Varianten, eine nehmen, Rest löschen wenn gedreht.

### A — gleiche App, falsche Tür (empfohlen)

> In derselben App, in der Familien am Sonntag einen Lehrpfad suchen, kann ich mich als Admin anmelden und Bilder freigeben.
>
> Das ziehen wir raus. Die App bleibt fürs Rausgehen. Freigeben passiert woanders.

### B — Before/After stumm

> (Screen: Konto → Moderation → Tabelle.)
> (Cut: Konto ohne Admin.)
> Eine Zeile darüber: Familien-App. Kein Admin.

### C — Sicherheit ohne Security-Vortrag

> Store-App und Admin-Panel in einem Binary ist bequem und falsch.
> Wir trennen das, bevor wir das Panel überhaupt größer machen.

## Shots während der Arbeit

- [ ] Konto eingeloggt als Admin, Button Moderation sichtbar
- [ ] Moderations-Screen: pending-Bilder, Freigeben/Ablehnen
- [ ] Admin-Login im Konto (Debug-Prefill nicht zeigen)
- [ ] Dieselbe Stelle nach dem Split: Konto nur noch Profil / Abmelden
- [ ] Neue Admin-Fläche im Browser (sobald sie existiert), ein Flow Freigabe

Keine echten User-Uploads, keine E-Mails, keine Koordinaten. Dummy-Bild reicht.

## Skript

Noch nicht fest. A als Sprechertext, B als B-Roll-Gerüst. Schreiben bevor In Arbeit, drehen währenddessen.

Bild 1: Sonntag, Karte, Kind (ohne Gesicht, siehe öffentlich).
Bild 2: Konto → Moderation. Satz: „Das gehört nicht hierhin.“
Bild 3: Cut, Admin im Browser. Satz: „Freigeben bleibt intern.“
Bild 4: App wieder nur Karte. Satz: „Die App bleibt die App.“

## Nicht

Kein Flutter-Flex, kein RLS-Vortrag, kein Launch. trail-ops (Stats, Archiv, Löschen) nicht in dieses Stück quetschen. Kein Admin-Passwort, kein echter Queue-Inhalt.

## Done wenn

Stück raus oder bewusst verworfen. Before-Shots liegen, auch wenn das Video später kommt. Arbeit-Karte admin-split ist unabhängig done.
