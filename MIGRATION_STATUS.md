# SOVR Linux 5.1 Migration — Status

Last verified: 2026-11-16
Project: Samsung Galaxy A50 SM-A505F / Exynos 9610
Requested target: Linux 5.1 (must not be silently substituted)

## Current phase

**Phase 0 — Repository discovery: IN PROGRESS**

This session performed read-only inspection. No kernel source, defconfig, build script, installer, workflow, branch, tag, or release was modified. The migration branch already contains this status document; its contents have been reconciled against the live repository where evidence was available.

## Live repository state

- Repository: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50
- Default branch: `main`
- Main HEAD observed through commit search: `e87fe99406053025d97b361fe18cc8faf6e416c6`
- Main HEAD message: `docs(readme): update documentation and package matrix for SOVR Kernel v4.2`
- Latest observed commit time: 2026-11-15 02:29:12 UTC
- Repository is public and available through the connected GitHub integration.
- Branches discovered: `main`, `migration/linux-5.1-assessment`.
- GitHub compare initially confirmed the migration branch was 1 commit ahead of main. After this session's documentation update, it is **2 commits ahead, 0 behind** main; the aggregate file diff remains a single added `MIGRATION_STATUS.md`.
- No pull requests or issues were returned by the repository-scoped searches.
- The repository integration exposes commit/file/PR/issue and selected workflow-run operations, but does not expose a repository-wide workflow-list or directory-tree operation. Consequently, complete branch/tag/workflow/release inventory remains pending.
- A commit-workflow-run lookup is PR-triggered-only and is not sufficient to conclude that no Actions runs exist.

## Verified source observations on main

1. Top-level `Makefile` declares:
   - `VERSION = 4`
   - `PATCHLEVEL = 14`
   - `SUBLEVEL = 357`
2. `arch/arm64/configs/exynos9610-a50_core_defconfig` exists. Its generated header identifies **Linux/arm64 4.14.194**, which conflicts with the top-level 4.14.357 Makefile version. This is a provenance/version-header discrepancy requiring investigation; the header alone does not prove the effective built kernel version.
3. The README describes SOVR v4.2 Final, OpenELA 4.14.357 plus ELTS backports, Clang 23.1.5, KernelSU-Next 3.4.2, SuSFS 1.5.5, MGLRU, ZSTD ZRAM, EROFS, F2FS, Samsung SCSC, and Exynos UFS customizations. README statements are project claims until independently checked against all source, configs, release packages and hardware evidence.
4. The README advertises eight build packages across Android 11, 12 and 14 variants. The One UI 6+ Android 14 package is described as hardware validated; older One UI and AOSP packages are described as community beta. These claims are not independently verified in this audit.
5. The inspected opening section of `build.sh`:
   - Selects `ARCH=arm64` and the Fresh/Mint-derived build framework.
   - Defaults to a compiler selector named `neutron`.
   - Looks for `$HOME/toolchains/neutron-clang` and describes it as LLVM 22+.
   - Falls back to cloning `TenSeventy7/exynos9610_toolchains_fresh` from the moving `neutron` branch.
   - Does not show a pinned toolchain commit or integrity checksum in the inspected download function.
   - Contains pipelines such as `git clone ... | sed` and Magisk update piped through `sed`; the inspected opening section does not establish `pipefail`. The complete script still needs a line-by-line audit before determining every affected command.
6. The inspected ZRAM Kconfig defines LZO, LZO-RLE, ZSTD and LZ4 default compressor choices, ZRAM writeback, and custom LRU writeback/SQZR options.
7. The inspected `drivers/block/zram/zram_drv.c` includes custom dependencies and structures for backing-device support. The full implementation and its locking, accounting, and reclaim interactions remain to be audited.
8. The inspected A50 defconfig enables PSI, LRU_GEN/MGLRU-related options, ZRAM with ZSTD and writeback-related options, ARM64 crypto, Samsung platform options, and EROFS features. A full config inventory is still pending.
9. `drivers/misc/tzdev/tz_deploy_tzar.c` embeds both `startup.tzar` and `startup_old.tzar` in `.rodata`, deploys asynchronously using `tzdev_deploy_tzar`, retries secure-loader connections, and attempts the older container after primary failure. Secure OS rejection is mapped to `-EINVAL`. This is a source-level observation, not proof of a universal A505F boot fix.
10. The source tree and README document substantial Samsung downstream functionality. A generic upstream Linux 5.1 tree will not preserve these features automatically.

