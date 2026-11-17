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


## Continuation re-check — 2026-11-16 16:20 UTC

### Current ref verification
- Pre-update ref snapshot: `main` was `e87fe99406053025d97b361fe18cc8faf6e416c6`; `migration/linux-5.1-assessment` was `2a435274b9678d8003c31a274129c863d975ae0c`.
- The migration branch still contains documentation-only changes relative to main. No Linux 5.1 source tree, compatibility shim, driver port, config migration, or build workflow has been introduced.
- The current repository contains two Actions workflows, `.github/workflows/development.yml` and `.github/workflows/galaxy-a50.yml`; the current Actions runs endpoint reports zero runs. This is not build evidence.

### Toolchain gate — exact control-flow confirmation
- In `build.sh`, the default compiler selector is `neutron`. The `verify_toolchain()` neutron branch requires `$HOME/toolchains/neutron-clang`; if it is absent, the script calls `exit_script` immediately.
- The current workflows install host packages but do not create or populate that required path. The script's repository-local toolchain fallback is reached only in other selector branches, not when the default `neutron` selector is active.
- Therefore, on a clean GitHub-hosted runner with no pre-existing home-directory toolchain, the existing workflows are not self-sufficient for the default build path. Treat toolchain provisioning as a hard CI blocker, not a warning.
- The Development workflow's optional `version` input remains unused by its build commands. The build script supports `--ksu`, but the workflow does not pass it; the inspected jobs build Magisk or non-root variants instead.

### Session boundary
- This was a read-only continuation audit followed by this status-document update only.
- No kernel source, defconfig, DTS/DTBO, installer, build script, workflow, or release configuration was modified.
- No compiler was run, no baseline build was attempted, no artifact was produced, and no device operation was performed.
- Next safe action remains: provision and pin a known-compatible baseline toolchain, then run the exact A50 One UI 14 / SOVR build path on an isolated CI branch and capture the generated `.config`, `UTS_RELEASE`, Image, DTB, boot image and ZIP contents. Only after this baseline is reproducible should the build-script error-propagation defect be changed.

- The status refresh and subsequent ref-snapshot wording correction were separate documentation-only commits (`e51b73a79b638352feef2fbeb87c49519724c8a8` and `4f54666c10035f31d6761695332ce7a6b763617e`). Check the live branch head at the start of the next session rather than treating either intermediate SHA as the current HEAD. The aggregate diff against `main` remains limited to `MIGRATION_STATUS.md`.


## Continuation update — 2026-11-16 21:28 PKT

### Live state re-check
- Confirmed repository is accessible and writable through the connected GitHub integration; default branch is `main`.
- `main` remains at `e87fe99406053025d97b361fe18cc8faf6e416c6`.
- Branch discovery currently returns exactly `main` and `migration/linux-5.1-assessment`.
- Live compare reports the migration branch is **12 commits ahead and 0 behind** main. The complete compare file list still contains only `MIGRATION_STATUS.md` (one added file); no source, configuration, build, workflow, installer, or package modifications are present on the migration branch.
- The current branch ref was used to fetch `MIGRATION_STATUS.md` successfully. The available branch-search operation returns branch names but not branch-tip SHAs; therefore this session does not claim an exact current migration-branch HEAD SHA. The next session should resolve the ref SHA through a Git refs/branch API or the repository's GitHub UI before making further changes.
- `MIGRATION_PLAN.md` was requested as a recommended document but is not present on the current migration branch.
- Main's `Makefile`, `build.sh`, `.github/workflows/development.yml`, `.github/workflows/galaxy-a50.yml`, README and selected A50 core defconfig were re-fetched from live main.

### Build entry point — exact control-flow reconfirmed
- `build.sh` defaults to `BUILD_PREF_COMPILER_VERSION='neutron'` and `BUILD_PREF_COMPILER='clang'`.
- The Neutron branch requires `$HOME/toolchains/neutron-clang`; if absent, it calls `exit_script`. The clean-runner CI blocker is therefore confirmed directly in the live script.
- The default path prepends the Neutron `bin` directory and the repository-local `toolchain/bin` to PATH, then sets `CROSS_COMPILE=aarch64-linux-gnu-` and `CROSS_COMPILE_ARM32=arm-linux-gnueabi-`.
- The script's `download_toolchain()` clones `TenSeventy7/exynos9610_toolchains_fresh` from the moving GitLab branch `neutron`; however, the default Neutron selector's missing-`$HOME/toolchains/neutron-clang` branch exits before that repository-local fallback can provision the compiler. This clone is not a valid substitute for the required Neutron Clang directory.
- The build script's CLI parser supports `--ksu` and translates it into `BUILD_KERNEL_KSU=true`; its KSU branch appends `CONFIG_KSU`, manual-hook and SuSFS configuration symbols. The Development workflow's `version` dispatch input still is not consumed by any build invocation, and the workflow invokes Magisk/non-root builds rather than `--ksu`.
- The script invokes clean/mrproper, make configuration, kernel compilation, and Magisk update through pipelines ending in `sed`; the script does not establish script-level `set -e` or `set -o pipefail`. The parent Actions step's shell options do not automatically apply to this separately executed script. Failure propagation remains a confirmed defect, but do not patch until the baseline build environment and test approach are reproducible.
- The A50 build script still selects `exynos9610-a50_core_defconfig`, then merges partial de-Knox, Android-version Mali, ROM variant, KSU/SuSFS or non-root, SELinux and Magisk/non-root fragments in sequence. The generated effective `.config` has not yet been captured.

