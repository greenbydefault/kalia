import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lehrpfad_app/admin/import/docx_zip.dart';

void main() {
  test('docx wird zu einem ZIP, das Python lesen kann', () async {
    const name = 'naturerlebnispfad-freizeitpark-marienfelde – Dossier v2.docx';
    final payload = utf8.encode('PK-falsch-aber-inhalt');
    final zip = docxAlsZip(name, payload);

    expect(zip[0], 0x50);
    expect(zip[1], 0x4b);
    expect(_indexOf(zip, utf8.encode(name)), isNonNegative);

    final dir = await Directory.systemTemp.createTemp('docx-zip');
    final file = File('${dir.path}/a.zip');
    await file.writeAsBytes(zip);
    final r = await Process.run('python3', [
      '-c',
      'import sys, zipfile; z = zipfile.ZipFile(sys.argv[1]); n = z.namelist(); '
          'assert len(n) == 1, n; sys.stdout.write(n[0] + "\\n" + z.read(n[0]).decode())',
      file.path,
    ]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
    expect(r.stdout, '$name\nPK-falsch-aber-inhalt');
    await dir.delete(recursive: true);
  });

  test('zip bleibt unverändert', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(dossierBytes('paket.zip', bytes), bytes);
  });
}

int _indexOf(List<int> hay, List<int> needle) {
  for (var i = 0; i <= hay.length - needle.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (hay[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}
