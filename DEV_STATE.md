# SOVR-Kernel-A50 Development State

**Project baseline:** SOVR v4.2 / Linux 4.14.357 / Samsung Galaxy A50 SM-A505F / Exynos 9610  
**Branch:** `main`  
**Audited HEAD:** `3227d8b749042ad0adb14fb4153aba89951407b0`

## Done / Committed
- `build.sh`: after sourcing the A50 device database, set `PLATFORM_VERSION="${BUILD_ANDROID_PLATFORM}.0.0"` so mkbootimg `--os_version` matches the selected `--android` target. The device DB's legacy static `12.0.0` no longer overrides Android 11/12/14 selection.
- Commit: `3227d8b749042ad0adb14fb4153aba89951407b0` — `fix: align boot image OS version with Android target`.
- Re-fetched `build.sh` and verified the new assignment is present at line 711.
- Confirmed README v4.2 release matrix identifies One UI 6+/Android 14 as the hardware-validated daily-driver target and specifies ClangBuiltLinux Clang 23.1.5 / LLVM 23.
- Confirmed both existing workflows still build Android 11/12 only; neither invokes `--ksu`.
- Confirmed `build.sh` has Android 14 DTB selection and KSU config/package naming paths.
- No kernel C sources, defconfigs, DTS files, or workflow files changed. No full kernel compile or device boot test was run.

## Failed / Do Not Repeat
- Do not restore `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md` to `main`; commit `9811fd3` reverted its accidental addition.
- Do not treat SOVR 4.0 as current; baseline is SOVR 4.2.
- Do not modify `SOVR-Technologies/SOVR-Kernel-A50`; work only in this fork.
- Do not assume workflow-level `set -eo pipefail` propagates into the separately executed `build.sh`.
- Do not change `PLATFORM_PATCH_LEVEL=2022-09` until the correct target patch-level policy/value is verified; this change only fixes the Android OS version field.
- Do not assume the Neutron branch is a verified source of the documented LLVM 23.1.5 binaries without checking its exact revision and compiler version.

## Active Bug / Current Focus
- **Toolchain provisioning/version mismatch — `build.sh:45-46,79-87,118-151`:** the script defaults to compiler version selector `neutron` and requires `$HOME/toolchains/neutron-clang`. The Neutron special-case exits if that directory is absent before the generic repository-local toolchain fallback can run. README documents ClangBuiltLinux LLVM 23.1.5; verify the exact approved distribution/source and `clang --version` / `ld.lld --version` before automating provisioning.
- **Build failure propagation — `build.sh:267-282,701-702`:** configuration/build/clean make commands are piped through `sed`; the child script has no local pipefail or explicit make-status handling. A failed build may proceed to image packaging, potentially using a stale `Image`.
- **CI coverage — `.github/workflows/development.yml`, `.github/workflows/galaxy-a50.yml`:** both cover Android 11/12 only and do not exercise the documented Android 14 KSU target. Existing jobs use Magisk or non-root invocations.
- **Boot image patch metadata — `Documentation/device-db/a50.sh`:** `PLATFORM_PATCH_LEVEL` is static `2022-09`; determine the correct release policy before changing it.
- Linux 5.1 migration remains unimplemented/unvalidated. Preserve the bootable Linux 4.14.357 SOVR 4.2 baseline.

## Next Step
1. Verify the exact ClangBuiltLinux LLVM 23.1.5 toolchain distribution and its expected extracted directory; compare it against the script's Neutron selector and documented path.
2. Add explicit make-status propagation in `build.sh` (including clean/mrproper) so a failed compile cannot continue to `build_image` or package a stale `Image`.
3. Add a separate Android 14 One UI KSU CI job only after the toolchain is pinned and boot-image OS/patch metadata is validated.
4. Run CI and inspect the generated config, Image, DTB/DTBO, ZIP contents and SHA-256 before any device flash.
5. Resume the DTS/TZDEV/TEEGRIS compatibility audit and Linux 5.1 migration after the baseline build is reproducible.
