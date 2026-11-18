import 'dart:io';

import 'package:image_picker/image_picker.dart';

Future<void> deleteTempCapture(XFile file) async {
  try {
    await File(file.path).delete();
  } on FileSystemException {
    // Capture lives in the platform cache, where it can be reclaimed by the OS.
  }
}