## Branch and status-document reconciliation

The prior text in this document incorrectly stated that only `main` had been discovered and that migration documents did not exist. Live branch discovery and comparison now confirm `migration/linux-5.1-assessment` exists and contains this document as its sole change over main. This corrected entry supersedes those earlier statements.

## Preliminary Linux 5.1 feasibility position

- Linux 5.1 is the explicit requested target; no alternative version has been selected.
- Linux 5.1 is an old, end-of-life upstream series and cannot be treated as security-maintained without a separately resourced downstream patch policy.
- Google's current Android Common Kernel compatibility matrix lists supported/tested Android branches such as 5.10, 5.15 and 6.1 for the relevant Android platform releases, but does not list 5.1. This is a GKI/ACK compatibility warning, not proof that a legacy non-GKI Samsung vendor kernel cannot boot.
- The practical path, if feasible, is a controlled forward-port of Samsung downstream device support onto the requested 5.1 base, with explicit porting and validation of each subsystem.
- No source-level feasibility conclusion can yet be made for Mali, display, camera, multimedia, SCSC, UFS, TZDEV, charging, thermal, suspend/resume, KernelSU or SuSFS. Their APIs and vendor dependencies must be mapped before source migration.
- Do not begin wholesale replacement or remove any current driver before the compatibility matrix and source ancestry are established.

## Build and hardware validation

- Linux 4.14.357 baseline build reproduced: NOT VERIFIED.
- Linux 5.1 build: NOT STARTED.
- Full CI workflow inventory: NOT AVAILABLE THROUGH THE CURRENT REPOSITORY TOOL SURFACE; continue through an available GitHub Actions UI/API path if exposed later.
- Linux 5.1 static validation: NOT STARTED.
- Physical Galaxy A50 boot test: NOT PERFORMED.
- Daily-driver validation: NOT PERFORMED.
- No kernel has been flashed by this project session.

## Outstanding Phase 0 / Phase 1 work

1. Obtain complete root/tree inventory and enumerate all branches, tags, release assets, workflows, and build artifacts.
2. Inspect all build scripts end-to-end, including selected defconfigs, fragments, device database, DTB generation, boot image handling, AnyKernel3 staging, install and rollback.
3. Identify actual GitHub Actions workflow files and inspect triggers, permissions, inputs, toolchain provisioning, logs, and artifacts.
4. Inventory all defconfigs and fragments and identify canonical configs for each ROM/Android target.
5. Reconcile the 4.14.357 Makefile versus 4.14.194 defconfig generated-header discrepancy.
6. Trace KernelSU-Next and SuSFS source revisions, patch dependencies, hooks and API assumptions.
7. Audit MGLRU, PSI, OPLUS_MM_HACKS, ZRAM/SQZR writeback, EROFS, F2FS, UFS, Mali, SCSC, TZDEV, CPU/thermal, display/camera/audio and other Samsung drivers.
8. Reconcile README claims with source, release ZIP contents, CI evidence and actual hardware test evidence.
9. Establish a clean, reproducible Linux 4.14.357 baseline build before migration work.

## Next continuation point

Complete repository/tree and workflow discovery, then finish the 4.14 functionality-preservation inventory. Resolve the defconfig provenance discrepancy and reproduce the existing baseline build. Only then finalize the Linux 5.1 migration architecture. Do not replace or rebase kernel source until the compatibility assessment establishes a defensible source and driver-porting strategy.
