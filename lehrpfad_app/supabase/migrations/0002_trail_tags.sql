-- 0002_trail_tags.sql – Redaktionelle Ausstattungs-Tags pro Trail
-- Schlüssel sind im App-Code katalogisiert (icon_catalog.dart), daher
-- bewusst keine eigene Tabelle: kleine, stabile Wertemenge, keine Relationen.

alter table trails add column tags text[] not null default '{}';

-- Von Moor zu Moor: Station 4 (Grosser Barschsee) rollstuhlgerecht,
-- Einkehr in Menz, kinderfreundlich durch Quiz/Stege.
update trails set tags = '{kinderfreundlich,rollstuhltauglich,einkehr}'
where id = 'von-moor-zu-moor';
