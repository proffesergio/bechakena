import tempfile
import hashlib
import unittest
from pathlib import Path
from zipfile import ZipFile

from make_submission_zip import REQUIRED, included, package


class SubmissionZipTests(unittest.TestCase):
    def test_private_and_generated_files_are_excluded(self):
        for name in ('.env', 'site/.env.production', '.git/config', 'site/node_modules/a.js',
                     'site/out/index.html', 'site/.next/server/page.js',
                     'build/windows/x64/runner/Release/bechakena.exe',
                     '.dart_tool/package_config.json', '.vercel/output/config.json',
                     'lib/core/db/database.g.dart', 'lib/app/router.freezed.dart',
                     'keys/live.pem', 'shop.sqlite3', 'tmp/audit.txt',
                     'shop.db-wal', 'shop.sqlite3-shm', 'shop.db-journal',
                     '.aws/credentials', '.ssh/id_ed25519',
                     'android/local.properties', 'dist/bechakena-vibe96.zip',
                     'site/tsconfig.tsbuildinfo', 'package.json', 'package-lock.json'):
            self.assertFalse(included(Path(name)), name)
        for name in ('windows/runner/main.cpp', 'windows/runner/win32_window.cpp',
                     'windows/runner/flutter_window.cpp', 'windows/runner/Runner.rc',
                     'site/app/layout.tsx', 'docs/SECURITY.md',
                     'docs/dependency-audit/npm-audit.json'):
            self.assertTrue(included(Path(name)), name)
        for name in REQUIRED:
            self.assertTrue(included(Path(name)), name)

    def test_archive_has_updated_sources_and_media_without_private_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in (*REQUIRED, 'site/.env.production', 'site/node_modules/private.js'):
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('fixture')
            output = root / 'dist/test.zip'
            package(root, output)
            with ZipFile(output) as archive:
                self.assertEqual(set(archive.namelist()), set(REQUIRED))
                for name in REQUIRED:
                    self.assertEqual(archive.read(name), (root / name).read_bytes())
            digest = hashlib.sha256(output.read_bytes()).hexdigest()
            self.assertEqual(output.with_suffix('.zip.sha256').read_text(),
                             f'{digest}  test.zip\n')

            # Replacing the package must include edits, not reuse old ZIP entries.
            (root / 'lib/main.dart').write_text('updated source')
            package(root, output)
            with ZipFile(output) as archive:
                self.assertEqual(archive.read('lib/main.dart'), b'updated source')

    def test_missing_windows_header_preserves_existing_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in REQUIRED:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('fixture')
            output = root / 'dist/test.zip'
            package(root, output)
            previous = output.read_bytes()
            (root / 'windows/runner/flutter_window.h').unlink()
            with self.assertRaisesRegex(ValueError, 'flutter_window.h'):
                package(root, output)
            self.assertEqual(output.read_bytes(), previous)

    def test_linked_source_directory_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / 'outside'
            target.mkdir()
            linked = root / 'lib'
            try:
                linked.symlink_to(target, target_is_directory=True)
            except OSError:
                self.skipTest('Creating symlinks requires OS permission')
            with self.assertRaisesRegex(ValueError, 'Linked directories'):
                package(root, root / 'dist/test.zip')

    def test_incomplete_source_does_not_replace_existing_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            output = root / 'dist/test.zip'
            output.parent.mkdir()
            output.write_bytes(b'previous archive')
            with self.assertRaisesRegex(ValueError, 'Missing submission files'):
                package(root, output)
            self.assertEqual(output.read_bytes(), b'previous archive')


if __name__ == '__main__':
    unittest.main()
