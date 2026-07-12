import 'package:flutter/material.dart';

import '../core/db/database.dart';

/// Product art is an emoji stored as `imagePath = "emoji:<glyph>"` until
/// real photos are attached; returns null for photo paths or no art.
String? productEmoji(Product product) {
  final path = product.imagePath;
  if (path == null || !path.startsWith('emoji:')) return null;
  return path.substring(6);
}

/// Parses "#RRGGBB" (category colorHex). Falls back to [fallback].
Color colorFromHex(String? hex, {required Color fallback}) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return fallback;
  final value = int.tryParse(hex.substring(1), radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}
