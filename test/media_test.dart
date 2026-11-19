import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_eyes/services/media.dart';

void main() {
  test('validates formats and decodes PNG and JPEG', () {
    final source = img.Image(width: 3, height: 2);
    for (final bytes in [img.encodePng(source), img.encodeJpg(source)]) {
      final decoded = img.decodePng(preparePreview((bytes, false)))!;
      expect(decoded.width, 3);
      expect(decoded.height, 2);
    }
    expect(
      () => preparePreview((Uint8List(10), false)),
      throwsFormatException,
    );
  });

  test('bakes JPEG EXIF orientation prior to display', () {
    final original = img.Image(width: 30, height: 20);
    original.exif.imageIfd.orientation = 6;
    final decoded = img.decodePng(
      preparePreview((img.encodeJpg(original), false)),
    )!;
    expect(decoded.width, 20);
    expect(decoded.height, 30);
  });

  test('bounds large preview and leaves the input bytes untouched', () {
    final source = img.Image(width: 2400, height: 1200);
    final bytes = img.encodePng(source);
    final original = Uint8List.fromList(bytes);
    final result = img.decodePng(preparePreview((bytes, false)))!;
    expect(result.width, 2048);
    expect(result.height, 1024);
    expect(bytes, orderedEquals(original));
  });

  test('mirrors the frame when capturing with the front camera', () {
    final source = img.Image(width: 4, height: 2);
    source.setPixelRgb(0, 0, 255, 0, 0);
    final decoded = img.decodePng(
      preparePreview((img.encodePng(source), true)),
    )!;
    expect(decoded.getPixel(3, 0).r, 255);
  });
}
