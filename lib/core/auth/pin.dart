import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Staff PIN hashing — salted, iterated SHA-256 (PBKDF2-style), verified fully
/// offline. Stored form: `pbkdf2sha256$<iterations>$<saltB64>$<digestB64>`.
const _iterations = 12000;
final _rng = Random.secure();

String hashPin(String pin) {
  if (pin.isEmpty) {
    throw ArgumentError.value(pin, 'pin', 'PIN must not be empty');
  }
  final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => _rng.nextInt(256)));
  final digest = _pbkdf2(pin, salt, _iterations);
  return 'pbkdf2sha256\$$_iterations\$${base64.encode(salt)}\$${base64.encode(digest)}';
}

bool verifyPin(String pin, String storedHash) {
  final parts = storedHash.split(r'$');
  if (parts.length != 4 || parts[0] != 'pbkdf2sha256') return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null) return false;
  Uint8List salt;
  Uint8List expected;
  try {
    salt = base64.decode(parts[2]);
    expected = base64.decode(parts[3]);
  } on FormatException {
    return false;
  }
  final actual = _pbkdf2(pin, salt, iterations);
  return _constantTimeEquals(actual, expected);
}

/// PBKDF2-HMAC-SHA256, single output block (32 bytes ≥ our needs).
Uint8List _pbkdf2(String password, Uint8List salt, int iterations) {
  final hmac = Hmac(sha256, utf8.encode(password));
  // U1 = HMAC(salt || INT(1))
  var u = Uint8List.fromList(hmac.convert([...salt, 0, 0, 0, 1]).bytes);
  final result = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = Uint8List.fromList(hmac.convert(u).bytes);
    for (var j = 0; j < result.length; j++) {
      result[j] ^= u[j];
    }
  }
  return result;
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
