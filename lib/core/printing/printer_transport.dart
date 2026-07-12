import '../db/database.dart';
import 'print_service.dart';

/// How the app reaches the thermal printer.
///
/// - [lan]  — RAW/JetDirect over TCP (port 9100). Pure `dart:io` sockets, so it
///   works on every platform with no plugin. This is the default.
/// - [usb]  — USB thermal printer (Windows/Android). Needs a native backend.
/// - [bluetooth] — Bluetooth thermal printer (Android). Needs a native backend.
///
/// USB and Bluetooth are first-class here, but the bytes are handed to a
/// [PrinterBackend]. The built-in backend has no USB/BT support, so those
/// transports report "unavailable" until a plugin backend is registered via
/// [printerBackend] — see `docs/OPERATIONS.md`. This keeps every platform
/// building while letting a shop enable USB/BT after testing on real hardware.
enum PrinterTransportType { lan, usb, bluetooth }

/// A resolved printer connection, read from settings.
class PrinterConfig {
  const PrinterConfig({
    this.type = PrinterTransportType.lan,
    this.host = '',
    this.port = 9100,
    this.width = 32,
    this.device = '',
  });

  /// Which transport to use.
  final PrinterTransportType type;

  /// LAN printer IP.
  final String host;

  /// LAN printer port (9100 for RAW/JetDirect).
  final int port;

  /// Receipt width in characters: 32 for 58 mm paper, 48 for 80 mm.
  final int width;

  /// USB/Bluetooth device identifier (address or system id) chosen in Settings.
  final String device;

  /// Printable dots across the head for the selected paper.
  int get widthDots => width >= 48 ? 576 : 384;

  static PrinterTransportType parseType(String? raw) => switch (raw) {
        'usb' => PrinterTransportType.usb,
        'bluetooth' => PrinterTransportType.bluetooth,
        _ => PrinterTransportType.lan,
      };

  static String encodeType(PrinterTransportType type) => switch (type) {
        PrinterTransportType.usb => 'usb',
        PrinterTransportType.bluetooth => 'bluetooth',
        PrinterTransportType.lan => 'lan',
      };
}

/// Builds a [PrinterConfig] from raw settings values (pure — easy to test).
PrinterConfig printerConfigFromMap(Map<String, String?> m) => PrinterConfig(
      type: PrinterConfig.parseType(m['printer.transport']),
      host: m['printer.host'] ?? '',
      port: int.tryParse(m['printer.port'] ?? '') ?? 9100,
      width: int.tryParse(m['printer.width'] ?? '') ?? 32,
      device: m['printer.device'] ?? '',
    );

/// Reads the saved printer configuration.
Future<PrinterConfig> loadPrinterConfig(SettingsDao settings) async {
  return printerConfigFromMap({
    'printer.transport': await settings.getValue('printer.transport'),
    'printer.host': await settings.getValue('printer.host'),
    'printer.port': await settings.getValue('printer.port'),
    'printer.width': await settings.getValue('printer.width'),
    'printer.device': await settings.getValue('printer.device'),
  });
}

/// A discoverable USB/Bluetooth printer.
class PrinterDevice {
  const PrinterDevice({required this.id, required this.name});
  final String id;
  final String name;
}

/// Thrown when the chosen transport can't deliver — misconfigured LAN, or a
/// USB/BT backend that isn't wired in on this platform.
class PrinterUnavailable implements Exception {
  const PrinterUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Pluggable native transport for USB/Bluetooth. The default implementation
/// supports neither; register a plugin-backed one in `main()` to enable them.
abstract interface class PrinterBackend {
  Future<bool> supports(PrinterTransportType type);
  Future<List<PrinterDevice>> discover(PrinterTransportType type);
  Future<void> send(PrinterTransportType type, String device, List<int> bytes);
}

/// Ships with LAN only (handled directly by [sendToPrinter]); USB/BT report
/// unavailable here. See `docs/OPERATIONS.md` for the plugin wiring point.
class DefaultPrinterBackend implements PrinterBackend {
  const DefaultPrinterBackend();

  @override
  Future<bool> supports(PrinterTransportType type) async => false;

  @override
  Future<List<PrinterDevice>> discover(PrinterTransportType type) async =>
      const [];

  @override
  Future<void> send(
          PrinterTransportType type, String device, List<int> bytes) async =>
      throw const PrinterUnavailable(
          'USB/Bluetooth printing is not enabled on this build');
}

/// The active backend. Swap this out (once) in `main()` to plug in a real
/// USB/Bluetooth printer plugin.
PrinterBackend printerBackend = const DefaultPrinterBackend();

/// True if [type] can print right now (LAN always; USB/BT if a backend supports
/// it).
Future<bool> transportAvailable(PrinterTransportType type) async =>
    type == PrinterTransportType.lan ? true : printerBackend.supports(type);

/// Lists selectable devices for a USB/BT transport (empty for LAN).
Future<List<PrinterDevice>> discoverPrinters(PrinterTransportType type) async =>
    type == PrinterTransportType.lan ? const [] : printerBackend.discover(type);

/// Sends already-encoded ESC/POS [bytes] over the configured transport.
Future<void> sendToPrinter(PrinterConfig cfg, List<int> bytes) async {
  switch (cfg.type) {
    case PrinterTransportType.lan:
      if (cfg.host.isEmpty) {
        throw const PrinterUnavailable('Set the printer IP in Settings first');
      }
      await printToNetwork(cfg.host, cfg.port, bytes);
    case PrinterTransportType.usb:
    case PrinterTransportType.bluetooth:
      await printerBackend.send(cfg.type, cfg.device, bytes);
  }
}
