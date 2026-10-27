import unittest
import hashlib
import json

from audit_pub import ROOT, locked_packages


class PubAuditTests(unittest.TestCase):
    def test_evidence_covers_current_lockfile(self):
        lock = ROOT / 'pubspec.lock'
        evidence = json.loads((ROOT / 'docs/dependency-audit/osv-pub-scan.json')
                              .read_text(encoding='utf-8'))
        # Git may convert CRLF/LF on checkout; compare normalized text in CI.
        self.assertEqual(evidence['lockfile_lf_sha256'], hashlib.sha256(
            lock.read_text(encoding='utf-8').encode('utf-8')).hexdigest())
        self.assertEqual(evidence['packages'],
                         locked_packages(lock.read_text(encoding='utf-8')))
        self.assertEqual(evidence['packages_checked'], len(evidence['results']))

    def test_reads_all_hosted_packages_in_submission_lockfile(self):
        contents = (ROOT / 'pubspec.lock').read_text(encoding='utf-8')
        packages = locked_packages(contents)
        self.assertEqual(len(packages), contents.count('    source: hosted\n'))
        self.assertEqual(len({p['name'] for p in packages}), len(packages))
        self.assertIn({'name': 'crypto', 'version': '3.0.7'}, packages)
        self.assertNotIn('flutter', {p['name'] for p in packages})

    def test_unknown_sources_and_malformed_input_are_not_silently_skipped(self):
        for text in ('', 'packages:\n  foo:\n',
                     'packages:\n  foo:\n    source: git\n    version: "1.0.0"\n'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                locked_packages(text)


if __name__ == '__main__':
    unittest.main()
