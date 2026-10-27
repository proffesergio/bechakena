# Dependency audit evidence

Evidence for audits #1051 and #972 / requirement R6. npm and OSV scans were
rerun on **2026-10-27 (UTC)**; the Pub outdated listing is retained from October 26.
The summary and the reviewer-facing explanation live in
[`../SECURITY.md`](../SECURITY.md#dependency-audit).

| File | Command | Result |
|---|---|---|
| `npm-audit.json` | `cd site && npm audit --json` | 0 vulnerabilities (64 dependencies: 20 prod, 6 dev, 39 optional) |
| `pub-outdated.txt` | `flutter pub outdated --no-color` | Version inventory only; this command is not a vulnerability scanner |
| `osv-pub-scan.json` | `python scripts/audit_pub.py` | All 126 hosted packages checked, 0 advisories; five SDK packages excluded |

Reproduce from the repository root:

```bash
cd site && npm audit --json && cd ..
flutter pub outdated --no-color
python scripts/audit_pub.py
```

`site/package-lock.json` and `pubspec.lock` are both committed. The audit checks
the exact versions that were built and tested; newer releases are maintenance
updates; the security result comes from the advisory scans, not version age.
The OSV evidence includes its UTC timestamp, the SHA-256 of `pubspec.lock`, every
queried package/version and the raw batch results. Five `source: sdk` packages
are supplied by Flutter and are not hosted Pub releases; SDK security must be
reviewed separately. The earlier count of 131 incorrectly included these five.
Both byte-level and LF-normalized lockfile hashes are recorded so Git's Windows
line-ending conversion does not cause a false mismatch in Linux CI.
