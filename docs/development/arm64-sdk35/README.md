# Native ARM64 Android SDK35 development

This branch contains the native ARM64 build support and the unmodified operational source/provider catalog. The complete internal technical reference, source inventories, retained host/container topology, original Blueprint snapshots, complete generated graph and evidence are maintained privately under **Development Ops → Android SDK35 – nativer ARM64-Entwicklungspfad** in Notion. They are intentionally separate from this public repository.

## Build contracts

- Original sources are selected by the existing coherent source lock; the full lock is retained in the private reference and ARM64 workspace.
- The single catalog `cluster-integration/sdk35-dev-module-sources.json` contains 588 projects, 748 provider definitions and 17 native artifact registrations. Catalog raw SHA-256: `19d90f00928ab31a815884373e83bff297b789bf35ca88e0c410eae9d4e3646f`.
- `ensure-sdk35-dev-modules.py` validates actual sources, revisions, definitions and tool inventories. A catalog entry alone is insufficient.
- Native tool inventories and source overlays must be supplied from the retained private workspace/cache; this public source-support directory is not a complete binary SDK.
- `build-sdk35-graph.sh` uses the original Soong source finder and strict dependencies. `build-sdk35-host-runtime.sh` uses the combined Ninja graph and actual AArch64 tools.
- The global native compiler and the native Bindgen Libclang backend are separate versioned artifacts. Bindgen's `CLANG_DEFAULT_CXX_STDLIB=libc++` is a documented native configuration adaptation, not a consumer-source workaround.
- Source checkout, cache seed, actual offline restore, image context and all three fresh development profiles remain separate validation gates. Aliases change only after successful validation.

## Retained development environment

Existing ARM64 containers, bind-mounted source/build/manufacturing directories, source-cache volumes, images, tags and proof records must be retained. Successful compilation is not permission to delete or prune them. Future working profile: 6 CPUs, 12 GiB RAM plus 8 GiB swap (Docker total 20 GiB). Maximum: 8 CPUs, 16 GiB RAM plus 8 GiB swap (Docker total 24 GiB). Existing ARM64 runtime containers and their historical limits remain unchanged. Stop below 42,949,672,960 free disk bytes.

The actual `libandroid_runtime.so` host-runtime compile/link succeeded as AArch64 DYN, 11,767,800 bytes, SHA-256 `e84f7159a146ef6ccae239d2340bb0ad976a728b5a49b53bd9d68e292fd484b5`. This does not establish JNI behavior, Robolectric regression, an Android APK release or device acceptance.

## Local entry point

`cluster-integration/Start-ARM64-Controller.ps1` adds **tlc-cde-cde-2-arm64-build** under the existing **tlc-cde** Compose project. The existing **tlc-cde-cde-1** and its AMD64 worktree stay in place. The additional container is a lightweight AMD64 controller; compilation executes natively on **tlc-arm64** over the existing authenticated SSH connection.

Connection values are derived at runtime from `ssh -G tlc-arm64`. The existing local CDE image is resolved by ID, not pulled or replaced. Only the needed existing key and known_hosts are mounted read-only at runtime; the key is copied into ephemeral tmpfs with mode 0600. Strict host-key verification stays enabled. No credentials are included in these files or images.

The controller supports `status`, `inventory` and `graph` through `sh /opt/tlc/arm64-support/tlc-arm64-controller.sh <mode>`. The existing remote stage runner remains authoritative. A successful controller connection does not claim a new compile run.

## Further work

Changes to source providers, host ports, compiler recipes or build configuration require new exact-byte inventories and appropriate restore/profile/graph checks. Actual variant selections must come from suitable generated artifacts. No substitute modules, architecture spoofing, missing-dependency bypasses, SDK downgrades or skipped tests.

Public source support and private operational data are complementary. Recovering from host loss requires the private reference and persistent source/tool binary stores or rebuilding from their pinned recipes; this repository alone is not a verified disaster-recovery backup.

## Shared resource policy

The validated policy is `cluster-integration/resource-profiles.json`; `resource_profiles.py` maps it to Docker options. `Set-TLCResourceProfile.ps1` applies a selected profile only to the named local/primary AMD64 project containers. It does not alter ARM64 or other workloads. Host/VM capacity and actual host swap must be verified separately. A per-container swap ceiling does not create or reserve host swap.

`run-codex-profile.py` starts new Linux Codex processes in a bounded user-systemd scope. Existing sessions and the native Windows Codex frontend are not reconfigured or restarted. Resource policy is independent of compiler and JNI acceptance.
