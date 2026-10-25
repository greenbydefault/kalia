import 'dart:convert';
import 'dart:typed_data';

/// Eine `.docx` als ZIP mit genau diesem Eintrag (Methode store, UTF-8).
/// Der Worker entpackt nur ZIPs; die Dropzone ruft das vor dem Upload auf.
Uint8List docxAlsZip(String name, Uint8List bytes) {
  final entry = utf8.encode(_dateiname(name));
  final crc = _crc32(bytes);
  final size = bytes.length;
  final local = BytesBuilder(copy: false);
  local.add(_u32(0x04034b50));
  local.add(_u16(20));
  local.add(_u16(0x0800));
  local.add(_u16(0));
  local.add(_u16(0));
  local.add(_u16(0));
  local.add(_u32(crc));
  local.add(_u32(size));
  local.add(_u32(size));
  local.add(_u16(entry.length));
  local.add(_u16(0));
  local.add(entry);
  local.add(bytes);
  final localBytes = local.toBytes();

  final central = BytesBuilder(copy: false);
  central.add(_u32(0x02014b50));
  central.add(_u16(20));
  central.add(_u16(20));
  central.add(_u16(0x0800));
  central.add(_u16(0));
  central.add(_u16(0));
  central.add(_u16(0));
  central.add(_u32(crc));
  central.add(_u32(size));
  central.add(_u32(size));
  central.add(_u16(entry.length));
  central.add(_u16(0));
  central.add(_u16(0));
  central.add(_u16(0));
  central.add(_u16(0));
  central.add(_u32(0));
  central.add(_u32(0));
  central.add(entry);
  final centralBytes = central.toBytes();

  final out = BytesBuilder(copy: false);
  out.add(localBytes);
  out.add(centralBytes);
  out.add(_u32(0x06054b50));
  out.add(_u16(0));
  out.add(_u16(0));
  out.add(_u16(1));
  out.add(_u16(1));
  out.add(_u32(centralBytes.length));
  out.add(_u32(localBytes.length));
  out.add(_u16(0));
  return out.toBytes();
}

/// ZIP-Bytes vor dem Hash, wenn die Datei eine einzelne `.docx` ist.
Uint8List dossierBytes(String name, Uint8List bytes) {
  if (name.toLowerCase().endsWith('.docx')) return docxAlsZip(name, bytes);
  return bytes;
}

String _dateiname(String name) {
  final n = name.replaceAll('\\', '/');
  final slash = n.lastIndexOf('/');
  final base = slash >= 0 ? n.substring(slash + 1) : n;
  return base.isEmpty ? 'dossier.docx' : base;
}

int _crc32(Uint8List data) {
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      final bit = crc & 1;
      crc = (crc >> 1) & 0x7FFFFFFF;
      if (bit != 0) crc ^= 0xEDB88320;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

Uint8List _u16(int v) {
  final b = ByteData(2)..setUint16(0, v, Endian.little);
  return b.buffer.asUint8List();
}

Uint8List _u32(int v) {
  final b = ByteData(4)..setUint32(0, v, Endian.little);
  return b.buffer.asUint8List();
}
