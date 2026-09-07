import 'dart:convert';
import 'dart:io';

import 'package:lehrpfad_app/features/community/domain/trail_image.dart';
import 'package:lehrpfad_app/shared/images/image_variants.dart';

/// AVIF-Qualität pro Variante (sips formatOptions). Naturfotos (Bäume,
/// Heide) brauchen den Spielraum nach unten, sonst sprengt small 60 KB.
const _avifQuality = {
  TrailImageVariant.thumb: 35,
  TrailImageVariant.small: 30,
  TrailImageVariant.medium: 40,
};

/// Seed-Hero-Ingest: JPEG/PNG-Quellen in `assets/images/trails/<id>/` über
/// dieselbe Resize-Logik wie der User-Upload in drei AVIF-Varianten bringen.
///
/// Reines Dart (kein Flutter-Plugin nötig): Resize/EXIF kommt aus
/// [resizeVariants], die AVIF-Enkodierung übernimmt `sips` (macOS, schreibt
/// AVIF nativ). Läuft daher als `dart run` ohne Xcode.
///
/// Nutzung (cwd = lehrpfad_app/):
///   dart run tool/ingest_images.dart trail-id
///   dart run tool/ingest_images.dart --all
///
/// Liest credits.json, encodiert jede genannte Quelldatei nach
/// `{slug}.thumb.avif` / `.small.avif` / `.medium.avif` und löscht das
/// Original. credits.json bleibt unverändert (`file` = Slug).
Future<void> main(List<String> args) async {
  final trailsDir = Directory('assets/images/trails');
  if (!trailsDir.existsSync()) {
    stderr.writeln('cwd muss lehrpfad_app/ sein (assets/images/trails fehlt)');
    exit(2);
  }
  if (Process.runSync('which', ['sips']).exitCode != 0) {
    stderr.writeln('sips fehlt (macOS). Abbruch.');
    exit(2);
  }

  final targets = <Directory>[];
  if (args.contains('--all')) {
    targets.addAll(
      trailsDir.listSync().whereType<Directory>().toList()
        ..sort((a, b) => a.path.compareTo(b.path)),
    );
  } else {
    final ids = args.where((a) => !a.startsWith('--')).toList();
    if (ids.isEmpty) {
      stderr.writeln('Nutzung: dart run tool/ingest_images.dart <trail_id> | --all');
      exit(2);
    }
    for (final id in ids) {
      targets.add(Directory('${trailsDir.path}/$id'));
    }
  }

  var encoded = 0;
  for (final dir in targets) {
    final creditsFile = File('${dir.path}/credits.json');
    if (!creditsFile.existsSync()) {
      stderr.writeln('SKIP ${dir.path} (kein credits.json)');
      continue;
    }
    final rows = jsonDecode(await creditsFile.readAsString());
    if (rows is! List) {
      stderr.writeln('SKIP ${dir.path} (credits.json kein Array)');
      continue;
    }

    for (final row in rows) {
      final file = row is Map ? row['file'] : null;
      if (file is! String || file.isEmpty || file.startsWith('assets/')) {
        continue;
      }
      final src = File('${dir.path}/$file');
      if (!src.existsSync()) {
        continue; // Schon ingestet (nur noch .avif) oder Slug ohne Endung.
      }
      final slug = file.replaceAll(RegExp(r'\.(jpe?g|png|webp)$'), '');
      if (await _ingestFile(src, dir, slug)) encoded++;
    }
  }

  // Zentraler Hero-Platzhalter liegt direkt unter trails/, nicht in einem
  // Trail-Ordner. --all nimmt ihn mit, einzelnes Trail-Ingest lässt ihn.
  final placeholder = File('${trailsDir.path}/_placeholder.jpg');
  if (args.contains('--all') && placeholder.existsSync()) {
    if (await _ingestFile(placeholder, trailsDir, '_placeholder')) encoded++;
  }

  stdout.writeln('fertig: $encoded Bilder encodiert');
}

/// Resized [src] in drei AVIFs unter [outDir]/[slug].{variant}.avif und
/// löscht die Quelle. false bei Decode- oder sips-Fehler.
Future<bool> _ingestFile(File src, Directory outDir, String slug) async {
  final ResizedVariants resized;
  try {
    resized = resizeVariants(await src.readAsBytes());
  } on ImageVariantsException catch (e) {
    stderr.writeln('FEHLER ${src.path}: $e');
    return false;
  }

  final stamp = DateTime.now().microsecondsSinceEpoch;
  for (final entry in resized.pngBytes.entries) {
    // Eigene Temp-Datei pro Variante: gleiche Quelle würde sonst
    // von sips gecacht und small/medium kämen identisch raus.
    final tmp = File(
      '${Directory.systemTemp.path}/ingest_${stamp}_${slug}_${entry.key.fileName}.png',
    );
    final out = File('${outDir.path}/$slug.${entry.key.fileName}.avif');
    await tmp.writeAsBytes(entry.value, flush: true);
    final res = await Process.run(
      'sips',
      [
        '-s', 'format', 'avif',
        '-s', 'formatOptions', '${_avifQuality[entry.key]}',
        tmp.path, '--out', out.path,
      ],
    );
    await tmp.delete().catchError((_) => tmp);
    if (res.exitCode != 0 || !out.existsSync()) {
      stderr.writeln('FEHLER sips ${entry.key.fileName} für $slug: ${res.stderr}');
      return false;
    }
  }

  await src.delete();
  stdout.writeln(
    'OK  ${outDir.path.split(Platform.pathSeparator).last}/$slug '
    '(${resized.width}x${resized.height})',
  );
  return true;
}
