import 'dart:typed_data';

import 'package:bechakena/core/printing/escpos.dart';
import 'package:bechakena/core/printing/logo_raster.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// Fills an image with a solid RGB colour.
img.Image _solid(int w, int h, int r, int g, int b) {
  final image = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return image;
}

void main() {
  group('escPosRaster', () {
    test('emits a GS v 0 header with correct dimensions', () {
      final bytes = escPosRaster(_solid(8, 1, 255, 255, 255));
      // GS v 0, mode, xL, xH, yL, yH
      expect(bytes.sublist(0, 8), [0x1D, 0x76, 0x30, 0x00, 1, 0, 1, 0]);
      expect(bytes.length, 8 + 1); // 1 byte per row * 1 row
    });

    test('white pixels produce empty (0x00) data', () {
      final bytes = escPosRaster(_solid(8, 1, 255, 255, 255));
      expect(bytes.last, 0x00);
    });

    test('black pixels set every bit (0xFF)', () {
      final bytes = escPosRaster(_solid(8, 1, 0, 0, 0));
      expect(bytes.last, 0xFF);
    });

    test('rows pad to whole bytes', () {
      // 9 dots wide -> 2 bytes per row.
      final bytes = escPosRaster(_solid(9, 2, 0, 0, 0));
      expect(bytes.sublist(3, 8), [0x00, 2, 0, 2, 0]); // mode,xL,xH,yL,yH
      expect(bytes.length, 8 + 2 * 2);
      // Column 9 is the high bit of the second byte only.
      expect(bytes[8], 0xFF); // first 8 columns
      expect(bytes[9], 0x80); // 9th column, MSB
    });

    test('undecodable bytes yield null, never throw', () {
      expect(
        tryEscPosRasterFromImage(
            Uint8List.fromList([1, 2, 3, 4]), // not an image
            maxWidthDots: 384),
        isNull,
      );
    });
  });

  group('escPosBytes with a raster header', () {
    test('wraps the raster in centre/left alignment after init', () {
      final raster = escPosRaster(_solid(8, 1, 0, 0, 0));
      final out = escPosBytes('HI', rasterHeader: raster);
      // ESC @ then ESC a 1 (centre) then the raster.
      expect(out.sublist(0, 5), [0x1B, 0x40, 0x1B, 0x61, 0x01]);
      // The raster command appears intact.
      expect(_contains(out, raster), isTrue);
      // Left-align restored somewhere after.
      expect(_contains(out, [0x1B, 0x61, 0x00]), isTrue);
    });

    test('no header keeps the original init-first layout', () {
      final out = escPosBytes('HI');
      expect(out.sublist(0, 2), [0x1B, 0x40]);
      expect(_contains(out, [0x1B, 0x61, 0x01]), isFalse);
    });
  });
}

bool _contains(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