### Toolchain provenance — new external-source finding
- The current Neutron Toolchains catalogue documentation describes Neutron as a rolling LLVM-source toolchain, with automated weekly builds, and explicitly cautions that complete stability cannot be guaranteed. This means an unqualified “latest” download is unsuitable as a reproducible baseline input.
- The documented AntMan manager supports syncing a specific dated release tag, and records build tag/date, Clang version, LLVM commit, binutils version/commit, minimum host glibc and SHA-256 in build metadata. Its sync flow verifies the archive against the catalogue SHA-256 before extraction.
- This provides a plausible mechanism for deterministic CI provisioning: select a fixed catalogue release, pin its tag, verify its published SHA-256, record compiler/LLVM/binutils/glibc metadata, and install it at the exact `$HOME/toolchains/neutron-clang` path expected by `build.sh`.
- **No Neutron release tag has yet been selected or verified as the exact SOVR v4.2 compiler.** The README advertises Clang 23.1.5, but that claim alone does not identify a Neutron archive or prove compatibility with this downstream 4.14.357 source. Do not download “latest” or change the compiler selector until the matching release metadata and an actual clean build establish provenance and compatibility.
- References for the toolchain mechanism: https://github.com/Neutron-Toolchains/clang-build-catalogue and https://github.com/Neutron-Toolchains/antman. These are toolchain documentation, not evidence that a particular release has passed the SOVR build.

### Current decision and validation boundary
- Preserve `main`; continue work only on `migration/linux-5.1-assessment`.
- Do not modify `build.sh`, workflows, configs, DTS, installer or kernel source in this session. There is not yet a proven compiler archive/revision to pin, and no clean baseline build has been performed.
- No compiler invocation, generated `.config`, Image/DTB/boot.img/ZIP artifact, static analysis, physical boot test or daily-driver test was performed.
- Linux 5.1 migration remains **not started**. Existing functionality remains in the historical 4.14.357 source and has not been ported or validated against 5.1.

### Next exact engineering task
1. Resolve and record the exact current migration branch HEAD SHA.
2. Inspect Neutron catalogue release metadata and locate the dated archive that corresponds to the repository's claimed Clang 23.1.5 (or otherwise establish the actual known-good compiler provenance from an authentic SOVR v4.2 build record/package).
3. Verify its published SHA-256, compiler version, LLVM/binutils revisions and host glibc requirement; check whether the companion cross tools expected by this script are included.
4. Add a **separate, non-release, manual CI baseline-validation workflow** on the migration branch that provisions that exact pinned toolchain into `$HOME/toolchains/neutron-clang`, records provenance, runs the exact Galaxy A50 One UI Android 14 enforcing/KSU build command selected for the known-good SOVR package, and uploads logs/config/image/DTB/ZIP even on failure where possible.
5. Run it and capture the actual `.config`, `include/generated/utsrelease.h`, kernel image, DTB, boot image and ZIP contents. Confirm whether the built kernel reports 4.14.357 and reconcile the defconfig generated-header discrepancy.
6. Only after this baseline can be reproduced should the script-level pipeline failure handling be corrected with focused tests; keep stable release publication and the `main` branch untouched.


## Continuation update — 2026-11-17 (live branch and compiler provenance investigation)

### Exact live ref snapshot
- main remains at e87fe99406053025d97b361fe18cc8faf6e416c6.
- migration/linux-5.1-assessment is currently at 8506b2feb53ca6f6285f6908c56952bc57cec5c5.
- GitHub compare confirms the migration branch is 13 commits ahead and 0 behind main. Its only aggregate file change is MIGRATION_STATUS.md; no kernel source, config, workflow, installer, or package implementation has changed.
- Main recursive tree was fetched successfully with truncated=false and 72,306 entries. The migration branch has 72,307 entries due to the status document.
- The repository-scoped Actions runs endpoint returned total_count: 0; no build evidence exists. PR search returned no PRs. Open issue search returned no issues. The current repository's releases endpoint is empty; tags remain unverified through the available endpoint.

### Authentic SOVR v4.2 release evidence — separate release repository
- The README's release link resolves to SOVR-Technologies/SOVR-Kernel-A50, which has a public v4.2 release published 2026-11-15 with eight uploaded ZIP assets.
- The release notes claim the source is OpenELA Linux 4.14.357 + ELTS, compiled with Clang 23.1.5, ThinLTO and LLD 23.1.5. These are upstream release-note claims; they are not yet independently verified from the binary payload.
- The A14 One UI 6 KSU package is SOVR-Kernel-v4.2.A14_OneUI6_A50_KSU.zip, size 18,080,593 bytes, published SHA-256 891bff8122ac293d7b58ce472764bb53bec2aacf6d9323676b6ef2801dc45e82. This provides a candidate immutable reference artifact for later forensic comparison; it has not been downloaded or inspected in this session.
- The release repository's v4.2 build.sh has the same blob SHA as this repository's main build.sh (5ab58405a3e7cb68968de9684ecaf9998888bcfb). Its defaults still select BUILD_PREF_COMPILER_VERSION='neutron', and its CLI has a generic --toolchain selector but no dedicated Clang 23.1.5 selector. The README/release compiler claim therefore cannot currently be reconciled with the default build-script path. Do not infer which compiler produced the release ZIP without inspecting build provenance or the ZIP itself.

