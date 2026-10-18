import '../printing/printer_transport.dart';

/// Browsers can't open raw TCP sockets — LAN printing is a desktop/tablet
/// feature. The receipt preview still works on the web demo.
Future<void> printToNetwork(String host, int port, List<int> bytes) async {
  throw const PrinterUnavailable(
      'Printing needs the desktop or mobile app — this is the browser demo');
}
