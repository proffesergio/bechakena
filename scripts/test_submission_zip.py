import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

from make_submission_zip import REQUIRED, included, package


class SubmissionZipTests(unittest.TestCase):
    def test_private_and_generated_files_are_excluded(self):
        for name in ('.env', 'site/.env.production', '.git/config', 'site/node_modules/a.js',
                     'site/out/index.html', 'lib/core/db/database.g.dart', 'keys/live.pem',
                     'shop.sqlite3', 'tmp/audit.txt', 'android/local.properties',
                     'dist/bechakena-vibe96.zip', 'site/tsconfig.tsbuildinfo'):
            self.assertFalse(included(Path(name)), name)
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
            self.assertTrue(output.with_suffix('.zip.sha256').is_file())

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