### Neutron catalogue findings
- The Neutron catalogue's latest.txt currently identifies tag 06092026.
- Its metadata identifies Clang 24.0.0git, LLVM commit f42c87ba2c70219b1f4ad1f031a5b6a1ea6603fb, minimum host glibc 2.43, archive size 128 MB, and SHA-256 531083928c8e37f6b31e324dbfd0b5a8323f989b1c57ff2c1368b889b5b1bd30.
- The inspected 23052026 catalogue metadata identifies Clang 23.0.0git (not 23.1.5), LLVM commit ec4681df3d6bd1aeb9d00ee93c54eb7d4001cdff, minimum host glibc 2.43, archive size 78 MB, and SHA-256 243bb8841f57147952057256078f46618f928d4b5b8dca49b2063c18f4051b47.
- The Neutron catalogue README states that builds track latest LLVM sources and complete stability is not guaranteed. A fixed tag and checksum make a download reproducible, but do not establish compatibility with this 4.14.357 Samsung downstream kernel.
- No inspected Neutron release was shown to match the release notes' exact Clang 23.1.5. Do not pin the 24.0.0git or 23.0.0git archive as the known-good v4.2 compiler. Both also declare glibc 2.43, so runner compatibility must be checked before any future test.
- The Neutron release archive and AntMan mechanism are viable research candidates only. No toolchain has been selected, installed, or tested.

### Updated engineering assessment
1. Compiler provenance is now a concrete unresolved discrepancy: release notes claim Clang/LLD 23.1.5, while the identical checked-in build script defaults to Neutron and has no 23.1.5-specific branch. The actual build invocation, compiler binary, LLD binary, LLVM commit and cross-toolchain revision must be recovered from a trusted build record or package metadata.
2. The authentic v4.2 A14 KSU ZIP hash is recorded as a reference artifact. If binary access becomes available, inspect ZIP entries, installer, embedded Image/DTB, kernel release string, compiler strings, and embedded .config where available; verify the downloaded bytes against the published SHA-256 before trusting any extracted evidence.
3. Keep the 4.14.357 baseline build gate ahead of Linux 5.1 source migration. No Linux 5.1 tree, compatibility patch, driver port, or target configuration has been integrated.
4. Do not change build.sh or CI workflows until the baseline compiler and exact v4.2 build path are understood. A CI test should not silently replace the release compiler with a different LLVM generation.
5. The immediate next task is to recover or inspect the v4.2 artifact/build provenance and reconcile Clang 23.1.5 versus Neutron. Then choose a pinned, host-compatible toolchain and reproduce the exact A50 Android 14 enforcing + KSU baseline on the migration branch.

### Session validation boundary
- Repository, branch refs, recursive source tree, migration status, build script, workflows, Neutron catalogue metadata and the separate v4.2 release metadata were inspected.
- No kernel source, config, workflow, installer or packaging code was modified.
- This status-document update is documentation-only.
- No compiler was run; no .config, kernel Image, DTB/DTBO, boot image or ZIP was built or inspected.
- No static analysis, physical boot test, flash operation or daily-driver test was performed.
- Current phase remains Phase 0 — repository discovery / Phase 1 — forensic baseline audit. Linux 5.1 migration remains not started.


## Continuation update — 2026-11-17 10:05 PKT

### Exact live repository refs
- Default branch `main`: `e87fe99406053025d97b361fe18cc8faf6e416c6`.
- Assessment branch `migration/linux-5.1-assessment`: `8506b2feb53ca6f6285f6908c56952bc57cec5c5`, commit message `docs(migration): record toolchain and baseline build findings`.
- Live compare: assessment branch is **13 commits ahead, 0 behind** main. The only aggregate changed path remains `MIGRATION_STATUS.md`; no kernel source, configuration, DTS/DTBO, build script, workflow, installer or package has been changed on this branch.
- Main recursive tree remains 72,306 entries, complete and not truncated.
- Current repository Actions API response: `total_count=0`, `workflow_runs=[]`. This is an API-observed result at this session, not proof that no external or historical builds ever existed.
- Two workflows are present: `.github/workflows/development.yml` and `.github/workflows/galaxy-a50.yml`. No PRs were returned by repository-scoped PR search; no issue entries were returned by the repository-scoped issue search.
- `MIGRATION_PLAN.md` remains absent on the assessment branch. The status document is the only migration-specific file currently added relative to main.

