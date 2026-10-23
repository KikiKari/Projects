#!/usr/bin/env bash
set -euo pipefail
cd "$HOME/tlc-integration/sdk35-runtime-build"
test "$(uname -m)" = aarch64
stage="${1:?stage name required}"
python3 ./preflight-sdk35-disk.py "$stage"
case "$stage" in
  rust-dependency-audit) command=(bash /runtime-build/run-rust-dependency-audit.sh) ;;
  module-cache-seed) command=(python3 /runtime-build/seed-sdk35-module-cache.py) ;;
  module-inventory) command=(python3 /runtime-build/ensure-sdk35-dev-modules.py --root /runtime-build) ;;
  module-cache-restore-check) command=(python3 /runtime-build/verify-sdk35-cache-restore.py) ;;
  modules-restore) command=(python3 /runtime-build/ensure-sdk35-dev-modules.py --root /runtime-build --restore-missing) ;;
  module-image-context) command=(python3 /runtime-build/prepare-sdk35-module-image.py) ;;
  module-image-verify-builder|module-image-verify-android-dev|module-image-verify-android-tests) command=(python3 /opt/tlc/sdk35-module-support/ensure-sdk35-dev-modules.py --root /opt/tlc/sdk35-dev) ;;
  source-locked)
    shift
    if [ "$#" -eq 0 ]; then echo "At least one locked project path required" >&2; exit 64; fi
    command=(python3 /runtime-build/fetch-sdk35-source.py "$@") ;;
  contract) command=(python3 /runtime-build/inspect-sdk35-runtime.py) ;;
  source-pin) command=(python3 /runtime-build/pin-sdk35-source.py) ;;
  source-core) command=(python3 /runtime-build/fetch-sdk35-source.py) ;;
  source-libcore) command=(python3 /runtime-build/fetch-sdk35-source.py libcore) ;;
  jni-check) command=(bash /runtime-build/verify-sdk35-contract.sh) ;;
  jni-patch) command=(python3 /runtime-build/patch-sdk35-jni.py) ;;
  soong-bootstrap) command=(bash /runtime-build/build-sdk35-soong.sh) ;;
  release-config) command=(bash /runtime-build/build-sdk35-release.sh) ;;
  source-release) command=(python3 /runtime-build/fetch-sdk35-source.py build/release external/spdx-tools hardware/interfaces hardware/libhardware test/vts frameworks/libs/systemui kernel/configs external/selinux system/sepolicy frameworks/hardware/interfaces packages/modules/Virtualization packages/services/Car cts packages/modules/common packages/modules/NeuralNetworks packages/modules/Wifi system/extras system/media system/apex system/hardware/interfaces frameworks/libs/modules-utils) ;;
  source-defaults) command=(python3 /runtime-build/sync-sdk35-defaults.py) ;;
  source-graph-defaults) command=(python3 /runtime-build/sync-sdk35-defaults.py netd-llvm) ;;
  source-bpf) command=(python3 /runtime-build/sync-sdk35-defaults.py bpf) ;;
  source-security-resolver) command=(python3 /runtime-build/sync-sdk35-defaults.py security-resolver) ;;
  source-crosvm-elfutils-networkstack) command=(python3 /runtime-build/sync-sdk35-defaults.py crosvm-elfutils-networkstack) ;;
  source-wayland-protocols) command=(python3 /runtime-build/fetch-sdk35-source.py external/wayland-protocols) ;;
  source-cuttlefish-adb) command=(python3 /runtime-build/fetch-sdk35-source.py device/google/cuttlefish packages/modules/adb device/generic/goldfish) ;;
  source-goldfish-opengl) command=(python3 /runtime-build/fetch-sdk35-source.py device/generic/goldfish-opengl) ;;
  source-hostapd) command=(python3 /runtime-build/fetch-sdk35-source.py external/wpa_supplicant_8) ;;
  source-media-car) command=(python3 /runtime-build/fetch-sdk35-source.py packages/modules/Media frameworks/opt/car/services) ;;
  graph) command=(bash /runtime-build/build-sdk35-graph.sh) ;;
  source-extra) command=(python3 /runtime-build/fetch-sdk35-source.py prebuilts/module_sdk/art frameworks/minikin libnativehelper external/dng_sdk external/piex external/wuffs-mirror-release-c external/libultrahdr external/perfetto external/vulkan-headers external/eigen external/fmtlib external/boringssl external/flatbuffers external/protobuf external/abseil-cpp external/libxml2 system/server_configurable_flags) ;;
  source-api) command=(python3 /runtime-build/fetch-sdk35-source.py art prebuilts/sdk) ;;
  source-runtime) command=(python3 /runtime-build/fetch-sdk35-source.py build/make build/bazel bionic frameworks/native frameworks/av system/core system/libbase system/logging system/libziparchive system/libhidl system/libhwbinder system/libfmq system/libvintf system/tools/aidl external/icu external/skia external/libcxx external/libcxxabi external/compiler-rt external/zlib external/libpng external/libjpeg-turbo external/webp external/freetype external/harfbuzz_ng external/sqlite external/expat) ;;
  *) echo "Unknown runtime build stage: $stage" >&2; exit 64 ;;
esac
python3 ./watch-sdk35-container.py "$stage" "${command[@]}"
