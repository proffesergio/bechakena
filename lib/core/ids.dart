import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// UUIDv7 — time-ordered, used as primary key on every table (sync contract).
String newUuidV7() => _uuid.v7();

/// Identifier of this device/install, stamped on every row it writes.
/// Set once at startup from settings; the default marks pre-setup writes.
String currentDeviceId = 'unregistered';
