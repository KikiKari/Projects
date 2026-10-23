#!/usr/bin/env bash
set -euo pipefail
export GOROOT=/runtime-build/aosp/prebuilts/go/linux-arm64/native-go-1.22-sdk-v1
readelf -h "$GOROOT/bin/go" | grep -q 'Machine:.*AArch64'
"$GOROOT/bin/go" version | grep -Fx 'go version go1.22.2 linux/arm64'
bash /runtime-build/build-sdk35-source-finder.sh
cd /runtime-build/aosp
mkdir -p prebuilts/build-tools/linux-arm64/bin
printf '%s  %s\n' '20dd6f4b24b5f449302459b9f50bc9fa928fa1ce85d8df3ab75d8d1889deb665' 'prebuilts/build-tools/linux_musl-arm64/bin/xz' | sha256sum -c -
readelf -h prebuilts/build-tools/linux_musl-arm64/bin/xz | grep -q 'Machine:.*AArch64'
test -e prebuilts/build-tools/linux-arm64/bin/xz || ln -s ../../linux_musl-arm64/bin/xz prebuilts/build-tools/linux-arm64/bin/xz
test "$(readlink -f prebuilts/build-tools/linux-arm64/bin/xz)" = "$(readlink -f prebuilts/build-tools/linux_musl-arm64/bin/xz)"
prebuilts/build-tools/linux-arm64/bin/xz --version
printf '%s  %s\n' 'c75c5acacd29a4ddf16eaecabf6139f01e4ca7a9a135889c9abb29bebc8288fd' 'prebuilts/build-tools/linux_musl-arm64/bin/create_minidebuginfo' | sha256sum -c -
readelf -h prebuilts/build-tools/linux_musl-arm64/bin/create_minidebuginfo | grep -q 'Machine:.*AArch64'
test -e prebuilts/build-tools/linux-arm64/bin/create_minidebuginfo || ln -s ../../linux_musl-arm64/bin/create_minidebuginfo prebuilts/build-tools/linux-arm64/bin/create_minidebuginfo
test "$(readlink -f prebuilts/build-tools/linux-arm64/bin/create_minidebuginfo)" = "$(readlink -f prebuilts/build-tools/linux_musl-arm64/bin/create_minidebuginfo)"
printf '%s  %s\n' 'de8dc6b547049a90be5338d23d6e967aebc1533abfe7d0c63658a17486b9db64' 'prebuilts/build-tools/linux_musl-arm64/bin/flex' | sha256sum -c -
readelf -h prebuilts/build-tools/linux_musl-arm64/bin/flex | grep -q 'Machine:.*AArch64'
test -e prebuilts/build-tools/linux-arm64/bin/flex || ln -s ../../linux_musl-arm64/bin/flex prebuilts/build-tools/linux-arm64/bin/flex
test "$(readlink -f prebuilts/build-tools/linux-arm64/bin/flex)" = "$(readlink -f prebuilts/build-tools/linux_musl-arm64/bin/flex)"
export OUT_DIR=out-sdk35 GOMAXPROCS=8 GOMEMLIMIT=5GiB GOGC=20
out-sdk35/host/linux-arm64/bin/sdk35-source-finder > out-sdk35/soong/source-finder-config.json
mkdir -p out-sdk35/soong/.temp prebuilts/clang/host/linux-arm64
# Use the existing builder's native tool; never relabel an x86 executable.
readelf -h /usr/bin/m4 | grep -q 'Machine:.*AArch64'
mkdir -p prebuilts/build-tools/linux-arm64/bin
test -e prebuilts/build-tools/linux-arm64/bin/m4 || ln -s /usr/bin/m4 prebuilts/build-tools/linux-arm64/bin/m4
test "$(readlink -f prebuilts/build-tools/linux-arm64/bin/m4)" = /usr/bin/m4
sha256sum /usr/bin/m4
readelf -h /usr/bin/bison | grep -q 'Machine:.*AArch64'
test -e prebuilts/build-tools/linux-arm64/bin/bison || ln -s /usr/bin/bison prebuilts/build-tools/linux-arm64/bin/bison
test "$(readlink -f prebuilts/build-tools/linux-arm64/bin/bison)" = /usr/bin/bison
sha256sum /usr/bin/bison
readelf -h "$JAVA_HOME/bin/javap" | grep -q 'Machine:.*AArch64'
"$JAVA_HOME/bin/javap" -version | grep '^21\.'
test -e prebuilts/jdk/jdk21/linux-arm64 || ln -s "$JAVA_HOME" prebuilts/jdk/jdk21/linux-arm64
test "$(readlink -f prebuilts/jdk/jdk21/linux-arm64)" = "$(readlink -f "$JAVA_HOME")"
sha256sum "$JAVA_HOME/bin/javap"
test -L Android.bp || ln -s build/soong/root.bp Android.bp
python3 /runtime-build/ensure-sdk35-native-compiler.py
# Version the packaging layout so Ninja rebuilds objects made with upstream atomic headers.
test -L prebuilts/clang/host/linux-arm64/clang-native-aosp-atomic-v1 || ln -s clang-native prebuilts/clang/host/linux-arm64/clang-native-aosp-atomic-v1
test "$(readlink prebuilts/clang/host/linux-arm64/clang-native-aosp-atomic-v1)" = clang-native
python3 - <<'PY'
import json
import re
from pathlib import Path
out = Path('out-sdk35/soong')
variables = {
 'HostArch': 'arm64', 'HostMusl': False,
 'DeviceName': 'sdk35_native_host', 'DeviceProduct': 'sdk35_native_host',
 'DeviceArch': 'arm64', 'DeviceArchVariant': 'armv8-a',
 'DeviceCpuVariant': 'generic', 'DeviceAbi': ['arm64-v8a'],
 'DeviceMaxPageSizeSupported': '4096', 'DeviceNoBionicPageSizeMacro': False,
 'Platform_version_name': '15', 'Platform_sdk_version': 35,
 'Platform_sdk_codename': 'REL', 'Platform_sdk_final': True,
 'Platform_sdk_version_or_codename': '35',
 'Platform_version_active_codenames': [], 'Platform_version_all_preview_codenames': [],
 'Platform_version_last_stable': '15',
 'Platform_base_sdk_extension_version': 13, 'Platform_sdk_extension_version': 13,
 'BuildFlags': {}, 'VendorVars': {}, 'Allow_missing_dependencies': False,
}
release = json.loads(Path('out-sdk35/release-config/all_release_configs-sdk35_native_host.json').read_text())
assert release['release_config']['name'] == 'ap4a'
for flag in release['release_config']['flags']:
    value = flag['value']['Val']
    if value is None:
        rendered = ''
    elif 'BoolValue' in value:
        rendered = 'true' if value['BoolValue'] else 'false'
    elif 'StringValue' in value:
        rendered = value['StringValue']
    elif 'UnspecifiedValue' in value:
        rendered = ''
    else:
        raise RuntimeError('Unknown release flag encoding: ' + repr(value))
    variables['BuildFlags'][flag['flag_declaration']['name']] = rendered
