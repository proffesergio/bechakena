import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'logo_raster.dart';

/// Wraps packed monochrome pixels in an ESC/POS GS v 0 command.
List<int> escPosRasterBytes(RasterBitmap raster) => <int>[
  0x1D,
  0x76,
  0x30,
  0x00,
  raster.bytesPerRow & 0xFF,
  (raster.bytesPerRow >> 8) & 0xFF,
  raster.height & 0xFF,
  (raster.height >> 8) & 0xFF,
  ...raster.bytes,
];

/// Compatibility helper for callers that already have a decoded image.
List<int> escPosRaster(img.Image image, {int threshold = 128}) =>
    escPosRasterBytes(rasterizeImage(image, threshold: threshold));

/// Compatibility helper for decoding and encoding an optional logo.
List<int>? tryEscPosRasterFromImage(
  Uint8List encoded, {
  required int maxWidthDots,
}) {
  final raster = tryRasterFromImage(encoded, maxWidthDots: maxWidthDots);
  return raster == null ? null : escPosRasterBytes(raster);
}

/// Minimal ESC/POS encoding: init, optional cash-drawer kick, optional raster
/// logo header, text/raster body, feed and partial cut. Works on any 58/80 mm
/// thermal printer.
///
/// [rasterHeader], when supplied, is a pre-encoded GS v 0 raster bitmap (see
/// [escPosRasterBytes]); it is centred above the text so the shop logo prints
/// on every receipt.
List<int> escPosBytes(
  String text, {
  bool kickDrawer = false,
  List<int>? rasterHeader,
  List<int>? encodedBody,
}) {
  final bytes = <int>[
    0x1B, 0x40, // ESC @ — initialize
    if (kickDrawer) ...[0x1B, 0x70, 0x00, 0x19, 0xFA], // ESC p — drawer pulse
    if (rasterHeader != null && rasterHeader.isNotEmpty) ...[
      0x1B, 0x61, 0x01, // ESC a 1 — centre
      ...rasterHeader,
      0x1B, 0x61, 0x00, // ESC a 0 — left
      0x0A,
    ],
  ];
  for (final unit in encodedBody == null ? text.codeUnits : <int>[]) {
    if (unit == 0x0A || (unit >= 0x20 && unit <= 0x7E)) {
      bytes.add(unit);
    } else {
      bytes.add(0x3F); // '?' — never send multi-byte glyphs the printer lacks
    }
  }
  if (encodedBody != null) bytes.addAll(encodedBody);
  bytes.addAll([0x0A, 0x0A, 0x0A, 0x0A]); // feed clear of the tear bar
  bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V 66 0 — partial cut
  return bytes;
}
