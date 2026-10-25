import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider<Object> kaliaFileImage(String path, int? cacheWidth) {
  return ResizeImage(FileImage(File(path)), width: cacheWidth);
}
