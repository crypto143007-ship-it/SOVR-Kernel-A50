# SOVR-Kernel-A50 Development State

**Project baseline:** SOVR v4.2 / Linux 4.14.357 / Samsung Galaxy A50 SM-A505F / Exynos 9610  
**Branch:** `main`  
**Audited HEAD:** `061bc5b7913ebab88f6af04856b7bff11d5080b2`

## Done / Committed
- `build.sh`: after sourcing the A50 device database, set `PLATFORM_VERSION="${BUILD_ANDROID_PLATFORM}.0.0"` so mkbootimg `--os_version` matches the selected `--android` target. The device DB's legacy static `12.0.0` no longer overrides Android 11/12/14 selection.
- Commit: `3227d8b749042ad0adb14fb4153aba89951407b0` — `fix: align boot image OS version with Android target`.
- Re-fetched `build.sh` and verified the new assignment is present at line 711.
- Confirmed README v4.2 release matrix identifies One UI 6+/Android 14 as the hardware-validated daily-driver target and specifies ClangBuiltLinux Clang 23.1.5 / LLVM 23.
- Confirmed both existing workflows still build Android 11/12 only; neither invokes `--ksu`.
- Confirmed `build.sh` has Android 14 DTB selection and KSU config/package naming paths.
- `build.sh`: added global/local `pipefail`; all 14 make pipelines in `build_kernel()` now return immediately on failure; clean/mrproper failures exit nonzero; stale `arch/arm64/boot/Image` is removed before compilation; caller aborts before image/package steps if compilation fails.
- Commit: `00f81c05415eea5f78fdd91b7f361b42c5c0cbcb` — `fix: stop packaging after kernel build failures`.
- Re-fetched the committed source and verified the guarded make pipelines, clean/mrproper failure handling, stale Image removal and compile-abort guard.
- No full kernel compile, CI run, package validation or device boot test was run.

## Failed / Do Not Repeat
- Do not restore `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md` to `main`; commit `9811fd3` reverted its accidental addition.
- Do not treat SOVR 4.0 as current; baseline is SOVR 4.2.
- Do not modify `SOVR-Technologies/SOVR-Kernel-A50`; work only in this fork.
- Do not assume workflow-level `set -eo pipefail` propagates into the separately executed `build.sh`.
- Do not change `PLATFORM_PATCH_LEVEL=2022-09` until the correct target patch-level policy/value is verified; this change only fixes the Android OS version field.
- Do not assume the Neutron branch is a verified source of the documented LLVM 23.1.5 binaries without checking its exact revision and compiler version.

## Active Bug / Current Focus
- **Toolchain target (user-confirmed and authoritative):** ClangBuiltLinux `clang 23.1.5` (`LLVM 23`) + `lld 23.1.5` + `ThinLTO`. This is the required SOVR 4.2 toolchain target; do not substitute Neutron rolling/latest LLVM, Clang 24, another LLVM release, GCC, or a different linker. **Provisioning remains to be verified:** `build.sh:45-46,79-87,118-151` currently selects `neutron` and expects `$HOME/toolchains/neutron-clang`; confirm the exact compatible distribution, compiler/linker versions, archive checksum, extracted path and kernel-4.14 compatibility before changing provisioning.
- **Build failure propagation:** fixed in commit `00f81c0`; retain regression checks for pipeline failure propagation and stale Image prevention.
- **CI coverage — `.github/workflows/development.yml`, `.github/workflows/galaxy-a50.yml`:** both cover Android 11/12 only and do not exercise the documented Android 14 KSU target. Existing jobs use Magisk or non-root invocations.
- **Boot image patch metadata — `Documentation/device-db/a50.sh`:** `PLATFORM_PATCH_LEVEL` is static `2022-09`; determine the correct release policy before changing it.
- Linux 5.1 migration remains unimplemented/unvalidated. Preserve the bootable Linux 4.14.357 SOVR 4.2 baseline.

