import 'package:flutter/widgets.dart';

/// Web hat keinen Dateipfad. Der Store liefert dort nie eine lokale Datei.
ImageProvider<Object> kaliaFileImage(String _, int? cacheWidth) {
  return ResizeImage(
    const AssetImage('assets/images/trails/_placeholder.thumb.webp'),
    width: cacheWidth,
  );
}
