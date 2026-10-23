#!/usr/bin/env bash
set -euo pipefail
cd /runtime-build/aosp
python3 /runtime-build/ensure-sdk35-native-compiler.py
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
export OUT_DIR=out-sdk35
readelf -h prebuilts/build-tools/linux_musl-arm64/bin/ninja | grep 'Machine:.*AArch64'
exec prebuilts/build-tools/linux_musl-arm64/bin/ninja -f out-sdk35/combined-sdk35.ninja -j 8 out-sdk35/soong/.intermediates/frameworks/base/core/jni/libandroid_runtime/linux_glibc_arm64_shared/libandroid_runtime.so
