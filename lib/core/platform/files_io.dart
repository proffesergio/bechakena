import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// True when [path] names an existing local file.
bool fileExists(String path) => File(path).existsSync();

/// Renders the image stored at the local file [path].
Widget fileImage(String path,
    {Key? key, BoxFit? fit, double? width, double? height}) =>
    Image.file(File(path),
        key: key, fit: fit, width: width, height: height);

/// Writes [text] to an explicit filesystem [path] (used after a save dialog).
Future<void> writeTextToPath(String path, String text) async {
  await File(path).writeAsString(text);
}

/// Saves [text] as [filename] in the Downloads folder (falling back to app
/// documents) and returns the full path.
Future<String> saveTextFile(String filename, String text) async {
  final dir = await getDownloadsDirectory() ??
      await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(text);
  return file.path;
}

/// Saves [bytes] as [filename] in the Downloads folder and returns the path.
Future<String> saveBinaryFile(String filename, List<int> bytes) async {
  final dir = await getDownloadsDirectory() ??
      await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Reads a local file, or null when it doesn't exist (e.g. a missing logo).
Future<Uint8List?> readLocalFileBytes(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

/// Handles the web demo's `?fresh=1` reset URL. No-op on native.
Future<void> maybeHandleFreshReset() async {}

