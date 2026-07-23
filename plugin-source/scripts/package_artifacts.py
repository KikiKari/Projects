import argparse
import hashlib
import json
import shutil
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
PROJECT_ROOT = ROOT.parent
EXCLUDED_PARTS = {"__pycache__", ".gradle", ".kotlin", "build", "DerivedData", "xcuserdata", "stage", "output"}


def add_tree(archive: zipfile.ZipFile, source: Path, prefix: str = "") -> None:
    for path in sorted(source.rglob("*")):
        if not path.is_file() or EXCLUDED_PARTS.intersection(path.parts) or path.suffix in {".pyc", ".aar"}:
            continue
        relative = path.relative_to(source)
        archive.write(path, Path(prefix) / relative)


parser = argparse.ArgumentParser(description="Package TikTok LIVE Companion artifacts.")
parser.add_argument("--output-dir", type=Path, required=True)
parser.add_argument("--android-apk", type=Path, help="Optional verified mockDebug or shazamDebug APK")
parser.add_argument("--include-mobile", action="store_true", help="Also package unchanged mobile source projects")
parser.add_argument("--installer", type=Path, help="Verified Windows installer to include in the release")
args = parser.parse_args()
args.output_dir.mkdir(parents=True, exist_ok=True)
output_dir = args.output_dir.resolve()

manifest = json.loads((ROOT / "browser-extension" / "manifest.json").read_text(encoding="utf-8"))
version = manifest["version"]
extension_zip = args.output_dir / f"tiktok-live-companion-extension-{version}.zip"
plugin_zip = args.output_dir / f"tiktok-live-companion-plugin-{version}.zip"
service_zip = args.output_dir / f"tiktok-live-companion-service-{version}.zip"
ios_source_zip = args.output_dir / f"tiktok-live-companion-ios-{version}-source.zip"
android_source_zip = args.output_dir / f"tiktok-live-companion-android-{version}-source.zip"
android_apk = args.output_dir / f"tiktok-live-companion-android-{version}-debug.apk"
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

with zipfile.ZipFile(service_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
    add_tree(archive, ROOT / "companion-service")

if args.include_mobile:
    with zipfile.ZipFile(ios_source_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        add_tree(archive, PROJECT_ROOT / "mobile" / "ios", "TikTokLiveCompanion-iOS")
    with zipfile.ZipFile(android_source_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        add_tree(archive, PROJECT_ROOT / "mobile" / "android", "TikTokLiveCompanion-Android")

if args.android_apk:
    source_apk = args.android_apk.resolve()
    if not source_apk.is_file() or source_apk.suffix.lower() != ".apk":
        raise RuntimeError("--android-apk must point to an existing APK")
    shutil.copy2(source_apk, android_apk)

artifacts = [extension_zip, plugin_zip, service_zip]
if args.include_mobile:
    artifacts.extend([ios_source_zip, android_source_zip])
if android_apk.exists():
    artifacts.append(android_apk)
installer_copy = None
if args.installer:
    source_installer = args.installer.resolve()
    if not source_installer.is_file() or source_installer.suffix.lower() != ".exe":
        raise RuntimeError("--installer must point to an existing EXE")
    installer_copy = args.output_dir / source_installer.name
    shutil.copy2(source_installer, installer_copy)
    artifacts.append(installer_copy)
checksums = []
for artifact in artifacts:
    digest = hashlib.sha256(artifact.read_bytes()).hexdigest()
    checksums.append(f"{digest}  {artifact.name}")
checksum_file.write_text("\n".join(checksums) + "\n", encoding="utf-8")

print(json.dumps({
    "extension_dir": str(extension_dir.resolve()),
    "extension_zip": str(extension_zip.resolve()),
    "plugin_zip": str(plugin_zip.resolve()),
    "service_zip": str(service_zip.resolve()),
    "ios_source_zip": str(ios_source_zip.resolve()) if args.include_mobile else None,
    "android_source_zip": str(android_source_zip.resolve()) if args.include_mobile else None,
    "android_apk": str(android_apk.resolve()) if android_apk.exists() else None,
    "installer": str(installer_copy.resolve()) if installer_copy else None,
    "checksum_file": str(checksum_file.resolve()),
    "version": version
}, ensure_ascii=False))