### Build and workflow source inspection
- `build.sh` is the existing Mint/Fresh-derived build entry point. Its default compiler variables are `BUILD_PREF_COMPILER='clang'` and `BUILD_PREF_COMPILER_VERSION='neutron'`.
- The default Neutron path expects `$HOME/toolchains/neutron-clang`; when it is absent, the verification path exits. The script's repository-local clone of `TenSeventy7/exynos9610_toolchains_fresh` is not by itself proof that the required Neutron directory has been provisioned.
- The script's make/configuration, clean/mrproper, Magisk-update, toolchain-clone and ZIP commands contain pipelines ending in `sed`; script-level `set -e` and `set -o pipefail` are not established. This remains a confirmed failure-propagation defect.
- `.github/workflows/development.yml` triggers only on `workflow_dispatch`; its `version` input says “Build KSU” but the build invocations do not consume it and invoke Magisk or non-KSU paths.
- `.github/workflows/galaxy-a50.yml` triggers on `workflow_dispatch` and pushes to `android-*`; it has no PR trigger for the migration branch.
- Both workflows upload artifacts and have release-publishing jobs. Keep their release behavior separate from any future non-release baseline validation workflow.
- No workflow was dispatched during this session.

### Toolchain provenance — catalogue cross-check
- Neutron's published catalogue currently reports tag `06092026` as Clang `24.0.0git`, LLVM commit `f42c87ba2c70219b1f4ad1f031a5b6a1ea6603fb`, minimum host glibc `2.43`, archive SHA-256 `531083928c8e37f6b31e324dbfd0b5a8323f989b1c57ff2c1368b889b5b1bd30`.
- Catalogue tag `30062026` reports Clang `23.0.0git`, LLVM commit `12628715ce61c8db841211eb8683e2f53fa74f0b`, minimum host glibc `2.43`, archive SHA-256 `b473a420d693a4e3bc71b56ec4283c0e3738f87d6ac37fa202bb0be5e0a07521`.
- The catalogue's current latest pointer is `06092026`. The release list inspected contains no Neutron catalogue release explicitly identified as Clang `23.1.5`.
- LLVM upstream does publish the official LLVM/Clang `23.1.5` release (3 November 2026). This is **not equivalent evidence** to a Neutron bare-metal kernel toolchain release. Do not silently replace the repository's Neutron toolchain with the upstream LLVM distribution; the required cross-binutils, host-library assumptions, build flags and SOVR build compatibility have not been established.
- Neutron's catalogue documentation says builds track LLVM sources and warns that complete stability cannot be guaranteed. AntMan supports selecting a dated tag and verifies the archive against the catalogue SHA-256. This is a viable integrity mechanism only after the exact compiler build is selected and tested.
- References: https://github.com/Neutron-Toolchains/clang-build-catalogue/releases ; https://github.com/Neutron-Toolchains/clang-build-catalogue ; https://github.com/Neutron-Toolchains/antman ; https://github.com/llvm/llvm-project/releases/tag/llvmorg-23.1.5

### Authentic v4.2 release metadata
- The README links v4.2 release assets from the separate `SOVR-Technologies/SOVR-Kernel-A50` repository, not the current `crypto143007-ship-it/SOVR-Kernel-A50` repository.
- The upstream v4.2 release metadata is available and lists eight ZIP assets. The A14 One UI 6 KSU asset is `SOVR-Kernel-v4.2.A14_OneUI6_A50_KSU.zip`, 18,080,593 bytes, release-published SHA-256 `891bff8122ac293d7b58ce472764bb53bec2aacf6d9323676b6ef2801dc45e82`.
- Release metadata and hashes were inspected; the ZIP binary itself was not downloaded or unpacked. Therefore its embedded kernel image, compiler identity, DTB/DTBO, installer and build metadata remain unverified in this session.
- Upstream release URL: https://github.com/SOVR-Technologies/SOVR-Kernel-A50/releases/tag/v4.2

### Engineering decision / validation boundary
- The SOVR README's advertised Clang `23.1.5` and the Neutron catalogue releases inspected do not yet identify a matching, verifiable Neutron archive. This provenance mismatch is a blocker to selecting a pinned CI compiler.
- Do not use the latest Neutron tag merely because it is available; do not assume the official LLVM 23.1.5 release is interchangeable with the expected Neutron toolchain.
- Do not add a baseline CI workflow with an unverified compiler selection. First establish the authentic v4.2 toolchain provenance, or explicitly define and test a candidate compiler while clearly labeling the result as a new baseline experiment rather than a reproduction of v4.2.
- No kernel source, defconfig, workflow, installer, or package was modified. No compiler/build was run, no generated config or artifact was produced, and no physical device operation or test was performed. Linux 5.1 migration remains **not started**.

### Next exact engineering actions
1. Investigate the upstream v4.2 build provenance and any build metadata embedded in its published release assets; distinguish advertised LLVM version from the actual compiler binary.
2. Inspect the remaining `build.sh` control flow and device database to document every environment variable, toolchain path, config merge, image/DTB/DTBO build step, packaging step and cleanup/rollback dependency.
3. Complete the canonical A50 config and fragment inventory, including both defconfigs and all Android/ROM/Mali/SELinux/KSU fragment variants.
4. Reproduce the Linux 4.14.357 build using an authenticated, pinned toolchain. Capture the final `.config`, `UTS_RELEASE`, Image, DTB/DTBO, boot image, ZIP contents and build logs.
5. Only after the baseline is reproducible, implement a separate manual, non-release CI validation workflow on this branch; then address pipeline failure propagation with regression tests.
6. Keep `main` untouched and do not begin Linux 5.1 source replacement until the baseline and preservation matrix are complete.


