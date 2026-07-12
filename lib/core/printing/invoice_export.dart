import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Offline invoice export — used when there is no printer to send to (or when
/// the shop simply wants a soft copy). We rasterise the already-rendered
/// receipt widget rather than re-typesetting it, so whatever the app can draw
/// (Bengali item names, ৳ symbols, the shop logo) survives into the PNG/PDF
/// with no font embedding needed.

/// Captures the widget behind [boundaryKey] as PNG bytes. Rendered at 3x for a
/// crisp result that stays legible when zoomed or printed later.
Future<Uint8List> captureInvoicePng(GlobalKey boundaryKey) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 3.0);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Preferred output location: the OS Downloads folder, falling back to the
/// app documents dir on platforms that don't expose one.
Future<Directory> _outputDir() async =>
    await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();

String _fileStem(String invoiceNo) {
  if (invoiceNo.trim().isNotEmpty) {
    return 'Invoice-${invoiceNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-')}';
  }
  final stamp = DateTime.now()
      .toIso8601String()
      .replaceAll(RegExp(r'[:.]'), '-')
      .substring(0, 19);
  return 'Invoice-$stamp';
}

/// Writes [png] to storage as an image file and returns the saved path.
Future<String> saveInvoicePng(Uint8List png, {String invoiceNo = ''}) async {
  final dir = await _outputDir();
  final file = File('${dir.path}/${_fileStem(invoiceNo)}.png');
  await file.writeAsBytes(png);
  return file.path;
}

/// Wraps [png] in a single-page PDF sized for an 80mm receipt roll and returns
/// the saved path. Image-based, so no glyph/font limits.
Future<String> saveInvoicePdf(Uint8List png, {String invoiceNo = ''}) async {
  final doc = pw.Document();
  final image = pw.MemoryImage(png);
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.all(8),
      build: (_) => pw.Center(child: pw.Image(image)),
    ),
  );
  final dir = await _outputDir();
  final file = File('${dir.path}/${_fileStem(invoiceNo)}.pdf');
  await file.writeAsBytes(await doc.save());
  return file.path;
}
