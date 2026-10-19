import 'pin.dart';

// Browser builds do not support Dart isolates. Yield before the bounded work.
Future<String> hashPinAsync(String pin) => Future(() => hashPin(pin));
Future<bool> verifyPinAsync(String pin, String stored) =>
    Future(() => verifyPin(pin, stored));