## Continuation update — 2026-11-17 (DTB, image and installer chain re-audit)

### Scope and safety
- Re-inspected live `main` source files: `build.sh`, `arch/arm64/Makefile`, `arch/arm64/boot/Makefile`, `arch/arm64/boot/dts/Makefile`, `arch/arm64/boot/dts/exynos/Makefile`, `arch/arm64/boot/dts/exynos/dtb_exynos.cfg`, `arch/arm64/boot/dts/samsung/dtbo_exynos.cfg`, and `tools/make/package/mint.sh`.
- No kernel source, defconfig, DTS, build script, installer, workflow, or release artifact was modified.
- No binary ZIP was downloaded or inspected; release asset metadata and its published checksum remain unverified at the byte level.

### Corrected DTB/DTBO build-path finding
- The earlier statement that the DTB path was unresolved because `build_dtb()` / `build_dtbo()` are not called was incomplete. These two shell helpers are unused legacy functions, but the kernel's default Kbuild targets independently schedule Exynos DTB/DTBO image creation.
- `arch/arm64/Makefile` sets `KBUILD_DTBO_EXYNOS_IMG=dtbo_exynos.img` and `KBUILD_DTB_EXYNOS_IMG=dtb_exynos.img`, and adds both as dependencies of `all`.
- `arch/arm64/boot/Makefile` discovers DTBOs under `arch/arm64/boot/dts/samsung` and DTBs under `arch/arm64/boot/dts/exynos`. It invokes `mkdtimg` for `dtbo_exynos.img` and `mkdtbimg` for `dtb_exynos.img`.
- The DTB image configuration `arch/arm64/boot/dts/exynos/dtb_exynos.cfg` selects `exynos9610.dtb` and assigns custom0=0x00000000/custom1=0x000000ff.
- The DTBO image configuration `arch/arm64/boot/dts/samsung/dtbo_exynos.cfg` lists A50 SWA open variants 00, 01, 02, 03, 04 and 06 with their custom metadata.
- `arch/arm64/boot/dts/Makefile` includes `exynos/exynos9610.dtb` and the six A50 DTBO source targets.
- This establishes a source-level Kbuild generation path. It does not prove the generated binary is valid, matches the released ZIP, or is appropriate for every A505F hardware revision.

### Critical packaging distinction: DTBO generated, not staged
- `build_package()` moves `arch/arm64/boot/Image` to package root as `Image`, and `arch/arm64/boot/dtb_exynos.img` to package root as `dtb.img`.
- It does **not** stage `dtbo_exynos.img` into the ZIP.
- The AnyKernel installer sets `dtbblock=/dev/block/platform/13520000.ufs/by-name/dtb` and calls `flash_generic dtb`; it does not call a DTBO flashing function in the inspected installer.
- Therefore, the current package path installs the combined Exynos DTB image to the dedicated `dtb` partition; the separately generated DTBO image appears unused by this package path. Do not add DTBO flashing or remove DTBO generation until the A50 bootloader/partition layout and release ZIP are inspected.

### Critical boot-image distinction: boot.img is not the packaged kernel payload
- `build_image()` creates `tools/make/boot.img` using `mkbootimg` and the device database's page/header/offset values.
- The normal non-recovery flow then calls `build_package()`, which stages the raw kernel `Image` and `dtb_exynos.img`; it does not stage the just-created `tools/make/boot.img`.
- The installer uses AnyKernel3 `split_boot` and `flash_boot`, so the ZIP's raw `Image` is injected into the existing device boot image by the installer. The standalone `tools/make/boot.img` is not the payload flashed by this path.
- The `build_image()` output must not be treated as the release boot image without inspecting the package. Its metadata remains relevant as a secondary build artifact, but the actual install route is AnyKernel boot repacking plus dedicated DTB flashing.

### ROM-specific DTS selection and working-tree hazard
- Before kernel compilation, `build.sh` copies a variant DTS over `arch/arm64/boot/dts/exynos/exynos9610.dts`:
  - AOSP Android 14+: `aosp14/exynos9610.dts`
  - Legacy AOSP: `aosp/exynos9610.dts`
  - One UI Android 14+: `oneui14/exynos9610.dts`
  - Other One UI targets leave the checked-in default DTS in place.
- After packaging, it attempts to restore the original with `git checkout arch/arm64/boot/dts/exynos/exynos9610.dts`.
- This restore command can discard pre-existing local modifications to that DTS in a developer's working tree. It is a build reproducibility and data-loss risk. A future safe fix should use a temporary output/source overlay or save-and-restore the exact pre-build file state, with a regression test; do not change it before baseline reproduction.
- The source copy is performed in the source tree, not a separately isolated output tree. Parallel builds for different ROM variants in the same checkout would race on the shared DTS path. This is another reason to use isolated worktrees/build directories for variant builds.

### Installer behavior relevant to the user's Android 14 One UI baseline
- `mint.sh` detects Fresh/One UI properties and Android SDK version. For SDK 34/35/36 it explicitly selects pure SOVR kernel defaults for One UI 6+/Fresh 6 and does not copy the legacy One UI 3/One UI 4 performance assets.
- The installer calls `split_boot`, `flash_boot`, then `flash_generic dtb`.
- The DTB block path is hard-coded as `/dev/block/platform/13520000.ufs/by-name/dtb`; compatibility with the user's exact A505F partition map must be confirmed before any new installer is produced.
- AOSP uses a different branch that installs ZRAM writeback overlay/init/fstab assets. That is separate from the user's current One UI 6.1.1-based ROM and must not be mixed into the One UI package.

