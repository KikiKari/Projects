import argparse
import hashlib
import json
import shutil
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def add_tree(archive: zipfile.ZipFile, source: Path, prefix: str = "") -> None:
    for path in sorted(source.rglob("*")):
        if not path.is_file() or "__pycache__" in path.parts or path.suffix == ".pyc":
            continue
        relative = path.relative_to(source)
        archive.write(path, Path(prefix) / relative)


parser = argparse.ArgumentParser(description="Package TikTok LIVE Companion artifacts.")
parser.add_argument("--output-dir", type=Path, required=True)
args = parser.parse_args()
args.output_dir.mkdir(parents=True, exist_ok=True)
output_dir = args.output_dir.resolve()

manifest = json.loads((ROOT / "browser-extension" / "manifest.json").read_text(encoding="utf-8"))
version = manifest["version"]
extension_zip = args.output_dir / f"tiktok-live-companion-extension-{version}.zip"
plugin_zip = args.output_dir / f"tiktok-live-companion-plugin-{version}.zip"
extension_dir = args.output_dir / f"tiktok-live-companion-extension-{version}"
checksum_file = args.output_dir / f"tiktok-live-companion-{version}-SHA256.txt"

resolved_extension_dir = extension_dir.resolve()
if resolved_extension_dir.parent != output_dir:
    raise RuntimeError("Refusing to package outside the requested output directory")
if extension_dir.exists():
    shutil.rmtree(extension_dir)
shutil.copytree(ROOT / "browser-extension", extension_dir)

with zipfile.ZipFile(extension_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    add_tree(archive, ROOT / "browser-extension")

with zipfile.ZipFile(plugin_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    add_tree(archive, ROOT, "tiktok-live-companion")

checksums = []
for artifact in (extension_zip, plugin_zip):
    digest = hashlib.sha256(artifact.read_bytes()).hexdigest()
    checksums.append(f"{digest}  {artifact.name}")
checksum_file.write_text("\n".join(checksums) + "\n", encoding="utf-8")

print(json.dumps({
    "extension_dir": str(extension_dir.resolve()),
    "extension_zip": str(extension_zip.resolve()),
    "plugin_zip": str(plugin_zip.resolve()),
    "checksum_file": str(checksum_file.resolve()),
    "version": version
}, ensure_ascii=False))
