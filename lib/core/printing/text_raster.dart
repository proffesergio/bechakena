import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

Future<void>? _fontReady;

Future<void> _loadFont() async {
  final loader = FontLoader('ReceiptBengali')
    ..addFont(rootBundle.load('assets/fonts/NotoSansBengali.ttf'));
  await loader.load();
}

/// Encodes native ASCII lines cheaply and shapes other lines with the bundled
/// Bengali font. Unicode wraps at the printable dot width, retaining conjuncts
/// and vowel marks instead of truncating UTF-16 code units.
Future<List<int>> receiptTextBody(String text, {required int widthDots}) async {
  if (widthDots < 8) {
    throw ArgumentError.value(widthDots, 'widthDots', 'Must be at least 8');
  }
  final out = <int>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.codeUnits.every((unit) => unit <= 0x7f)) {
      out.addAll(
        line.codeUnits.map(
          (unit) => unit >= 0x20 && unit <= 0x7e ? unit : 0x3f,
        ),
      );
      if (i < lines.length - 1) out.add(0x0a);
    } else {
      await (_fontReady ??= _loadFont());
      out.addAll(await _rasterLine(line, widthDots));
      // GS v 0 advances by its bitmap height; an extra LF adds a blank line.
    }
  }
  return out;
}

Future<List<int>> _rasterLine(String text, int widthDots) async {
  // GS v 0 widths are whole bytes. Keep padding inside the printable area.
  final width = widthDots ~/ 8 * 8;
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textDirection: ui.TextDirection.ltr,
            fontFamily: 'ReceiptBengali',
            fontSize: 24,
          ),
        )
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xff000000)))
        ..addText(text);
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: width.toDouble()));
  final height = paragraph.height.ceil() + 4;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xffffffff), ui.BlendMode.src);
  canvas.drawParagraph(paragraph, const ui.Offset(0, 2));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (rgba == null) throw StateError('Unable to rasterize receipt text');
    final out = <int>[];
    final rowBytes = width ~/ 8;
    // Small commands work with inexpensive printer receive buffers. Each
    // command advances directly to the next slice without an intervening LF.
    for (var top = 0; top < height; top += 64) {
      final rows = math.min(64, height - top);
      out.addAll([
        0x1d,
        0x76,
        0x30,
        0x00,
        rowBytes & 0xff,
        rowBytes >> 8,
        rows,
        0,
      ]);
      for (var y = top; y < top + rows; y++) {
        for (var x = 0; x < width; x += 8) {
          var packed = 0;
          for (var bit = 0; bit < 8; bit++) {
            if (rgba.getUint8((y * width + x + bit) * 4) < 160) {
              packed |= 0x80 >> bit;
            }
          }
          out.add(packed);
        }
      }
    }
    return out;
  } finally {
    image.dispose();
    picture.dispose();
    paragraph.dispose();
  }
}