### Updated conclusions and next gates
1. Source-level DTB generation is now traced. The earlier unresolved-call concern is superseded: Kbuild, not the unused shell helpers, creates the Exynos DTB/DTBO image outputs.
2. The release package path stages raw `Image` and `dtb_exynos.img` only. DTBO is generated but not staged/flashed by the inspected installer.
3. The generated standalone `tools/make/boot.img` is not the normal ZIP's boot payload; AnyKernel repacks the installed boot image from raw `Image`.
4. The source-tree DTS overwrite followed by `git checkout` is a concrete build safety issue to address later, after capturing a reproducible baseline.
5. The next evidence gate remains obtaining the official v4.2 A14 One UI KSU ZIP from the separate release repository, verifying its published SHA-256, then inspecting ZIP entries, installer scripts, kernel Image metadata, DTB payload and any embedded config/build metadata.
6. After binary forensics, establish a clean build environment and reproduce the exact Android 14 One UI enforcing + KSU build. Do not begin Linux 5.1 driver migration or alter the packaging contract before this baseline is understood.

### Validation boundary
- Source-level build/packaging flow: inspected.
- Release ZIP bytes and checksum: not downloaded or independently verified.
- Generated Image, DTB, DTBO and boot.img: not built or inspected.
- No compiler run, static analysis, physical device test, flash or boot validation performed.
- Linux 5.1 migration remains not started.


### DTS variant comparison — additional finding
- Fetched the default, One UI 14, AOSP 14 and legacy AOSP Exynos9610 DTS sources from live `main`.
- `aosp14/exynos9610.dts` and `aosp/exynos9610.dts` are byte-identical at Git blob SHA `acd2fecbb1521bc094216b03ff1dd548ed0e1533`; the Android 14 AOSP copy currently adds no DTS delta over legacy AOSP.
- The One UI 14 DTS differs materially in its Android fstab declarations: `vendor` and `product` are changed from `ext4` to `erofs`, and the product entry is enabled. The `system` entry remains `ext4` and disabled in the inspected DTS.
- The default DTS declares system/vendor/product as ext4 (system disabled, vendor enabled, product present). The AOSP14 DTS declares system and vendor as ext4 (system disabled); it has no product fstab node in the inspected region.
- This is a concrete reason not to collapse the One UI 14 and AOSP DTB selections into one generic “Android 14 EROFS” tree. The One UI 14 vendor/product EROFS declarations are part of the ROM-specific boot contract and must be preserved.
- The user's One UI-based EROFS ROM does not justify assuming every partition is EROFS. The inspected DTS specifically describes vendor/product as EROFS and system as ext4/disabled. The actual on-device partition formats and fstab remain the final authority.


## Continuation update — 2026-11-17 (ROM config composition and installer asset audit)

### Exact build configuration composition

- The live `build.sh` selects `arch/arm64/configs/exynos9610-a50_core_defconfig` as the base for A50 builds. It creates a temporary config by copying that file, then appends the following fragments from `kernel/configs/`:
  1. `mint_partial-deknox-${BUILD_ANDROID_PLATFORM}.config`
  2. `mint_mali-${BUILD_ANDROID_PLATFORM}.config`
  3. `mint_variant_${BUILD_KERNEL_CODE}.config`
  4. KSU/SuSFS or explicit non-root settings
  5. SELinux enforcing or permissive settings
  6. Magisk pre-root or non-root initramfs settings
  7. `CONFIG_MINT_PLATFORM_VERSION=${BUILD_ANDROID_PLATFORM}`
- The fragment merge is a direct append to the temporary defconfig before the make defconfig target is invoked. The effective final `.config` is therefore the result of Kconfig resolution, not a simple concatenation; conflicts and unmet symbols must be checked from a real generated config.
- The fragment directory is `kernel/configs`, not `arch/arm64/configs`. Earlier fragment-path shorthand should be read accordingly.

### Verified Android 14 configuration details

- `kernel/configs/mint_mali-14.config` selects `CONFIG_MALI_BIFROST_R38P1=y`, disables the older R16P0/R19P0/R25P1/R26P0/R32P1 variants, and enables the Exynos Mali platform integration, DVFS, PM, RTPM, QoS, thermal, BTS and device-tree support.
- This is a source-level selection. It does not prove the matching userspace/vendor Mali stack on the user's ROM is compatible or that GPU operation has been tested.
- `kernel/configs/mint_variant_oneui.config` enables `CONFIG_MINT=y`, `CONFIG_MINT_SESL=y`, Samsung SCSC WLBT daemon support, the EFS Wi-Fi MAC path `/efs/wifi/.mac.info`, up to three WLAN interfaces, AP interface `swlan0`, Samsung MTP and Knox NCM.
- `kernel/configs/mint_variant_aosp.config` enables `CONFIG_MINT=y`, disables `CONFIG_MINT_SESL` and `CONFIG_SCSC_WLBTD`, uses the vendor EFS path `/mnt/vendor/efs/wifi/.mac.info`, allows up to twelve WLAN interfaces, selects AP interface `wlan1`, and enables early devtmpfs mounting for Treble/GSI bootstrap.
- The Android 14 `mint_partial-deknox-14.config` fragment still enables FIVE, FIVE TEE/TZDEV integration, integrity signatures, fscrypt SDP and SDP. The fragment name must not be interpreted as removing every Samsung security/integrity dependency.
- `mint_selinux-enforcing.config` selects `CONFIG_ALWAYS_ENFORCE=y`, disables SELinux switching and permissive fallback. The build script separately adds KSU/SuSFS settings or explicitly disables KSU, then merges the SELinux and root/initramfs fragments.
- The above fragment files are inputs to the config build, not proof that every symbol survives Kconfig resolution. The final generated `.config` and build log are required for definitive confirmation.

