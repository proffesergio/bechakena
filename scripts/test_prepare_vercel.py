"""Focused checks for the public showcase package inputs."""

import tempfile
import unittest
from pathlib import Path

import prepare_vercel


class PrepareVercelTests(unittest.TestCase):
    @unittest.skipUnless(prepare_vercel.DEMO.is_dir(), "Flutter web build unavailable")
    def test_required_flutter_files_match_build(self):
        prepare_vercel.require_files(prepare_vercel.DEMO, prepare_vercel.DEMO_REQUIRED)

    def test_private_exports_are_rejected(self):
        for name in ("customers.csv", "database.sql", "credentials.p12"):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                (Path(directory) / name).write_text("private")
                with self.assertRaisesRegex(ValueError, "private/source file"):
                    prepare_vercel.validate_tree(Path(directory))

    def test_flutter_build_bookkeeping_is_ignored(self):
        with tempfile.TemporaryDirectory() as directory:
            (Path(directory) / ".last_build_id").write_text("build id")
            prepare_vercel.validate_tree(Path(directory))


if __name__ == "__main__":
    unittest.main()
