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
- GitHub compare confirms the migration branch is ahead of main and has no divergence behind main; its aggregate file diff remains a single added `MIGRATION_STATUS.md`. The exact ahead count is intentionally not recorded here because each documentation correction creates another commit.
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


## Session update — 2026-11-16 (continued live inspection)

### Repository and branch verification

- Recursive Git tree query completed successfully for the current `main` tree: **72,306 entries**, not truncated.
- The repository has two branches in the current branch listing: `main` at `e87fe99406053025d97b361fe18cc8faf6e416c6` and `migration/linux-5.1-assessment` at `2f93d295da6526f1e46adbbc8ca66b26dab8384f`.
- Compare result: migration branch is **5 commits ahead, 0 behind** main. Its aggregate change remains only the added/updated `MIGRATION_STATUS.md`; no kernel source migration has occurred on that branch.
- Root inventory confirms a complete conventional kernel source layout plus SOVR/Fresh build and packaging infrastructure. Top-level device-specific inputs include `build.config.universal9610_pqr`, `Documentation/device-db/a50.sh`, `arch/arm64/configs/exynos9610-a50_core_defconfig`, and `exynos9610-a50_default_defconfig`.
- The two workflow files are `.github/workflows/development.yml` and `.github/workflows/galaxy-a50.yml`.
- GitHub Actions API returned `total_count: 0` workflow runs. Repository releases API returned an empty list. The tags endpoint was not available through the current GitHub fetch surface, so tag inventory remains unverified.
- Repository-scoped pull request and open-issue queries returned no entries.

### Newly verified build and CI defects / risks

1. **Build-script pipeline exit masking is confirmed.** `build.sh` does not establish `set -o pipefail` or `set -e`. Its compiler/configuration commands at approximately lines 268–285, cleanup commands at 701–702, toolchain clone at 71, Magisk update at 170, and ZIP creation at 491 pipe through `sed`. The workflow's `set -eo pipefail` is in the parent Actions shell and does not automatically enable pipefail inside the separately executed `./build.sh` process. A failed `make`, clone, or zip can therefore be hidden by a successful `sed` exit unless the script explicitly handles pipeline status. This is a confirmed high-priority CI correctness defect; fix on the migration branch only after reviewing the complete script and adding a focused regression test.
2. **The advertised Development workflow KSU input is not wired.** It declares `workflow_dispatch.inputs.version` with description “Build KSU”, but none of the build invocations references `inputs.version` or `github.event.inputs.version`. The build script does support `--ksu` (argument parser around lines 552–555), but the workflow's invocations use `--magisk` or no root flag. Thus the current input does not select KernelSU.
3. **Workflow triggers are narrower than the requested CI design.** `development.yml` is manual-dispatch only. `galaxy-a50.yml` runs on manual dispatch and pushes to `android-*`; neither inspected workflow declares `pull_request` or general development-branch push triggers. There is no observed workflow run evidence.
4. **Workflow permissions are broader than necessary for artifact-only CI.** Both inspected workflows declare `contents: write`; the build/artifact jobs should be reviewed for least privilege. Do not reduce permissions until checking whether any release-publishing step actually writes repository releases.
5. **Toolchain reproducibility remains unresolved.** `build.sh` defaults to compiler selector `neutron`, checks for `$HOME/toolchains/neutron-clang`, and labels it LLVM 22+. Its fallback clones the moving GitLab `neutron` branch into a repository-local `toolchain` directory, but the Neutron-specific verification branch checks the separate home-directory path. The inspected script does not pin a commit or verify a checksum. The CI workflows install host packages but do not themselves provision and verify a pinned compiler archive/revision. Resolve this before claiming reproducible CI.
6. **Package/build path needs careful preservation.** The script selects `exynos9610-a50_core_defconfig`, merges Android/variant fragments, conditionally appends KernelSU/SuSFS symbols, builds an Image, constructs boot image/DTB/DTBO-related outputs, and stages AnyKernel assets. The package path moves `Image` and `dtb_exynos.img` into a temporary staging directory and zips it. Preserve this behavior until installer, boot-header, DTB and rollback dependencies have been fully mapped.
7. **KSU source is a downstream integration, not a simple config toggle.** The inspected Kconfig exposes `KSU_MANUAL_HOOK`, `KSU_KPROBES_HOOK` and numerous SuSFS options. The script forces manual hooks and disables KPROBES hooks for its KSU path. Linux 5.1 porting must verify the exact KernelSU/SuSFS source revision and hook/API compatibility; do not transplant current Kconfig fragments blindly.

