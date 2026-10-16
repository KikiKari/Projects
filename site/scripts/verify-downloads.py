"""Verify the candidate's actual HTTP downloads against committed files."""
import argparse
import hashlib
import json
import urllib.request
import zipfile
import io
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--base-url', required=True)
p.add_argument('--report', type=Path, required=True)
a = p.parse_args()
root = Path(__file__).resolve().parents[1]
checksum = root / 'public/downloads/tiktok-live-companion-0.8.2-SHA256.txt'
results = []
for line in checksum.read_text(encoding='utf8').splitlines():
    expected, name = line.split('  ', 1)
    url = a.base_url.rstrip('/') + '/downloads/' + name
    with urllib.request.urlopen(url, timeout=30) as response:
        data = response.read()
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected or data != (root / 'public/downloads' / name).read_bytes():
        raise RuntimeError('HTTP artifact mismatch: ' + name)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        if archive.testzip():
            raise RuntimeError('Corrupt archive: ' + name)
        if '-extension-' in name:
            if json.loads(archive.read('manifest.json'))['version'] != '0.8.2':
                raise RuntimeError('Wrong extension version')
            for source in ('background.js', 'content.js', 'sidepanel.js', 'sidepanel.html'):
                if archive.read(source) != (root.parent / 'plugin-source/browser-extension' / source).read_bytes():
                    raise RuntimeError('Extension source mismatch: ' + source)
    results.append({'name': name, 'sha256': actual, 'bytes': len(data), 'verified': True})
a.report.write_text(json.dumps({'base_url': a.base_url, 'artifacts': results}, indent=2), encoding='utf8')
print(json.dumps(results, indent=2))
