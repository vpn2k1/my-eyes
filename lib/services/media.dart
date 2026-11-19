import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

const maxFileBytes = 24 * 1024 * 1024;
const maxPixels = 32 * 1000 * 1000;
const previewEdge = 2048;

Future<ui.Image> loadScene(String asset) async {
  final data = await rootBundle.load(asset);
  return _decodePreview(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );
}

Future<ui.Image> loadPhoto(XFile file, {bool mirror = false}) async {
  if (await file.length() > maxFileBytes) {
    throw const FormatException('File exceeds the size limit');
  }
  final bytes = await compute(preparePreview, (
    await file.readAsBytes(),
    mirror,
  ));
  return _decodePreview(bytes);
}

Future<ui.Image> _decodePreview(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}

/// Validates and bounds input before allocating a full decoded frame.
Uint8List preparePreview((Uint8List bytes, bool mirror) args) {
  final (bytes, mirror) = args;
  if (bytes.length > maxFileBytes) {
    throw const FormatException('File exceeds the size limit');
  }
  final jpeg = img.JpegDecoder();
  final png = img.PngDecoder();
  final img.Decoder decoder;
  if (jpeg.isValidFile(bytes)) {
    decoder = jpeg;
  } else if (png.isValidFile(bytes)) {
    decoder = png;
  } else {
    throw const FormatException('Expected JPEG or PNG');
  }
  final info = decoder.startDecode(bytes);
  if (info == null ||
      info.width <= 0 ||
      info.height <= 0 ||
      info.width * info.height > maxPixels) {
    throw const FormatException('Invalid or oversized image');
  }
  final raw = decoder.decodeFrame(0);
  if (raw == null) throw const FormatException('Cannot decode image');
  var frame = img.bakeOrientation(raw);
  if (mirror) frame = img.flipHorizontal(frame);
  if (frame.width > previewEdge || frame.height > previewEdge) {
    frame = img.copyResize(
      frame,
      width: frame.width >= frame.height ? previewEdge : null,
      height: frame.height > frame.width ? previewEdge : null,
      interpolation: img.Interpolation.average,
    );
  }
  return img.encodePng(frame, singleFrame: true);
}
