/// Minimal ESC/POS encoding: init, optional cash-drawer kick, ASCII body,
/// feed and partial cut. Works on any 58/80 mm thermal printer.
List<int> escPosBytes(String text, {bool kickDrawer = false}) {
  final bytes = <int>[
    0x1B, 0x40, // ESC @ — initialize
    if (kickDrawer) ...[0x1B, 0x70, 0x00, 0x19, 0xFA], // ESC p — drawer pulse
  ];
  for (final unit in text.codeUnits) {
    if (unit == 0x0A || (unit >= 0x20 && unit <= 0x7E)) {
      bytes.add(unit);
    } else {
      bytes.add(0x3F); // '?' — never send multi-byte glyphs the printer lacks
    }
  }
  bytes.addAll([0x0A, 0x0A, 0x0A, 0x0A]); // feed clear of the tear bar
  bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V 66 0 — partial cut
  return bytes;
}