### Configuration provenance discrepancy — confirmed

- Top-level `Makefile` identifies the source as **4.14.357**.
- The build script selects `exynos9610-a50_core_defconfig`, whose generated-file header says **Linux/arm64 4.14.194**.
- `exynos9610-a50_default_defconfig` has a generated-file header saying **4.14.113**.
- The build script constructs `BUILD_DEVICE_CONFIG=exynos9610-a50_core_defconfig`; the default defconfig is not selected by this path.
- These generated header comments are provenance clues, not proof that the effective built kernel reports those releases. Investigate config ancestry and verify the resulting `.config`, `include/generated/utsrelease.h`, `kernelversion`, and built image metadata in a clean baseline build. Do not rewrite the headers or defconfigs merely to make the versions appear consistent.

### Confirmed preserved features in the selected core defconfig

The inspected core defconfig includes PSI, LRU_GEN/MGLRU, ZRAM with ZSTD default, ZRAM entropy, ZRAM writeback, LRU/SQZR writeback, Exynos thermal/ACPM, Exynos display/camera blocks, SCSC WLAN/Bluetooth, F2FS encryption and extensive Exynos 9610 platform options. This is a feature-preservation checklist, not a statement that every feature has been hardware-tested.

The selected defconfig also enables the Exynos/Samsung-specific driver families that make a generic upstream 5.1 replacement unsafe without substantial downstream porting. The alternative default defconfig differs materially (including a different generated kernel version header and Mali configuration); both configs must be diffed and traced to the intended ROM/variant before any migration.

### TZDEV source detail

The current `drivers/misc/tzdev/tz_deploy_tzar.c` embeds `startup.tzar` and `startup_old.tzar` into `.rodata` using assembler `.incbin`, then asynchronously deploys the primary container and falls back to the older container after failure. The comments associate the fallback with non-NFC A505F models. This is important device-specific code and must be preserved and validated against the actual A505F secure OS; source comments and fallback logic do not by themselves prove deployment succeeds on the user's handset.

### Current engineering decision

- Do **not** start source replacement yet.
- First reproduce the 4.14.357 baseline from the actual `build.sh` path, inspect generated config and kernel release metadata, and capture the exact toolchain and package outputs.
- Then complete the selected-config/fragment diff, installer/DTB boot-chain inventory, and full Samsung driver ownership map.
- The first safe implementation candidate is a focused CI correctness fix for pipeline failure propagation plus a real KSU workflow input, but only after regression-safe review. Keep changes isolated on `migration/linux-5.1-assessment`; do not touch `main`.
- No files outside this status document were modified in this session. No build, static analysis, boot test, or physical-device test was performed.

## Session update — 2026-11-16 (continuation verification)

### Live Git state re-check

