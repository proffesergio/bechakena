import 'package:bechakena/core/printing/printer_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('printerConfigFromMap', () {
    test('defaults to LAN on port 9100, 58mm', () {
      final cfg = printerConfigFromMap({});
      expect(cfg.type, PrinterTransportType.lan);
      expect(cfg.host, '');
      expect(cfg.port, 9100);
      expect(cfg.width, 32);
      expect(cfg.widthDots, 384);
      expect(cfg.device, '');
    });

    test('parses USB with a device id', () {
      final cfg = printerConfigFromMap({
        'printer.transport': 'usb',
        'printer.device': 'usb-001',
      });
      expect(cfg.type, PrinterTransportType.usb);
      expect(cfg.device, 'usb-001');
    });

    test('parses Bluetooth and 80mm width -> 576 dots', () {
      final cfg = printerConfigFromMap({
        'printer.transport': 'bluetooth',
        'printer.width': '48',
      });
      expect(cfg.type, PrinterTransportType.bluetooth);
      expect(cfg.width, 48);
      expect(cfg.widthDots, 576);
    });

    test('unknown transport falls back to LAN', () {
      expect(printerConfigFromMap({'printer.transport': 'carrier-pigeon'}).type,
          PrinterTransportType.lan);
    });

    test('type round-trips through encode/parse', () {
      for (final t in PrinterTransportType.values) {
        expect(PrinterConfig.parseType(PrinterConfig.encodeType(t)), t);
      }
    });
  });

  group('transport availability with the default backend', () {
    test('LAN is always available; USB/BT are not (no backend)', () async {
      expect(await transportAvailable(PrinterTransportType.lan), isTrue);
      expect(await transportAvailable(PrinterTransportType.usb), isFalse);
      expect(await transportAvailable(PrinterTransportType.bluetooth), isFalse);
    });

    test('discovery is empty for every transport by default', () async {
      expect(await discoverPrinters(PrinterTransportType.lan), isEmpty);
      expect(await discoverPrinters(PrinterTransportType.usb), isEmpty);
    });
  });

  group('sendToPrinter', () {
    test('LAN without a host throws PrinterUnavailable', () {
      expect(
        () => sendToPrinter(const PrinterConfig(), const [0x1B]),
        throwsA(isA<PrinterUnavailable>()),
      );
    });

    test('USB with the default backend throws PrinterUnavailable', () {
      expect(
        () => sendToPrinter(
            const PrinterConfig(type: PrinterTransportType.usb), const [0x1B]),
        throwsA(isA<PrinterUnavailable>()),
      );
    });
  });
}
