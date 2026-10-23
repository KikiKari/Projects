#!/usr/bin/env bash
set -euo pipefail
cd /runtime-build/aosp/build/soong
export GOWORK=/runtime-build/aosp/build/soong/go.work GOCACHE=/runtime-build/cache/go GOTOOLCHAIN=local GOPROXY=off GOMAXPROCS=8
go build -p 8 -o ../../out-sdk35/host/linux-arm64/bin/sdk35-source-finder /runtime-build/sdk35-original-source-finder.go
readelf -h ../../out-sdk35/host/linux-arm64/bin/sdk35-source-finder | grep 'Machine:.*AArch64'
