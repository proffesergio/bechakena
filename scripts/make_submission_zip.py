"""Build a clean source submission on Windows, macOS or Linux (stdlib only)."""

from fnmatch import fnmatch
import hashlib
import os
from pathlib import Path
import sys
import zipfile

ROOT = Path(__file__).resolve().parent.parent
EXCLUDED_DIRS = {
    '.git', 'pyenv', 'venv', '.venv', '.dart_tool', 'build', 'ephemeral',
    '.gradle', 'Pods', 'coverage', 'dist', '.vercel', '.idea', '.claude',
    '.codex', '.agents', '__pycache__', 'node_modules', '.next',
    'graphify-out', 'tmp', '.pytest_cache', '.pub-cache',
}
EXCLUDED_FILES = (
    '*.pyc', '*.log', '*.zip', '*.zip.tmp', '*.iml', '*.g.dart', '*.freezed.dart',
    '*.tsbuildinfo', '.flutter-plugins-dependencies', '.DS_Store',
    '*.key', '*.pem', '*.p12', '*.pfx', '*.jks', '*.keystore',
    '*.db', '*.sqlite', '*.sqlite3', 'local.properties', 'key.properties',
)
REQUIRED = (
    'README.md', 'HowToSetup.md', 'CLAUDE.md', 'CHANGELOG.md', 'LICENSE-NOTE.md',
    '.env.example', 'docker-compose.yml', 'docker/Dockerfile',
    'database/schema.sql', 'database/seed.sql', 'database/README.md',
    'mobile/README.md', 'pubspec.yaml', 'pubspec.lock', 'site/package.json',
    'site/package-lock.json', 'scripts/prepare_vercel.py',
    'site/app/submission.css', 'site/public/media/cover.png',
    'site/public/media/landing-square.png', 'docs/RESUBMISSION.md', 'AUDIT_RESPONSE.md',
)


def included(relative):
    if any(part in EXCLUDED_DIRS for part in relative.parts):
        return False
    if relative.parts[:2] == ('site', 'out'):
        return False
    if relative.as_posix() in {'package.json', 'package-lock.json'}:
        return False  # Root npm files are local tooling; the application is in site/.
    name = relative.name
    if name.startswith('.env') and name != '.env.example':
        return False
    return not any(fnmatch(name.lower(), pattern.lower()) for pattern in EXCLUDED_FILES)


def package(root, output):
    files = []
    # Prune caches before traversal, rather than walking node_modules/build output.
    for directory_name, dirs, names in os.walk(root, followlinks=False):
        directory = Path(directory_name)
        dirs[:] = sorted(d for d in dirs if included((directory / d).relative_to(root)))
        for name in sorted(names):
            path = directory / name
            relative = path.relative_to(root)
            if included(relative):
                if path.is_symlink():
                    raise ValueError(f'Symlinks cannot be submitted: {relative}')
                if path.stat().st_size == 0 and relative.as_posix() in REQUIRED:
                    raise ValueError(f'Empty required file: {relative}')
                files.append(relative)
    names = {path.as_posix() for path in files}
    missing = set(REQUIRED) - names
    if missing:
        raise ValueError(f'Missing submission files: {sorted(missing)}')
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix('.zip.tmp')
    try:
        with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for relative in files:
                archive.write(root / relative, relative.as_posix())
        with zipfile.ZipFile(temporary) as archive:
            assert archive.testzip() is None, 'ZIP integrity check failed'
            assert set(archive.namelist()) == names, 'ZIP contents differ from source'
            assert all(included(Path(name)) for name in archive.namelist())
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix('.zip.sha256').write_text(f'{digest}  {output.name}\n')
    print(f'Archive: {output}\nFiles: {len(files)}\nBytes: {output.stat().st_size}\nSHA-256: {digest}')


if __name__ == '__main__':
    package(ROOT, Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / 'dist/bechakena-vibe96.zip')