### Installer assets and ROM branch mapping

- `build_package()` stages common AnyKernel assets first, then chooses only the target-specific asset directory:
  - AOSP: `files_aosp` plus `patch/init.zram.rc`.
  - One UI Android 11: `files_oneui` plus RAM Plus/Pageboost patches.
  - One UI Android 12/13: `files_fresh`.
  - One UI Android 14+: no legacy One UI/Fresh asset directory is copied by this branch.
- The omission of legacy One UI assets for Android 14+ is consistent with `mint.sh`: SDK 34/35/36 takes the pure SOVR-default branch and does not install the legacy One UI 3/4 or Fresh 4/5 performance assets.
- The installer uses ROM detection and SDK detection at flash time; the build variant selects which assets are even available inside the ZIP. Both sides of this contract must remain aligned during migration.
- AOSP's installer branch installs the ZRAM writeback overlay APK, ZRAM fstab and init service under `/vendor`, patches vendor properties and adjusts vendor init swap actions. This is a distinct AOSP integration and must not leak into the user's One UI package.
- One UI Android 14+ relies on the kernel/ROM's existing SOVR defaults and EROFS-compatible path rather than copying the legacy writable-system performance files. Preserve this behavior unless a future ROM-specific requirement is demonstrated.

### Build-path risks reaffirmed

- The functions `build_dtb()` and `build_dtbo()` in `build.sh` are legacy helper functions and are not called in the final build flow. DTB/DTBO generation is handled by Kbuild dependencies as documented above.
- The normal package path moves raw `Image` and `dtb_exynos.img` into the package staging directory; it does not stage `dtbo_exynos.img`.
- The standalone `tools/make/boot.img` is generated before packaging but is not the boot payload used by the AnyKernel installer. The installer repacks the existing boot image with `split_boot` / `flash_boot` and separately flashes the DTB partition.
- `build.sh` currently copies ROM-specific DTS over the shared source path, then uses `git checkout` to restore it. This remains unsafe with pre-existing local edits and concurrent variant builds.
- The current source installer hard-codes `/dev/block/platform/13520000.ufs/by-name/dtb`. This must be verified against the exact device partition map before any new installer is built or used.

### Engineering decisions

1. Treat the base defconfig plus all fragments as one versioned ROM target configuration. A migration matrix must map Android SDK, ROM family, Mali DDK, SCSC settings, security/TZDEV dependencies, KSU/SuSFS and initramfs mode.
2. Do not replace R38P1 or alter Mali configuration based only on upstream kernel availability. First identify the matching vendor/userspace DDK and preserve the Exynos-specific Mali platform glue.
3. Preserve the One UI Android 14 no-legacy-assets installer path and the separate AOSP ZRAM writeback path.
4. Before any build-script repair, capture the exact current v4.2 output and verify package contents. The existing pipeline failure propagation and DTS restore hazards remain candidates for isolated fixes with regression tests.
5. No kernel source, configuration fragment, workflow, installer, or release file was changed in this audit. No compiler build, ZIP installation, physical-device flash or boot test was performed. Linux 5.1 migration remains not started.


## Continuation update — 2026-11-17 (baseline version and build-script reliability audit)

### Kernel version identity: source is 4.14.357; defconfig banner is stale

- The top-level kernel `Makefile` on `main` declares `VERSION=4`, `PATCHLEVEL=14`, `SUBLEVEL=357`. This is the authoritative Kbuild source version: Linux 4.14.357.
- `arch/arm64/configs/exynos9610-a50_core_defconfig` begins with the generated-file banner `Linux/arm64 4.14.194 Kernel Configuration`. This is stale provenance text embedded in a checked-in defconfig, not evidence that the current source tree is 4.14.194.
- The build script prints the source version using Makefile variables, so it will identify 4.14.357 at build time.
- Still unknown: whether the released v4.2 ZIP's embedded Image was actually built from this exact source commit and effective config. Only a successful controlled build plus binary comparison/metadata can close that gap.
- Correct interpretation: source baseline 4.14.357; checked-in defconfig header claims it was originally generated on 4.14.194. Do not silently edit the header or assume all config values are refreshed for 4.14.357 without regenerating and reviewing the effective .config.

### Toolchain provenance: build script does not pin a compiler version

