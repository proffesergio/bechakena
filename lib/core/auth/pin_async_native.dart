import 'dart:isolate';
import 'pin.dart';

/// Keep native PIN work off the UI isolate without coupling database tooling
/// to Flutter or dart:ui.
Future<String> hashPinAsync(String pin) => Isolate.run(() => hashPin(pin));
Future<bool> verifyPinAsync(String pin, String stored) =>
    Isolate.run(() => verifyPin(pin, stored));
