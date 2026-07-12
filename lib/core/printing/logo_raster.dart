import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Decodes PNG/JPG bytes and encodes them as an ESC/POS `GS v 0` raster bitmap,
/// downscaled to at most [maxWidthDots] (384 for 58 mm, 576 for 80 mm) and
/// thresholded to 1-bit black/white — the only image format cheap thermal
/// printers understand. Returns `null` when the bytes aren't a decodable image
/// so a bad logo never blocks a receipt.
List<int>? tryEscPosRasterFromImage(Uint8List encoded,
    {required int maxWidthDots}) {
  img.Image? decoded;
  try {
    // Malformed bytes can make a format probe read past the buffer, so guard
    // decoding as well as the null return.
    decoded = img.decodeImage(encoded);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  var image = decoded;
  if (image.width > maxWidthDots) {
    image = img.copyResize(image, width: maxWidthDots);
  }
  return escPosRaster(image);
}

/// Packs an [image] into a `GS v 0` raster command, MSB-first, 1 = black dot.
/// Pixels darker than [threshold] (0–255 luminance) print; transparent pixels
/// are treated as paper (white).
List<int> escPosRaster(img.Image image, {int threshold = 128}) {
  final width = image.width;
  final height = image.height;
  final bytesPerRow = (width + 7) >> 3;
  final data = Uint8List(bytesPerRow * height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final px = image.getPixel(x, y);
      final lum = 0.299 * px.r + 0.587 * px.g + 0.114 * px.b;
      final isBlack = px.a > 0 && lum < threshold;
      if (isBlack) {
        data[y * bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
      }
    }
  }

  return <int>[
    0x1D, 0x76, 0x30, 0x00, // GS v 0, mode 0 (normal)
    bytesPerRow & 0xFF, (bytesPerRow >> 8) & 0xFF, // xL, xH
    height & 0xFF, (height >> 8) & 0xFF, // yL, yH
    ...data,
  ];
}