## Next Step
1. Provision and verify the user-confirmed ClangBuiltLinux `clang 23.1.5` / `lld 23.1.5` + ThinLTO toolchain (exact distribution, checksum, extracted path and Linux 4.14 compatibility); repair the Neutron selector/path only to deliver this exact target.
2. Add a separate Android 14 One UI KSU CI job only after the toolchain is pinned and boot-image OS/patch metadata is validated.
3. Run CI and inspect the generated config, Image, DTB/DTBO, ZIP contents and SHA-256 before any device flash.
4. Audit the Android 14 One UI DTS selection and validate boot-image/DTB/DTBO packaging.
5. Resume the DTS/TZDEV/TEEGRIS compatibility audit and Linux 5.1 migration after the baseline build is reproducible.

## Investigation Update — 2026-11-19
- Re-audited current `main`: `build.sh` still defaults to `BUILD_PREF_COMPILER_VERSION='neutron'`; the special-case requires `$HOME/toolchains/neutron-clang` and exits if absent before reaching the generic repository-local toolchain fallback. The default clone path and the documented install path therefore need to be reconciled before CI provisioning is changed.
- README documents ClangBuiltLinux Clang 23.1.5 / LLVM 23, while the script's Neutron selector does not itself pin a version or release.
- Public Neutron catalogue documentation says its published builds are made from latest LLVM sources rather than stable releases; its 2026-09-06 catalogue entry reports Clang 24.0.0git. This is evidence that “Neutron” is not inherently a stable LLVM 23.1.5 pin, **not** proof of the exact version in the separate legacy GitLab `TenSeventy7/exynos9610_toolchains_fresh` `neutron` branch.
- Direct inspection of that GitLab branch, its exact commit, compiler `--version`, bundled tools, and archive/checksum was not available in this audit. No toolchain files or build configuration were changed on this evidence alone.
- Current workflow audit remains: `.github/workflows/development.yml` contains Android 11/12 builds; Android 14 One UI KSU is not covered. Do not add that job until the actual compiler source/version and boot metadata policy are verified.
- Latest commit search returned `ff292772` (`docs: record kernel build failure guard`) after the code fix `00f81c0`. The `DEV_STATE.md` audited-HEAD field should be refreshed when the next state commit is made.

## Revised Next Step
1. Obtain and inspect the exact legacy GitLab `neutron` branch source/revision (or a reproducible clone/build-info record). Verify `clang --version`, `ld.lld --version`, target triple, archive checksum and host runtime requirements against README's LLVM 23.1.5 claim.
2. Reconcile `build.sh`'s expected toolchain path with its clone/fallback logic. Add deterministic, checksum-verified provisioning only after the exact intended toolchain is established; do not substitute a newer Neutron build or generic LLVM archive.
3. Add a separate Android 14 One UI KSU CI job after toolchain and boot-image patch-level policy are validated.
4. Run CI and inspect generated config, Image, DTB/DTBO, ZIP contents and SHA-256 before any device flash.
5. Audit Android 14 One UI DTS selection and boot-image/DTB/DTBO packaging; then resume TZDEV/TEEGRIS compatibility and Linux 5.1 migration research without changing the bootable 4.14.357 baseline.


## Toolchain Requirement Confirmation — 2026-11-19
- User explicitly reconfirmed the required toolchain specification:
  `ClangBuiltLinux clang 23.1.5 (LLVM 23) + lld 23.1.5 + ThinLTO`.
- This is a **fixed project requirement**, not an open version-selection question. The README Technical Specifications table already states this exact row and remains aligned.
- Distinguish the fixed target from the still-unverified acquisition/provisioning mechanism. The exact binaries/source revision, checksum and install path must be validated; do not reinterpret uncertainty about Neutron provisioning as uncertainty about the requested compiler version.