assert 'RELEASE_HIDDEN_API_EXPORTABLE_STUBS' in variables['BuildFlags']
# Preserve the types emitted by the original ap4a release generator.
# Values remain those read above from its JSON; no replacement defaults.
type_file = Path('out-sdk35/release-config/release_config-sdk35_native_host-ap4a.varmk')
type_pairs = re.findall(
    r'^_ALL_RELEASE_FLAGS\.([A-Za-z0-9_]+)\.TYPE :=\$= (\S+)\s*$',
    type_file.read_text(), re.MULTILINE)
flag_types = dict(type_pairs)
assert len(flag_types) == len(type_pairs), 'Duplicate release flag type'
assert set(flag_types) == set(variables['BuildFlags']), 'Release flag/type key mismatch'
assert set(flag_types.values()) <= {'bool', 'string', 'unspecified', 'obsolete'}, 'Unknown release flag type'
variables['BuildFlagTypes'] = flag_types
# Mirror the locked Make chain: RELEASE_BOARD_API_LEVEL -> BOARD_API_LEVEL
# -> PLATFORM_SEPOLICY_VERSION and BOARD_SEPOLICY_VERS. No fallback value.
board_api = variables['BuildFlags']['RELEASE_BOARD_API_LEVEL']
assert flag_types['RELEASE_BOARD_API_LEVEL'] == 'string'
assert re.fullmatch(r'[0-9]{6}', board_api), 'Invalid release board API level'
policy_bp = Path('system/sepolicy/prebuilts/api') / board_api / 'Android.bp'
assert re.search(r'\bname\s*:\s*"' + re.escape(board_api + '_plat_pub_policy.cil') + r'"', policy_bp.read_text()), 'Original SEPolicy prebuilt module missing'
variables['PlatformSepolicyVersion'] = board_api
variables['BoardSepolicyVers'] = board_api
# Use the locked CPython factory's supported source-build switch.
import subprocess
system_sdk_origin = json.loads(subprocess.check_output(['python3', '/runtime-build/derive-sdk35-system-sdk.py'], text=True))
variables['Platform_systemsdk_versions'] = system_sdk_origin['Platform_systemsdk_versions']
variables['BuildId'] = system_sdk_origin['BuildId']
for key in ['Platform_sdk_extension_version','Platform_base_sdk_extension_version']:
    variables[key] = system_sdk_origin[key]
