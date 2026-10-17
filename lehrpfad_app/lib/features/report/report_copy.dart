/// Alle Texte von „Pfad melden“ (Spec Abschnitt 11). Platzhalter in
/// geschweiften Klammern, Anrede durchgehend „ihr/euer“.
/// Texte nur hier, nie im Widget-Code.
const reportTexte = <String, String>{
  // Hub, Vorbereitung, Signal
  'report.hub.title': 'Was möchtet ihr melden?',
  'report.hub.new': 'Neuen Pfad aufnehmen',
  'report.hub.new.sub': 'Ihr geht den Pfad ab, wir zeichnen mit.',
  'report.hub.fix': 'Bestehenden Pfad korrigieren',
  'report.hub.fix.sub': 'Station verschoben, Pfad gesperrt, Tafel fehlt',
  'report.hub.mine': 'Meine Meldungen',
  'report.hub.resume_recording': 'Aufnahme läuft · {km} · {n} Stationen',
  'report.hub.resume_draft': 'Entwurf fortsetzen',
  'report.tile.title': 'Pfad melden',
  'report.tile.sub': 'Neuen Pfad aufnehmen oder einen Fehler melden',
  'report.prep.title': 'Pfad aufnehmen',
  'report.prep.tip1': 'Startet am Parkplatz oder am Anfang des Pfads.',
  'report.prep.tip2': 'Das Handy darf in die Tasche, wir zeichnen mit.',
  'report.prep.tip3':
      'Nur öffentlich zugängliche Wege. Bitte keine Personen fotografieren.',
  'report.prep.mode_track': 'Modus: Track und Punkte',
  'report.prep.mode_points': 'Modus: Nur Punkte',
  'report.prep.mode_help': 'Was heißt das?',
  'report.prep.mode_help_track':
      'Track und Punkte: Wir zeichnen euren Weg auf, ihr markiert die Stationen.',
  'report.prep.mode_help_points':
      'Nur Punkte: Ihr markiert Punkte, den Weg dazwischen zeichnen wir später nach.',
  'report.prep.understood': 'Verstanden',
  'report.prep.start': 'Aufnahme starten',
  'report.prep.searching': 'Signal wird gesucht …',
  'report.prep.start_anyway': 'Trotzdem starten',
  'report.prep.revision_start': 'Startet am Anfang von „{name}“',
  'report.prep.far_warning':
      'Ihr seid {d} m vom Pfad entfernt. Seid ihr am richtigen Ort?',
  'report.prep.bg_fail':
      'Hintergrund-Aufnahme geht gerade nicht. Ihr nehmt nur Punkte auf.',
  'report.signal.good': 'GPS gut',
  'report.signal.mid': 'GPS mittel',
  'report.signal.weak': 'GPS schwach',
  'report.signal.none': 'Kein GPS',

  // Aufnahme und Marker
  'report.rec.stats': '{km} · {n} Stationen',
  'report.rec.end': 'Beenden',
  'report.rec.chip.station': 'Station',
  'report.rec.chip.waypoint': 'Wegpunkt',
  'report.rec.chip.parking': 'Parkplatz',
  'report.rec.chip.hint': 'Hinweis',
  'report.rec.set.station': 'Station setzen',
  'report.rec.set.waypoint': 'Wegpunkt setzen',
  'report.rec.set.parking': 'Parkplatz setzen',
  'report.rec.set.hint': 'Hinweis setzen',
  'report.rec.measuring': 'Wird gemessen …',
  'report.rec.pause': 'Pause',
  'report.rec.resume': 'Weiter',
  'report.rec.recenter': 'Zentrieren',
  'report.rec.snack.station': 'Station {n} gesetzt',
  'report.rec.snack.other': '{typ} gesetzt',
  'report.rec.snack.photo': 'Tafel fotografieren',
  'report.rec.snack.details': 'Details',
  'report.rec.snack.undo': 'Rückgängig',
  'report.rec.low_accuracy':
      'Signal schwach (±{a} m). Punkt gespeichert, ihr könnt ihn später prüfen.',
  'report.rec.no_fix': 'Kein GPS-Signal. Versucht es gleich noch einmal.',
  'report.rec.no_signal_banner':
      'Kein GPS-Signal. Punkte setzen geht gleich wieder.',
  'report.rec.marker_limit':
      'Mehr als 60 Punkte gehen nicht. Beendet die Aufnahme oder löscht Punkte.',
  'report.rec.track_full': 'Die Spur ist voll. Beendet die Aufnahme.',
  'report.rec.battery_low':
      'Akku ist niedrig. Beendet die Aufnahme bald und reicht den Pfad ein.',
  'report.rec.end.title': 'Aufnahme beenden?',
  'report.rec.end.review': 'Beenden und prüfen',
  'report.rec.end.continue': 'Weiter aufnehmen',
  'report.rec.end.discard': 'Verwerfen',
  'report.rec.discard.title': 'Aufnahme löschen?',
  'report.rec.discard.body': 'Das lässt sich nicht rückgängig machen.',
  'report.rec.paused_label': 'Pausiert',
  'report.common.delete': 'Löschen',
  'report.common.cancel': 'Abbrechen',
  'report.common.done': 'Fertig',
  'report.common.close': 'Schließen',
  'report.banner.running': 'Aufnahme läuft · {km} · {n} Stationen',
  'report.banner.paused': 'Aufnahme pausiert',
  'report.notif.title': 'Kalia nimmt euren Pfad auf',
  'report.marker.accuracy': 'Genauigkeit ±{a} m',
  'report.marker.inaccurate': 'Ungenau',
  'report.marker.number': 'Nummer',
  'report.marker.title': 'Titel der Tafel (optional)',
  'report.marker.note': 'Notiz (optional)',
  'report.marker.photo_add': 'Foto hinzufügen',
  'report.marker.photo_remove': 'Entfernen',
  'report.marker.remeasure': 'Neu messen',
  'report.marker.remeasure_far': 'Zu weit weg zum Neu-Messen',
  'report.marker.type.start': 'Start',
  'report.marker.type.end': 'Ende',
  'report.marker.type.station': 'Station',
  'report.marker.type.waypoint': 'Wegpunkt',
  'report.marker.type.parking': 'Parkplatz',
  'report.marker.type.hint': 'Hinweis',
  'report.hint.kind.closed': 'Gesperrt',
  'report.hint.kind.danger': 'Gefährlich',
  'report.hint.kind.stairs': 'Treppen oder Wurzeln',
  'report.hint.kind.viewpoint': 'Aussicht',
  'report.hint.kind.facility': 'Spielplatz, Rast oder WC',
  'report.hint.kind.other': 'Sonstiges',

  // Prüfen, Konto, Gesendet
  'report.review.title': 'Pfad prüfen',
  'report.review.summary': '{km} · {n} Stationen · {p} Fotos',
  'report.review.approx': 'ungefähr',
  'report.review.h1': 'Der Pfad ist sehr kurz. Ist die Aufnahme vollständig?',
  'report.review.h2':
      'Ihr habt keine Station gesetzt. Stationen helfen anderen Familien beim Zuhören.',
  'report.review.h3': '{n} Punkte sind ungenau.',
  'report.review.h4': 'Die Spur hat eine Lücke von {d} m.',
  'report.review.h5': 'Es gibt doppelte Stationsnummern.',
  'report.review.dup.title':
      'In der Nähe gibt es schon „{name}“. Ist das derselbe Pfad?',
  'report.review.dup.yes': 'Ja, als Korrektur melden',
  'report.review.dup.no': 'Nein, anderer Pfad',
  'report.review.dup.confirm':
      'Eure Daten bleiben erhalten und gehen als Korrektur zu „{name}“ raus. Name und Gebiet entfallen.',
  'report.review.name': 'Name des Pfads',
  'report.review.name.error':
      'Bitte gebt dem Pfad einen Namen (mindestens 3 Zeichen).',
  'report.review.area': 'Gebiet',
  'report.review.area.error': 'Bitte wählt ein Gebiet.',
  'report.review.loop': 'Rundweg',
  'report.review.stroller': 'Kinderwagen',
  'report.review.stroller.yes': 'Ja',
  'report.review.stroller.no': 'Nein',
  'report.review.stroller.unknown': 'Weiß nicht',
  'report.review.note': 'Notiz (optional)',
  'report.review.trim.title':
      'Beginnt oder endet die Aufnahme bei euch zu Hause?',
  'report.review.trim.body':
      'Dann kürzt hier Anfang oder Ende. Gekürzte Teile werden nicht übertragen.',
  'report.review.trim.start': 'Anfang kürzen',
  'report.review.trim.end': 'Ende kürzen',
  'report.review.too_short':
      'Eure Aufnahme ist zu kurz. Nehmt mindestens 100 m oder zwei Punkte auf.',
  'report.review.legal':
      'Mit dem Einreichen erlaubt ihr uns, eure Daten und Fotos in Kalia zu verwenden.',
  'report.review.legal.link': 'Beitragsbedingungen',
  'report.review.submit': 'Einreichen',
  'report.review.save_draft': 'Als Entwurf speichern',
  'report.review.draft_saved': 'Entwurf gespeichert',
  'report.review.continue_recording': 'Weiter aufnehmen',
  'report.review.markers': 'Punkte',
  'report.review.menu.discard': 'Verwerfen',
  'report.account.title': 'Konto anlegen, um euren Pfad einzureichen',
  'report.account.body':
      'Ohne Konto bleibt alles auf diesem Gerät. Mit Konto könnt ihr den Stand eurer Meldung sehen.',
  'report.account.later': 'Später',
  'report.account.saved': 'Euer Entwurf ist gespeichert.',
  'report.sent.title': 'Danke, euer Pfad ist unterwegs',
  'report.sent.title_quick': 'Danke, eure Meldung ist unterwegs',
  'report.sent.title_offline':
      'Gespeichert. Wird gesendet, sobald ihr Netz habt.',
  'report.sent.step1': 'Wir prüfen euren Beitrag.',
  'report.sent.step2': 'Den Stand seht ihr unter „Meine Meldungen“.',
  // [TODO: Zeitversprechen festlegen] bis dahin ohne Zahl.
  'report.sent.step3': 'Das dauert meist ein paar Tage.',
  'report.sent.mine': 'Meine Meldungen',
  'report.sent.done': 'Fertig',
  'report.sent.push.title': 'Sollen wir Bescheid geben?',
  'report.sent.push.yes': 'Ja, gern',
  'report.sent.push.no': 'Nein danke',

  // Berechtigungen und Wiederherstellung
  'report.perm.pre.title': 'Wir brauchen euren genauen Standort',
  'report.perm.pre.body':
      'Damit wir den Weg aufzeichnen und Punkte genau setzen können. Der Standort wird nur benutzt, solange ihr aufnehmt oder meldet.',
  'report.perm.pre.cta': 'Standort erlauben',
  'report.perm.denied.title': 'Ohne Standort geht das nicht',
  'report.perm.denied.body':
      'Ohne euren Standort können wir keinen Pfad aufnehmen. Ihr könnt ihn jederzeit erlauben.',
  'report.perm.denied.cta': 'Erneut fragen',
  'report.perm.settings.title': 'Standort ist für Kalia ausgeschaltet',
  'report.perm.settings.body':
      'Erlaubt den Standort in den Einstellungen. Danach geht es hier weiter.',
  'report.perm.settings.cta': 'Einstellungen öffnen',
  'report.perm.off.title': 'Der Standortdienst ist aus',
  'report.perm.off.body': 'Schaltet den Standort in den Einstellungen ein.',
  'report.perm.off.cta': 'Standort-Einstellungen öffnen',
  'report.perm.precise.title': 'Genauer Standort nötig',
  'report.perm.precise.body':
      'Mit ungefährem Standort liegen Punkte oft 100 m daneben. Bitte erlaubt „Genau“.',
  'report.perm.precise.cta': 'Genau erlauben',
  'report.perm.notif.title': 'Hinweis während der Aufnahme',
  'report.perm.notif.body':
      'Kalia zeigt eine Benachrichtigung, solange die Aufnahme läuft.',
  'report.perm.notif.cta': 'Erlauben',
  'report.perm.battery':
      'Tipp: Nehmt Kalia aus der Akku-Optimierung, damit die Aufnahme nicht stoppt.',
  'report.perm.battery.cta': 'Verstanden',
  'report.perm.camera.title': 'Kamera-Zugriff fehlt',
  'report.perm.camera.cta': 'Einstellungen öffnen',
  'report.perm.camera.alt': 'Ohne Foto weiter',
  'report.perm.later': 'Später',
  'report.recover.title': 'Eine Aufnahme wurde unterbrochen',
  'report.recover.body': 'Eure Punkte und die bisherige Spur sind gespeichert.',
  'report.recover.continue': 'Weiter aufnehmen',
  'report.recover.review': 'Prüfen und einreichen',
  'report.recover.discard': 'Verwerfen',

  // Korrigieren (Flow B)
  'report.pick.title': 'Welcher Pfad?',
  'report.pick.search': 'Pfad suchen',
  'report.pick.distance': '{d} km entfernt',
  'report.pick.empty_search': 'Keinen Pfad mit diesem Namen gefunden.',
  'report.pick.empty_near': 'Kein Pfad in der Nähe. Sucht nach dem Namen.',
  'report.pick.no_location': 'Ohne Standort könnt ihr nach dem Namen suchen.',
  'report.fix.title': 'Was stimmt bei „{name}“ nicht?',
  'report.fix.move': 'Eine Station liegt woanders',
  'report.fix.add': 'Es fehlt eine Station oder Tafel',
  'report.fix.hint': 'Der Pfad ist gesperrt oder gefährlich',
  'report.fix.route': 'Der Pfad verläuft anders',
  'report.fix.parking': 'Der Parkplatz stimmt nicht',
  'report.fix.place': 'Der Ort liegt woanders',
  'report.fix.other': 'Etwas anderes',
  'report.fix.link': 'Hier stimmt etwas nicht',
  'report.fix.route_info.title': 'Der Pfad verläuft anders',
  'report.fix.route_info.body':
      'Dafür geht ihr den Pfad einmal ganz ab. Wir legen eure Spur über den bestehenden Pfad und prüfen die Unterschiede.',
  'report.fix.route_info.go': 'Los geht’s',
  'report.move.title': 'Station verschieben',
  'report.move.pick': 'Wählt die Station, die ihr korrigieren möchtet.',
  'report.move.distance':
      'Die gespeicherte Station ist {d} m von euch entfernt.',
  'report.move.too_far':
      'Ihr seid zu weit weg. Geht zur Station und versucht es dort noch einmal.',
  'report.move.cta': 'Station hier neu setzen',
  'report.move.noise':
      'Nur {d} m Unterschied. Das liegt im Bereich der GPS-Genauigkeit.',
  'report.move.send_anyway': 'Trotzdem senden',
  'report.move.weak': 'Signal zu schwach (±{a} m)',
  'report.move.remeasure': 'Nochmal messen',
  'report.move.send': 'Senden',
  'report.move.photo': 'Foto (optional)',
  'report.move.note': 'Notiz (optional)',
  'report.add.title': 'Station ergänzen',
  'report.add.cta': 'Station hier setzen',
  'report.add.parking.title': 'Parkplatz melden',
  'report.add.parking.cta': 'Parkplatz hier setzen',
  'report.add.too_far': 'Ihr seid zu weit weg. Meldet am Pfad.',
  'report.add.offtrail':
      'Das liegt abseits des Pfads. Gehört die Station zu diesem Pfad?',
  'report.add.offtrail.yes': 'Ja, senden',
  'report.hintform.title': 'Hinweis melden',
  'report.hintform.other.title': 'Etwas anderes melden',
  'report.hintform.location': 'Standort: ±{a} m',
  'report.hintform.note_required':
      'Bitte beschreibt kurz, was los ist (mindestens 10 Zeichen).',
  'report.hintform.too_far':
      'Meldet das vor Ort, damit wir euch glauben können.',
  'report.hintform.kind': 'Art',

  // Meine Meldungen, Status, Fehler, Push
  'report.list.title': 'Meine Meldungen',
  'report.list.drafts': 'Entwürfe',
  'report.list.open': 'In Bearbeitung',
  'report.list.done': 'Abgeschlossen',
  'report.list.draft_old': 'Entwurf vom {date}',
  'report.list.login_card':
      'Meldet euch an, um eingereichte Meldungen zu sehen.',
  'report.list.delete.title': 'Entwurf löschen?',
  'report.list.delete.body': 'Das lässt sich nicht rückgängig machen.',
  'report.list.empty':
      'Noch keine Meldungen. Habt ihr einen Pfad entdeckt, der fehlt?',
  'report.list.empty.cta': 'Pfad melden',
  'report.list.stale': 'Stand von {time}',
  'report.list.refresh_error':
      'Aktualisieren hat nicht geklappt. Gezeigt wird der letzte Stand.',
  'report.list.retry': 'Erneut versuchen',
  'report.list.push_off': 'Benachrichtigungen sind aus.',
  'report.title.revision': 'Neuaufnahme: {name}',
  'report.title.move': 'Station verschoben',
  'report.title.add': 'Station ergänzt',
  'report.title.parking': 'Parkplatz gemeldet',
  'report.title.hint': 'Hinweis',
  'report.title.other': 'Sonstiges',
  'report.status.draft': 'Entwurf',
  'report.status.awaiting_account': 'Wartet auf Konto',
  'report.status.queued': 'Wartet auf Netz',
  'report.status.uploading': 'Wird gesendet …',
  'report.status.submitted': 'Eingereicht',
  'report.status.in_review': 'In Prüfung',
  'report.status.needs_info': 'Rückfrage',
  'report.status.approved': 'Übernommen',
  'report.status.partially_approved': 'Teilweise übernommen',
  'report.status.rejected': 'Nicht übernommen',
  'report.status.withdrawn': 'Zurückgezogen',
  'report.status.failed': 'Senden fehlgeschlagen',
  'report.status.recording': 'Aufnahme läuft',
  'report.status.paused': 'Aufnahme pausiert',
  'report.status.text.submitted': 'Eure Meldung ist bei uns eingegangen.',
  'report.status.text.in_review': 'Wir schauen uns eure Meldung an.',
  'report.status.text.needs_info': 'Wir haben eine Frage zu eurer Meldung.',
  'report.status.text.approved_new':
      'Danke! Wir haben euren Pfad übernommen und ergänzen jetzt Beschreibung und Audio.',
  'report.status.text.approved': 'Danke! Eure Korrektur ist übernommen.',
  'report.status.text.partial':
      'Danke! Wir haben einen Teil übernommen. {note}',
  'report.status.text.withdrawn': 'Ihr habt diese Meldung zurückgezogen.',
  'report.reject.duplicate': 'Diesen Pfad gibt es bei uns schon.',
  'report.reject.within_gps_noise':
      'Der Unterschied liegt im Bereich der GPS-Genauigkeit. Wir lassen den Punkt unverändert. Danke fürs Nachschauen!',
  'report.reject.not_family_suitable':
      'Dieser Pfad passt nicht zu unseren Familien-Kriterien: kurze, machbare Strecken für kleine Kinder.',
  'report.reject.not_public': 'Der Weg ist nicht öffentlich zugänglich.',
  'report.reject.insufficient_data': 'Die Angaben reichen uns noch nicht aus.',
  'report.reject.wrong_location':
      'Die Position passt nicht zum gemeldeten Ort.',
  'report.reject.other':
      'Wir konnten die Meldung leider nicht übernehmen. {note}',
  'report.detail.title': 'Meldung',
  'report.detail.history': 'Verlauf',
  'report.detail.event.submitted': 'Eingereicht',
  'report.detail.event.in_review': 'In Prüfung',
  'report.detail.event.needs_info': 'Rückfrage',
  'report.detail.event.user_reply': 'Eure Antwort',
  'report.detail.event.decided': 'Entschieden',
  'report.detail.event.withdrawn': 'Zurückgezogen',
  'report.detail.reply.label': 'Eure Antwort',
  'report.detail.reply.send': 'Antworten',
  'report.detail.reply.sent': 'Antwort gesendet',
  'report.detail.withdraw': 'Zurückziehen',
  'report.detail.withdraw.title': 'Meldung zurückziehen?',
  'report.detail.withdraw.yes': 'Ja, zurückziehen',
  'report.detail.withdraw.offline': 'Zurückziehen geht nur mit Internet',
  'report.detail.retry': 'Erneut versuchen',
  'report.detail.edit': 'Bearbeiten',
  'report.detail.photos_missing': '{n} Fotos fehlen',
  'report.detail.photos_resend': 'Fotos erneut senden',
  'report.detail.photos_uploaded': '{n} von {m} Fotos hochgeladen',
  'report.detail.open_trail': 'Pfad ansehen',
  'report.detail.again': 'Nochmal melden',
  'report.detail.relogin': 'Bitte meldet euch erneut an.',
  'report.detail.relogin.cta': 'Anmelden',
  'report.detail.gone': 'Diese Meldung gibt es nicht mehr.',
  'report.detail.back': 'Zurück',
  'report.err.limit_open':
      'Ihr habt gerade viele offene Meldungen. Wartet, bis einige geprüft sind.',
  'report.err.limit_daily':
      'Heute sind schon viele Meldungen von euch eingegangen. Versucht es morgen wieder.',
  'report.err.invalid_payload':
      'Mit euren Angaben stimmt etwas nicht. Bitte prüft sie noch einmal.',
  'report.err.too_large':
      'Euer Beitrag ist zu groß. Kürzt den Track oder entfernt Fotos.',
  'report.err.db_write': 'Speichern hat nicht geklappt.',
  'report.err.db_write.retry': 'Erneut versuchen',
  'report.err.photo_save':
      'Das Foto konnte nicht gespeichert werden. Der Speicher ist voll.',
  'report.err.web': 'Aufnehmen geht nur in der App auf dem Handy.',
  'report.push.approved.title': 'Eure Meldung ist übernommen',
  'report.push.approved.body':
      'Danke! Schaut euch an, was daraus geworden ist.',
  'report.push.rejected.title': 'Eure Meldung wurde geprüft',
  'report.push.rejected.body': 'Wir haben eine Rückmeldung für euch.',
  'report.push.needs_info.title': 'Wir haben eine Frage',
  'report.push.needs_info.body': 'Zu eurer Meldung gibt es eine Rückfrage.',
};

/// Text zum Key. Platzhalter `{name}` werden ersetzt.
String rt(String key, [Map<String, Object> args = const {}]) {
  final text = reportTexte[key];
  assert(text != null, 'Fehlender Copy-Key: $key');
  var out = text ?? key;
  args.forEach((name, value) {
    out = out.replaceAll('{$name}', '$value');
  });
  return out;
}

/// Zahlen nach den Formatierungsregeln der App: Dezimalkomma, „km“ und „m“
/// mit Leerzeichen.
String formatKm(double meters) {
  final km = meters / 1000;
  final s = km < 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(0);
  return '${s.replaceAll('.', ',')} km';
}

String formatMeters(double meters) => '${meters.round()} m';