- `build.sh` hard-codes `BUILD_PREF_COMPILER='clang'` and `BUILD_PREF_COMPILER_VERSION='neutron'`.
- Its primary expected compiler location is `$HOME/toolchains/neutron-clang`; the script's status text describes this as “LLVM 22+”. If missing, it clones the repository's external `toolchain` directory from `https://gitlab.com/TenSeventy7/exynos9610_toolchains_fresh.git`, branch `neutron`, shallow depth 1.
- The script does not pin a Neutron Git commit, LLVM exact version, Clang binary hash, LLD version or target toolchain manifest. The external toolchain branch may move.
- The source-level default therefore does **not** independently establish the earlier release-note claim of Clang/LLD 23.1.5. That claim must be checked against the actual v4.2 CI logs/artifact provenance or exact compiler binary.
- `verify_toolchain()` checks for a directory and sets PATH/LD_LIBRARY_PATH; it does not validate `clang --version`, `ld.lld --version`, compiler hashes or linker identity before proceeding.
- The build exports `CROSS_COMPILE=aarch64-linux-gnu-` and `CROSS_COMPILE_ARM32=arm-linux-gnueabi-`. The selected toolchain must contain/resolve compatible cross tools; this is another explicit baseline check.

### Defconfig and fragment merge risks

- The script copies the A50 core defconfig to a temporary defconfig, appends Android-version partial-deknox, Mali and ROM-variant fragments, then appends KSU/SuSFS or disables KSU, then SELinux mode and root/initramfs fragments.
- It ultimately invokes Kconfig to produce the effective configuration. The temporary concatenated input is not equivalent to the final resolved `.config`.
- The build script does not, in the inspected section, preserve a versioned copy of the final generated `.config` and a machine-readable manifest of fragment hashes/compiler identity beside every release ZIP.
- The build script's `merge_config()` checks only that the named fragment file exists before appending its contents. It does not validate duplicate/conflicting assignments at append time.
- A controlled baseline must archive: source commit, dirty-tree status, exact defconfig and fragment hashes, final resolved `.config`, compiler/LLD versions and hashes, build command/environment, build log, Image/DTB hashes and ZIP hash.

### Concrete build-script failure-propagation issues

- The script pipes multiple commands through `sed` for readable logs but does not set `set -o pipefail` in the inspected header. In Bash, without pipefail, a pipeline normally returns the status of its last command; a failed `make`, `git clone`, `zip`, or copy command can be masked by a successful `sed`.
- The clean path uses `make clean | sed` and `make mrproper | sed`; a failure can be hidden. Similar risks occur in toolchain clone, Magisk update, ZIP creation and other piped commands.
- The script uses `exit_script()` implemented as `kill -INT $$`, rather than a consistent error-return path with cleanup and a precise failure code.
- `build_package()` creates a temporary staging directory using `mktemp`, copies assets, moves the only built `Image` and DTB into staging, zips the staging directory, moves the ZIP to output, and removes the staging directory. There is no visible EXIT trap in the inspected script to clean temporary state on failure.
- Because the package stage uses `mv` for Image and DTB, a later packaging failure may leave the source build output without those files. A future fix should copy or stage from a preserved build-output directory, validate all expected inputs first, and only publish atomically after ZIP validation.
- The ZIP command is `zip -9 -r ./${FILE_OUTPUT} ./* | sed ...`; without pipefail, a ZIP failure may be masked. The subsequent `mv` should be preceded by an explicit ZIP integrity test (e.g. `unzip -t`) and required-entry assertions.
- The build script should not be globally rewritten in one step. Add strict error handling and trap-based cleanup in a dedicated CI-only/reproducibility branch first, with shellcheck and synthetic failure tests, then compare output hashes before replacing release behavior.

### Device image metadata and packaging contract

- `Documentation/device-db/a50.sh` declares A50 boot image metadata: board `SRPRL05B007KU`, base `0x10000000`, page size 2048, kernel offset `0x00008000`, ramdisk/second offset `0xf0000000`, tags offset `0x00000100`, header version 1, DTB hash type SHA-1.
- These values feed the standalone mkbootimg path, but the normal SOVR ZIP path packages raw `Image` and `dtb_exynos.img` for AnyKernel repacking/flashing. Keep these two paths conceptually separate when validating the release.
- The installer and DTB partition path still require verification against the exact A505F partition map and actual ZIP script before any installation changes.

### Current state and next validation gate

- The live source Makefile proves the checked-out source is 4.14.357. The defconfig's 4.14.194 banner is stale provenance text and must not be mistaken for the active source version.
- The build script defaults to a movable Neutron toolchain branch and checks toolchain directory presence rather than exact compiler identity. The release's claimed Clang 23.1.5 remains unverified.
- Pipeline failure masking and destructive `mv` staging are concrete reproducibility hazards. No source fix was made in this audit.
- No CI workflow was dispatched, no new Actions run was created, and no build was attempted. The repository search still returned no open pull requests.
- Next step: obtain the official v4.2 release artifact and associated CI provenance. If the ZIP cannot be fetched through the connector, use a reproducible release URL/download route with checksum verification before inspection. Then run a clean baseline build in an isolated branch/workspace and archive the final config, compiler manifest, build logs and artifact hashes.
- No kernel source, defconfig, DTS, build script, installer, workflow, or release asset was modified. Linux 5.1 migration remains not started.
