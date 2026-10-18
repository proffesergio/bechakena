import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:drift/wasm.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// The web has no user-visible filesystem: stored paths (logos, product
/// images) can never resolve, so file-backed images render a placeholder and
/// "saving" becomes a browser download.
bool fileExists(String path) => false;

Widget fileImage(String path,
        {Key? key, BoxFit? fit, double? width, double? height}) =>
    Icon(Icons.image_outlined, key: key, size: width);

Future<void> writeTextToPath(String path, String text) async {
  // No filesystem on the web — callers gate this behind kIsWeb.
  throw UnsupportedError('Writing to a path is not available on the web');
}

Future<String> saveTextFile(String filename, String text) =>
    _download(filename, utf8.encode(text), 'text/plain;charset=utf-8');

Future<String> saveBinaryFile(String filename, List<int> bytes) {
  final mime = filename.endsWith('.pdf')
      ? 'application/pdf'
      : filename.endsWith('.png')
          ? 'image/png'
          : 'application/octet-stream';
  return _download(filename, bytes, mime);
}

Future<Uint8List?> readLocalFileBytes(String path) async => null;

/// `?fresh=1` wipes this demo visitor's state (both module databases + the
/// device store) and reloads with a clean URL — the browser equivalent of
/// Settings → Clear local data.
Future<void> maybeHandleFreshReset() async {
  final uri = Uri.base;
  if (uri.queryParameters['fresh'] != '1') return;
  // Drift may store in either IndexedDB or OPFS. Ask its worker to delete the
  // actual storage, and wait before a new app can open the databases again.
  for (final module in ['superShop', 'restaurant']) {
    final name = 'bechakena_$module';
    final storage = await WasmDatabase.probe(
      databaseName: name,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    for (final database in storage.existingDatabases) {
      if (database.$2 == name) await storage.deleteDatabase(database);
    }
  }
  web.window.localStorage.removeItem('bechakena.device');
  final params = Map<String, String>.from(uri.queryParameters)..remove('fresh');
  web.window.location.replace(uri.replace(queryParameters: params).toString());
  // Navigation is asynchronous. Do not continue startup and reopen the DB.
  await Completer<void>().future;
}


/// Hands [bytes] to the browser as a download named [filename] and returns the
/// filename (there is no path to report on the web).
Future<String> _download(String filename, List<int> bytes, String mime) async {
  final blob = web.Blob(
      [Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: mime));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  // Revoke on the next tick so the download has grabbed the blob already.
  Future<void>.delayed(
      const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  return filename;
}