- `main` remains at `e87fe99406053025d97b361fe18cc8faf6e416c6`.
- At the start of this continuation verification, `migration/linux-5.1-assessment` pointed to `2f93d295da6526f1e46adbbc8ca66b26dab8384f` (`docs(migration): record live source and CI audit findings`). The first status refresh was committed as `d6d233f77b96759ce3bdcb660d36edf1a5eb731b`; this line records the pre-refresh snapshot, not the current branch head.
- At that pre-refresh snapshot, GitHub compare reported the migration branch **5 commits ahead, 0 behind** main. Its diff against main contained only `MIGRATION_STATUS.md`; no kernel source, build script, workflow, defconfig, installer or package file had been changed on the migration branch.
- The branch listing currently returns exactly `main` and `migration/linux-5.1-assessment`.
- Repository-scoped PR listing and open-issue search return no entries.
- GitHub Actions run API returns `total_count: 0`. The releases endpoint for this repository returns an empty list. Tag enumeration is still unavailable through the current API surface (the Git refs/tags endpoint returned 404), so do not infer that no tags exist.
- Main's recursive Git tree was independently fetched with `truncated=false`: **72,306 entries**. Root inventory includes the complete kernel tree, `.elts`, `.github`, SOVR/Fresh build scripts, `build.config.universal9610_pqr`, and the A50 device database.
- The README advertises SOVR v4.2 and links release assets under the separate `SOVR-Technologies/SOVR-Kernel-A50` repository. The current `crypto143007-ship-it/SOVR-Kernel-A50` releases API is empty; therefore ZIP payloads and release provenance are not yet verified from this repository.

### Build-script and workflow re-check

- The live `build.sh` is 812 lines and still has no script-level `set -e` or `set -o pipefail`.
- Nineteen critical logging pipelines were identified: toolchain clone (1), Magisk update (1), config/build make invocations (14), ZIP creation (1), and clean/mrproper (2). These remain potential false-success paths because the build script runs as a separate process from the workflow shell. This confirms the issue but does not yet constitute a fix.
- `.github/workflows/development.yml` has only `workflow_dispatch`; its `version` input is described as “Build KSU”, but no invocation consumes the input and all build calls select Magisk or no KSU flag.
- `.github/workflows/galaxy-a50.yml` has manual dispatch and a restricted push trigger; neither workflow currently provides a pull-request trigger for migration-branch validation.
- Both workflows contain release-writing operations, so `contents: write` cannot be reduced safely without first separating artifact-only validation from release publication.
- No workflow was dispatched, no source was modified, and no build or device test was performed in this continuation. These findings remain audit evidence only.

### Next action

Finish the source/configuration and packaging preservation inventory, especially the two competing A50 defconfigs, all merged fragments, Mali DDK selection, DTB/DTBO generation, boot-image construction and AnyKernel3 install/rollback logic. Then reproduce the existing 4.14.357 build with its actual toolchain and record the generated `.config`, `UTS_RELEASE`, image metadata and package contents. Only after this baseline is reproducible should the focused pipeline-failure fix and KSU workflow-input correction be implemented and tested on this migration branch.

## Session update — 2026-11-16 (live repository and build-path verification)

### Current live refs and repository identity

