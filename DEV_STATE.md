# SOVR-Kernel-A50 Development State

**Project baseline:** SOVR v4.2 / Linux 4.14.357 / Samsung Galaxy A50 SM-A505F / Exynos 9610  
**Branch:** `main`  
**Audited HEAD:** `00f81c05415eea5f78fdd91b7f361b42c5c0cbcb`

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
