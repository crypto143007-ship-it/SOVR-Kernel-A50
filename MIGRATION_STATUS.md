# SOVR Linux 5.1 Migration — Status

Last verified: 2026-11-16
Project: Samsung Galaxy A50 SM-A505F / Exynos 9610
Target: Linux 5.1 (explicitly retained; no version substitution)

## Current phase

**Phase 0 — Repository discovery: IN PROGRESS**

No kernel source, defconfig, build script, installer, branch, tag, or release has been modified by this migration session. This status file is the only migration-session change.

## Verified repository baseline

- Repository: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50
- Default branch at discovery: `main`
- Baseline commit: `e87fe99406053025d97b361fe18cc8faf6e416c6`
- Latest commit message: `docs(readme): update documentation and package matrix for SOVR Kernel v4.2`
- Repository metadata reports public visibility and read/write permissions for the connected GitHub identity.
- Branch discovery returned `main`; a second page returned no further branches.
- Pull-request search returned no PRs; issue search returned no issues.
- Commit combined-status query returned no status entries.
- Commit workflow-run lookup returned no PR-triggered workflow runs. This endpoint is not a complete repository-wide workflow inventory.
- Root migration documents `MIGRATION_STATUS.md` and `MIGRATION_PLAN.md` did not exist when checked.

## Confirmed source observations

1. Top-level `Makefile` declares Linux `4.14.357`.
2. README documents SOVR v4.2 Final and describes OpenELA 4.14.357 plus ELTS backports, Clang 23.1.5, KernelSU-Next 3.4.2, SuSFS 1.5.5, MGLRU, ZSTD ZRAM, EROFS, F2FS, Samsung SCSC, and Exynos UFS customizations. These README statements remain claims until independently verified.
3. `build.sh` selects `exynos9610-a50_core_defconfig`.
4. That defconfig's generated header says Linux/arm64 4.14.194. This is a provenance/version-header discrepancy requiring investigation; it does not override the top-level Makefile version.
5. The defconfig enables PSI, LRU_GEN and LRU_GEN_ENABLED, ZRAM with ZSTD, ZRAM entropy, ZRAM writeback, ZRAM_LRU_WRITEBACK, SCSC WLAN/BT, TZDEV/TZAR deployment, and Exynos UFS components.
6. The ZRAM driver contains custom backing-device, writeback-limit, idle/huge/page writeback, LRU/SQZR, mm_stat, bd_stat, and debug_stat paths.
7. `drivers/misc/tzdev/tz_deploy_tzar.c` embeds primary and fallback TZAR blobs in `.rodata`, deploys asynchronously using `tzdev_deploy_tzar`, retries secure-loader connections, and falls back from `startup.tzar` to `startup_old.tzar`. Secure-world rejection is translated to `-EINVAL`.
8. `build.sh` contains build, clean, toolchain-download and ZIP pipelines piped through `sed`, without establishing `set -o pipefail` in its opening section. These pipelines can mask the left-hand command's exit status.
9. `build.sh` defaults to a toolchain selector named `neutron` and looks for `$HOME/toolchains/neutron-clang` described by the script as LLVM 22+, while the current README advertises Clang 23.1.5. The exact toolchain actually used by the latest release build is not yet independently established.
10. `build.sh` downloads a fallback toolchain from a moving GitLab branch and does not show a pinned commit or integrity checksum in the inspected function.

## Preliminary risk observations

- Linux 5.1 is an end-of-life upstream series. It must not be represented as a security-maintained target without a separately documented downstream patch-maintenance strategy.
- Android's published Android Common Kernel compatibility matrix does not list Linux 5.1 as a supported/tested kernel for Android 12–16. This is a compatibility warning, not proof that a legacy non-GKI Samsung vendor kernel cannot boot a custom ROM.
- The existing 4.14 tree contains substantial downstream functionality that must be carried deliberately; a clean upstream 5.1 tree will not preserve it automatically.
- MGLRU is a backport in this 4.14 tree, not a native 4.14 feature. It requires explicit forward-port analysis.
- Samsung SCSC, TZDEV, Exynos UFS, Mali, display, camera, multimedia, power and thermal integration remain unverified for Linux 5.1.

## Build and hardware validation

- Linux 5.1 build: NOT STARTED.
- Existing baseline build reproduced in CI: NOT VERIFIED.
- Linux 5.1 static validation: NOT STARTED.
- Physical Galaxy A50 boot test: NOT PERFORMED.
- Daily-driver test: NOT PERFORMED.
- No kernel has been flashed by this project session.

## Outstanding Phase 0 / Phase 1 work

1. Obtain a complete root/tree inventory and enumerate all branches, tags, release assets, workflows, and build artifacts.
2. Identify the actual CI workflow files and inspect their triggers, permissions, inputs, toolchain provisioning, logs, and artifact history.
3. Inspect all defconfigs and configuration fragments; establish which file is the canonical A50 baseline for each Android variant.
4. Trace build.sh, device database, DTB generation, boot-image construction, AnyKernel3 staging, and install/rollback behavior end to end.
5. Inventory KernelSU-Next and SuSFS source revisions and dependencies.
6. Audit MGLRU, PSI, OPLUS_MM_HACKS, ZRAM/SQZR writeback, EROFS, F2FS, UFS, Mali, SCSC, TZDEV, CPU/thermal, display/camera/audio and other Samsung drivers.
7. Reconcile README claims with source, release ZIP contents, and actual test evidence.
8. Establish a clean, reproducible Linux 4.14.357 baseline build before migration work.

## Next continuation point

Complete repository/tree and workflow discovery, then finish the 4.14 functionality-preservation inventory. Do not replace or rebase the kernel source until the Linux 5.1 feasibility assessment identifies a defensible source and driver-porting strategy.
