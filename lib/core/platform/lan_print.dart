// LAN (RAW/JetDirect) printing over a TCP socket — native only. The web
// build swaps in a stub that reports printing as a desktop feature.
export 'lan_print_io.dart' if (dart.library.js_interop) 'lan_print_web.dart';