- Default branch `main`: `e87fe99406053025d97b361fe18cc8faf6e416c6`.
- Assessment branch `migration/linux-5.1-assessment`: `3df53c48ff6188369c94c78916a2009a484a01c5`.
- GitHub compare: **7 commits ahead, 0 behind** main; aggregate diff still consists only of `MIGRATION_STATUS.md`. No kernel source, defconfig, build script, workflow, installer, or package content has been changed on the assessment branch.
- The repository is a public fork of `SOVR-Technologies/SOVR-Kernel-A50`; preserve the user's fork and its independent history. Parent repository metadata reports a later update on 2026-11-16, so upstream/fork divergence should be reviewed before any future sync. Do not merge or rebase automatically.
- Recursive `main` tree fetch completed with `truncated=false`: **72,306 entries / 67,449 files**. Root includes conventional kernel directories, `.elts`, `.github`, `build.sh`, `build_all_v35.sh`, `build_all_v36.sh`, and `build.config.universal9610_pqr`.
- Live branch listing contains only `main` and `migration/linux-5.1-assessment`.
- Actions API: `total_count=0`; release list: empty. The GitHub fetch surface rejects the tags endpoint, so tag inventory remains **unverified**, not empty.
- PR list returned empty. The repository metadata says Issues are disabled (`has_issues=false)); issue endpoint returning no results must not be interpreted as a complete issue-history audit.
- `MIGRATION_PLAN.md` does not exist on the assessment branch yet. Do not assume it exists or overwrite/create it before the assessment is ready.

### Workflow and build-path details confirmed

- `.github/workflows/development.yml` and `.github/workflows/galaxy-a50.yml` are both present on main and unchanged on the assessment branch.
- Development workflow is manual-dispatch only. Its `version` input says “Build KSU” but is not referenced by the build invocations; those invocations choose Magisk or no root option.
- Galaxy A50 workflow triggers on manual dispatch and pushes to `android-*`; it has eight ROM/root build jobs plus a release aggregation job. It does not currently trigger on pull requests or general development-branch pushes.
- Both workflows perform release publication, explaining why `contents: write` cannot be removed from those release jobs without separating artifact-only CI from release publication.
- `build.sh` uses `exynos9610-a50_core_defconfig` for the A50 build path, then merges partial de-Knox, Mali, variant, and SELinux fragments. The KSU path appends KernelSU/SuSFS config symbols; this is configuration injection, not proof that the KSU source hooks are compatible with Linux 5.1.
- The build script has 14 make/configuration pipelines ending in `sed`, plus toolchain clone, Magisk update, ZIP creation, clean and mrproper pipelines. It has no script-level `set -e` or `pipefail`. Parent workflow shell options do not propagate into the separately executed `./build.sh` process.
- Packaging stages variant-specific installer assets in a temporary directory, then moves `arch/arm64/boot/Image` and `arch/arm64/boot/dtb_exynos.img` into the staged package before ZIP creation. DTB/DTBO helper functions and exact call order still require full trace; do not change the package format based on partial inspection.
- `build_dtb()` and `build_dtbo()` invoke the repository's `tools/dtb/mkdtboimg` helper with A50-specific config files. The actual output dependency chain must be verified against the device database and installer before any packaging edits.

### Current decision and next work

- This session remained read-only until this status-document update; no kernel source, workflow, config, installer, or packaging file was changed.
- Do not add a blanket `set -u` to `build.sh`: the script references optional variables that may be unset. Any pipeline correction must account for expected nonzero commands and preserve interactive behavior. Prefer explicit failure checks or narrowly scoped `set -o pipefail` plus controlled error handling after a clean baseline is reproduced.
- Next: trace the full build function call order, device database, variant fragment merge implementation, DTB/DTBO configuration, AnyKernel installer and rollback behavior; compare the two A50 defconfigs and all merged fragments; then reproduce the 4.14.357 build with the actual pinned toolchain provenance. No Linux 5.1 source replacement is authorized by the current evidence.


## Session update — 2026-11-16 (build/configuration and installer preservation audit)

### Live branch snapshot

- Default branch `main`: `e87fe99406053025d97b361fe18cc8faf6e416c6`.
- Assessment branch observed at the start of this audit: `172d8b726b467234432a30f50b0aca60f753a2ae`.
- The assessment branch still contains the conventional Linux 4.14 tree and the two existing workflows; no Linux 5.1 source has been introduced.
- The current branch root contains `MIGRATION_STATUS.md`, `build.sh`, `build.config.universal9610_pqr`, the A50 device database, two A50 defconfigs and the existing kernel/configuration/package directories.
- GitHub Actions remains at zero observed workflow runs. Do not treat absence of runs as evidence that the workflow definitions are valid.

### Build entry point and effective A50 configuration

- `build.sh` explicitly selects `exynos9610-a50_core_defconfig` for device `a50`; it does not select `exynos9610-a50_default_defconfig` in the normal A50 build path.
- The selected core config is 5,798 lines and has generated header `Linux/arm64 4.14.194`; the alternative default config is 5,799 lines and has generated header `Linux/arm64 4.14.113`. The top-level Makefile remains the source of the 4.14.357 kernel version. These are config provenance discrepancies requiring investigation, not proof that the compiled release is 4.14.194 or 4.14.113.
- A programmatic symbol comparison found **510 differing config symbols** between core and default. This is not a harmless header-only difference. Important differences include:
  - Core enables PSI, ZRAM with ZSTD default, ZRAM entropy, ZRAM writeback, LRU/SQZR writeback and LRU_GEN/MGLRU; the default config does not show those same settings.
  - Core enables the Energy Adaptive CPU governor by default and has schedutil available; default selects schedutil as default.
  - Core disables Android LMK; default enables `CONFIG_ANDROID_LOW_MEMORY_KILLER`.
  - Core enables ARM64 crypto; default disables it.
  - Core enables Exynos thermal devfreq and selected SCSC NAPI/low-latency options; default differs.
  - Default enables Exynos FMP/FIPS-related options, ITMON/CORESIGHT, and an alternate Mali DDK config family; core differs.
  - Both retain important Exynos platform, Android Binder, F2FS, EROFS, and KernelSU/SuSFS configuration entries, but their detailed feature selection is not equivalent.
- The build script then appends the following fragments in order: Android-version-specific partial de-Knox, Android-version-specific Mali, ROM variant, KernelSU/SuSFS or non-root, SELinux mode, and Magisk/non-root. The effective final configuration therefore cannot be inferred from either base defconfig alone. Preserve the exact merge order and capture the generated `.config` in a clean build before deciding migration settings.
- The A50 device database file `Documentation/device-db/a50.sh` supplies board `SRPRL05B007KU`, base `0x10000000`, page size 2048, kernel offset `0x00008000`, ramdisk/second offsets `0xf0000000`, tags offset `0x00000100`, boot header version 1, SHA-1 DTB hash type, platform version 12.0.0 and patch level 2022-09. These are current script inputs, not independently verified device boot-image metadata; validate against the actual stock/known-good boot image before altering.
- The selected core config includes `CONFIG_PSI=y`, `CONFIG_LRU_GEN=y`, `CONFIG_LRU_GEN_ENABLED=y`, `CONFIG_ZRAM=y`, `CONFIG_ZRAM_DEF_COMP_ZSTD=y`, `CONFIG_ZRAM_WRITEBACK=y`, `CONFIG_ZRAM_LRU_WRITEBACK=y`, `CONFIG_F2FS_FS=y`, `CONFIG_EROFS_FS=y`, SCSC WLAN/BT and Exynos thermal/display/camera/platform features. The core config has `CONFIG_UFS_FS` unset; the actual Samsung UFS host integration must be traced in the Exynos-specific driver/config symbols rather than assuming generic UFS_FS represents the complete device path.
- `build.config.universal9610_pqr` is a separate build-config entry point selecting `universal9610_pqr_defconfig`, Android clang prebuilt path `clang-r365631c`, and image/DTB/DTBO/vmlinux outputs. It is not the A50 `build.sh` defconfig path and must not be conflated with it.

### Build script control-flow and failure handling

- The script performs toolchain verification, optional clean/mrproper, writes a temporary config, sources device metadata, merges the fragments, selects an Android-version/ROM-specific DTS source, runs the config/build function, then builds boot.img and the ZIP.
- The build function has multiple `make ... 2>&1 | sed ...` pipelines, and the script itself has no global `set -e` / `set -o pipefail`. This remains a confirmed build-integrity defect. Do not apply a blind `set -u`: optional variables are used in the script. Correct this in a focused change with controlled failure propagation and tests after the baseline build is reproducible.
- The build script declares `build_dtb()` and `build_dtbo()` helper functions that invoke `tools/dtb/mkdtboimg cfg_create` against A50-specific config paths. The final visible execution sequence invokes `build_kernel`, then `build_image`, then `build_package`; it does not call those helper functions directly. The generated `arch/arm64/boot/dtb_exynos.img` is instead moved into the package as `dtb.img`. Trace Kbuild/DTB generation and helper usage before modifying this packaging flow.
- `build_image()` creates `tools/make/boot.img` from the kernel Image and device-database boot parameters. It checks only for the resulting file after mkbootimg; the package path itself stages the raw Image and DTB, not this boot.img.
- Toolchain selection defaults to the `neutron` selector and expects `$HOME/toolchains/neutron-clang` (described by the script as LLVM 22+) plus a cloned companion repository at `toolchain`. The fallback clone follows the moving GitLab branch `neutron` and has no pinned commit/checksum. A deterministic baseline cannot be claimed until the actual compiler binary/version and both toolchain source revisions are recorded.
- The command-line parser supports `--ksu`, but the inspected Development workflow's `version` input still is not wired to that flag. The A50 workflow currently builds Magisk and non-root variants, not the requested KernelSU matrix.

### Installer and boot-chain preservation

- The current AnyKernel installer is `tools/make/package/mint.sh`. Its properties include `do.devicecheck=1`, `do.modules=0`, `do.systemless=0`, `do.cleanup=1`, and `do.cleanuponabort=0`. It targets the DTB partition path `/dev/block/platform/13520000.ufs/by-name/dtb`, declares a non-A/B device, calls `split_boot` and `flash_boot`, then flashes the DTB using `flash_generic dtb`.
- The installer performs ROM/Android-version detection and installs distinct One UI/Fresh/AOSP assets. Android 14+ One UI/Fresh path explicitly expects EROFS system and uses the pure SOVR defaults; older One UI 3 path modifies Pageboost/RAM Plus and swap fstab/init integration; AOSP path installs ZRAM writeback overlay/init assets and adjusts vendor properties/fstab.
- The package build stages common AnyKernel metadata and tools, then selects `files_aosp`, `files_oneui`, or `files_fresh` and version-specific init patches. It moves `arch/arm64/boot/Image` and `arch/arm64/boot/dtb_exynos.img` into the staging directory as `Image` and `dtb.img`, writes `mint.prop`, and zips the staged contents.
- The installer and packaging are tightly coupled to current Android init/fstab behavior, vendor mount points, UFS DTB partition naming, A-only boot layout, and EROFS/F2FS assumptions. Do not replace the installer or change the image/DTB format during kernel source migration without a complete boot-chain comparison and rollback test.

### Preservation decisions and newly prioritized work

1. Keep both A50 defconfigs and all current config fragments unchanged until their origin and intended target variants are documented. The 510-symbol delta requires a proper semantic config comparison, not a simple choose-one decision.
2. Resolve the 4.14.357 Makefile versus generated defconfig header discrepancy through a clean build and generated metadata, not by editing the header comments.
3. Trace exact DTS/Kbuild targets and determine where `dtb_exynos.img` is generated; reconcile that with the unused helper functions and the installer's direct DTB flashing.
4. Audit `tools/make/package/tools/ak3-core.sh`, all variant asset trees, boot image split/flash behavior, device assertions and abort rollback before touching packaging.
5. Establish compiler/toolchain provenance and run a clean baseline build with the actual A50 command path.
6. Only after baseline reproduction, implement a narrowly scoped build-failure propagation fix and a CI-only validation workflow separate from release publication. Keep `main` untouched.

### Validation status

- Source/build-script/configuration/installer inspection: **performed (static repository inspection only)**.
- Effective generated `.config`: **not captured**.
- Linux 4.14.357 baseline compilation: **not performed**.
- Linux 5.1 compilation: **not started**.
- ZIP/boot image validation: **not performed**.
- Physical device boot and daily-driver testing: **not performed**.
- No repository source, workflow, config, installer or package file was modified in this session; this update is documentation only.