## Optimization Target Audit — 2026-11-19
- User clarified that the **Optimization Target should use the latest worthwhile optimizations**. Interpret this as the newest proven, device-compatible improvements for Exynos 9610 / the 4 GB A50, not blind imports of newer-mainline features or benchmark-only tuning.
- Confirmed `build.sh` selects `exynos9610-a50_core_defconfig` at line 639. This is the active baseline for the normal A50 build; do not audit or modify only the unused/default defconfig.
- Active core defconfig already enables: `CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE_O3`, Clang LTO + ThinLTO, `CONFIG_LRU_GEN` (MGLRU implementation), PSI, Energy Adaptive CPUFreq governor, ZSTD ZRAM, ZRAM writeback + LRU writeback, ARM64 crypto acceleration, Exynos thermal/devfreq thermal, EROFS per-CPU high-priority decompression kthreads, F2FS, and KernelSU/SuSFS.
- Verified source wiring: top-level `Makefile` applies `-O3` when the O3 config is enabled, uses `-flto=thin` for ThinLTO, and adds safe ICF to vmlinux linking; `arch/arm64/Makefile` applies ARMv8 crypto/CRC/SHA2/AES and Cortex-A73 tuning for Exynos9610 Clang builds. README optimization claims are therefore backed by current source/config for these flags.
- The secondary `exynos9610-a50_default_defconfig` differs materially and is not the config selected by the current build path. Keep future config changes focused on the active `_core_defconfig` unless a separate build variant is explicitly added.
- No optimization code/config was changed and no compile or boot validation was performed during this audit. Preserve existing thermal/DVFS policy and avoid new overclock/undervolt or aggressive boost changes without measured device evidence.

## Revised Next Step
1. Continue with a compatibility-first optimization audit of the active `exynos9610-a50_core_defconfig` and its implementation: memory reclaim/MGLRU + PSI, ZRAM writeback, scheduler/CPUFreq/EMS, Mali/GPU DVFS, Exynos thermal/devfreq, storage/EROFS/F2FS and ARM64 crypto.
2. For each candidate newer optimization, verify its upstream/backport provenance, Linux 4.14.357 API dependencies, Samsung vendor interactions, measurable benefit on the A50 4 GB model, and rollback path before proposing a patch.
3. Keep the current stable config as the control build; test one change at a time with build artifacts, config diffs, runtime logs and battery/thermal/multitasking measurements.
4. In parallel, continue the pinned LLVM 23.1.5 / LLD 23.1.5 provisioning investigation. Do not add Android 14 KSU CI until toolchain and boot metadata policy are verified.


## Build Continuation — 2026-11-19
- README explicitly documents the expected local toolchain path as `$HOME/toolchains/neutron-clang` and names Clang 23.1.5 / LLVM 23. The directory name is not proof of its contents; actual compiler and linker versions must be checked.
- `build.sh` now runs a fail-fast toolchain contract check after resolving PATH and before build configuration/compilation. It requires both `clang --version` and `ld.lld --version` to report exactly version string `23.1.5`. This prevents an unintended Clang 24 / rolling compiler or mismatched linker from silently producing a SOVR 4.2 build.
- The version check captures complete version output before extracting its first line; it deliberately avoids a `head` pipeline so global `pipefail` cannot turn a successful version command into SIGPIPE failure.
- Commits: `f8bb112` (add pinned LLVM/LLD gate), `52652d0` (make version capture pipefail-safe).
- README's toolchain path and version requirement are aligned; the source/revision and reproducible provisioning mechanism are still not pinned. No toolchain archive/source was downloaded or trusted in this continuation.
- No GitHub Actions workflow-dispatch capability is exposed through the connected GitHub actions; no build was launched. No compile, package, or device boot result is claimed.
- Next: provision the exact ClangBuiltLinux LLVM 23.1.5 / LLD 23.1.5 toolchain at the documented path, then run the A50 Android 14 One UI KSU build in CI. Inspect config, Image, DTB/DTBO, ZIP and SHA-256. Do not flash until artifact checks and device-specific boot metadata are validated.


