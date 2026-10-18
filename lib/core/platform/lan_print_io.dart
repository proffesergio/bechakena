import 'dart:io';

/// Sends raw ESC/POS bytes to a LAN thermal printer (RAW/JetDirect, port 9100).
Future<void> printToNetwork(String host, int port, List<int> bytes) async {
  final socket = await Socket.connect(host, port,
      timeout: const Duration(seconds: 5));
  try {
    socket.add(bytes);
    await socket.flush();
  } finally {
    await socket.close();
  }
}
