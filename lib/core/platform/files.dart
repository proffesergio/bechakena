// Platform abstraction for local file operations (paths, images, downloads).
//
// Native (IO) writes real files under the app/support directories; web has no
// filesystem, so "downloads" become browser downloads and file-backed images
// simply don't exist. Feature code imports only this facade.
export 'files_io.dart' if (dart.library.js_interop) 'files_web.dart';
