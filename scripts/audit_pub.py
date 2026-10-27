"""Audit every hosted dependency in a Pub-generated lockfile using OSV (stdlib)."""

from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parent.parent
ENDPOINT = 'https://api.osv.dev/v1/querybatch'


def locked_packages(contents):
    # Pub emits one two-space-indented mapping per dependency. SDK packages
    # have no hosted package version and are covered by the Flutter SDK release.
    packages = []
    for match in re.finditer(r'^  ([\w]+):\n((?:^    .*\n|^\n)+)', contents, re.M):
        name, body = match.groups()
        source = re.search(r'^    source: (\w+)$', body, re.M)
        if source and source[1] == 'sdk':
            continue
        version = re.search(r'^    version: "([^"]+)"$', body, re.M)
        if not source or source[1] != 'hosted' or not version:
            raise ValueError(f'Cannot audit dependency: {name}')
        packages.append({'name': name, 'version': version[1]})
    declared = re.findall(r'^  ([\w]+):$', contents, re.M)
    if not packages or len(declared) != len(list(re.finditer(
            r'^  ([\w]+):\n((?:^    .*\n|^\n)+)', contents, re.M))):
        raise ValueError('Unrecognized or empty Pub lockfile')
    return packages


def audit():
    lock = ROOT / 'pubspec.lock'
    contents = lock.read_text(encoding='utf-8')
    packages = locked_packages(contents)
    results = []
    for start in range(0, len(packages), 100):
        batch = packages[start:start + 100]
        queries = [{'package': {'name': p['name'], 'ecosystem': 'Pub'},
                    'version': p['version']} for p in batch]
        request = urllib.request.Request(
            ENDPOINT, data=json.dumps({'queries': queries}).encode(),
            headers={'Content-Type': 'application/json'}, method='POST')
        with urllib.request.urlopen(request, timeout=60) as response:
            chunk = json.load(response)['results']
        if (len(chunk) != len(batch) or any(
                not isinstance(r, dict) or 'next_page_token' in r or 'error' in r
                for r in chunk)):
            raise ValueError('OSV response incomplete; evidence was not replaced')
        results.extend(chunk)
    hits = [{**p, 'vulns': r['vulns']} for p, r in zip(packages, results)
            if r.get('vulns')]
    evidence = {
        'queried_at_utc': datetime.now(timezone.utc).isoformat(),
        'ecosystem': 'Pub', 'source': ENDPOINT, 'lockfile': 'pubspec.lock',
        'lockfile_sha256': hashlib.sha256(lock.read_bytes()).hexdigest(),
        'lockfile_lf_sha256': hashlib.sha256(contents.encode('utf-8')).hexdigest(),
        'packages_checked': len(packages),
        'advisories_found': sum(len(h['vulns']) for h in hits),
        'packages': packages, 'hits': hits, 'results': results,
    }
    output = ROOT / 'docs/dependency-audit/osv-pub-scan.json'
    output.write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
    print(f"Pub: {len(packages)} packages, {evidence['advisories_found']} advisories")
    return 1 if hits else 0


if __name__ == '__main__':
    raise SystemExit(audit())