## Build Continuation Correction — 2026-11-19
- During the attempted LLVM 23.1.5 gate edit, the remote `build.sh` content was malformed by the file-update operation. This was detected by re-fetching and checking line count/content.
- Immediately restored `build.sh` byte-for-byte to its pre-edit baseline blob `27238dbec68279e6af3b067c9c6251ba9360f9fa` in commit `061bc5b7913ebab88f6af04856b7bff11d5080b2`.
- Re-fetched and verified `build.sh` is back to 32,322 characters / 825 lines and contains no injected LLVM gate. The earlier commits `f8bb112` and `52652d0` were superseded by this restoration; do not rely on their implementation.
- No kernel compile was launched. Do not claim a successful build.
- Next: make future script changes in a separate branch or validated patch, run `bash -n` and a diff review before updating `main`. First establish a verified ClangBuiltLinux 23.1.5 + LLD 23.1.5 provisioning source and exact checksum; only then add a fail-fast version check and Android 14 KSU CI job.

## Build Continuation Audit — 2026-11-19 (18:20 PKT)
- Re-fetched current `main`: `build.sh` blob `27238dbec68279e6af3b067c9c6251ba9360f9fa` is the original 825-line baseline. The earlier LLVM-gate implementation commits were superseded by restoration; the authoritative current script has **no LLVM 23.1.5 fail-fast check**.
- Actual toolchain flow: `BUILD_PREF_COMPILER_VERSION='neutron'`; `verify_toolchain()` prepends `$HOME/toolchains/neutron-clang/bin` and the external toolchain `bin`, and prints “LLVM 22+”. For this selector it exits if `$HOME/toolchains/neutron-clang` is absent. `build_kernel()` passes LLVM tools (`llvm-ar/nm/objcopy/objdump/strip`) and `LLVM=1`, but does not explicitly pin the LLD binary version. The directory name does not prove it contains the project-required Clang 23.1.5 / LLD 23.1.5.
- Existing `.github/workflows/development.yml` only builds One UI/AOSP Android 11/12 and invokes `--magisk`; it has no Android 14 One UI KernelSU job. A separate A14 KSU workflow is still needed after toolchain validation.
- Identified a reproducible candidate source for the exact version: kernel.org's slim LLVM toolchains are built from signed `llvmorg-<version>` tags and PGO-optimized with tc-build; their documented backends include AArch64 and ARM. The official files index lists `llvm-23.1.5-x86_64.tar.xz` and matching `.tar.sign` (published 2026-11-04). This is a stronger candidate for a pinned build than the rolling Neutron selector, but the archive signature, package layout, exact `clang --version` / `ld.lld --version`, and integration with this vendor kernel have **not yet been verified**. Do not install or use it until those checks pass.
- LLVM 23.1.6 has since appeared in the kernel.org toolchain index (2026-11-18), but project requirement remains exactly 23.1.5; do not auto-upgrade to 23.1.6.
- Checked the remembered Vothcito reference branch `exynos9610-port`: it is Linux 5.15.211, and its A50 core defconfig identifies itself as Linux 4.14.194. Treat it as a source of selectively reviewable backports only; do not transplant its kernel tree or config wholesale into SOVR 4.2 / 4.14.357.
- No source code or workflow changes made in this audit; no compile, package, or boot test was performed. GitHub Actions dispatch is not exposed by the connected GitHub actions in this session.
- **Authoritative next steps:** (1) verify kernel.org 23.1.5 `.tar.sign` and archive layout on a disposable runner; (2) confirm exact Clang and LLD version output and required host libraries; (3) stage the provisioning and fail-fast toolchain validation on a dedicated branch, not directly on `main`; (4) add an Android 14 One UI KSU enforcing workflow using `./build.sh --ksu --automated --device a50 --variant oneui --android 14`; (5) inspect config, Image, DTB/DTBO, package contents and SHA-256 before considering device flash.