assert str(variables['Platform_sdk_version']) in variables['Platform_systemsdk_versions']
variables.setdefault('VendorVars', {}).setdefault('cpython3', {})['force_build_host'] = 'true'
variables.setdefault('VendorVarTypes', {}).setdefault('cpython3', {})['force_build_host'] = 'bool'
(out / 'soong.variables').write_text(json.dumps(variables, indent=2))
# Consume the original Soong UI source-finder output.
import shutil
shutil.copyfile('out-sdk35/.module_paths/Android.bp.list', out / 'Android.bp.list')
finder_config = json.loads((out / 'source-finder-config.json').read_text())
assert Path(finder_config['LOG_DIR']).is_absolute()
env = {'LOG_DIR': finder_config['LOG_DIR'],
       'LLVM_PREBUILTS_BASE': 'prebuilts/clang/host',
       'LLVM_PREBUILTS_VERSION': 'native-clang-r530567-v1',
       'LLVM_BINDGEN_PREBUILTS_VERSION': 'native-clang-r530567-bindgen-cxx-v1',
       # Only the original Java 8 bootclasspath JARs are consumed here.
       'ANDROID_JAVA8_HOME': 'prebuilts/jdk/jdk8/linux-x86'}
# Keep pinned prebuilt libraries/CI artifacts separate from the native compiler.
clang_config = Path('build/soong/cc/config/global.go').read_text()
artifact_version = re.search(r'ClangDefaultVersion\s*=\s*"([^"]+)"', clang_config)
assert artifact_version
env['LLVM_PREBUILTS_ARTIFACT_VERSION'] = artifact_version.group(1)
# Native ARM64 has no matching original SDK LLVM prebuilt; use the locked source factory.
env['FORCE_BUILD_LLVM_COMPONENTS'] = 'true'
assert all(Path(env['ANDROID_JAVA8_HOME'], 'jre/lib', n).is_file() for n in ['jce.jar', 'rt.jar'])
(out / 'available.env').write_text(json.dumps([{'Key': k, 'Value': v} for k, v in sorted(env.items())]))
PY
export GOMAXPROCS=8
# Go runtime soft memory budget; Docker hard cap remains 16 GiB.
export GOMEMLIMIT=5GiB
export GOGC=20
out-sdk35/host/linux-arm64/bin/soong_build --top . --out out-sdk35 \
 --soong_out out-sdk35/soong --soong_variables out-sdk35/soong/soong.variables \
 --available_env out-sdk35/soong/available.env --used_env out-sdk35/soong/used.env \
 -l out-sdk35/soong/Android.bp.list -o out-sdk35/soong/build.ninja Android.bp
