# SOVR-Kernel-A50 Development State

**Project baseline:** SOVR v4.2 / Linux 4.14.357 / Samsung Galaxy A50 SM-A505F / Exynos 9610  
**Branch:** `work/sovr42-explicit-lld`  
**Audited HEAD:** `cd5a54d7f6ea9b43348cb77b9a549449bf4dd878`

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


## Toolchain Source Verification Update — 2026-11-19
- Rechecked current fork `main` and its latest commit: `cfe7bfbc8265f6241d5f271414c0fd8179713847`. The current `DEV_STATE.md` audited-HEAD field had lagged behind the actual branch head; refresh it to this commit in the next state update.
- Kernel.org's LLVM toolchain documentation describes these slim toolchains as built from `llvmorg-<version>` tags and PGO-optimized via tc-build, with AArch64 and ARM backends enabled. Its usage instructions explicitly say pre-5.18 kernel trees should use the toolchain on `PATH` with `LLVM=1`; that matches this Linux 4.14.357 build model.
- The official files index currently lists `llvm-23.1.5-x86_64.tar.xz` (83 MiB) and `llvm-23.1.5-x86_64.tar.sign` (228 bytes), dated 2026-11-04. This is a plausible pinned distribution for the required Clang/LLD version, but not yet an approved source for builds.
- Signature format: kernel.org documents that `.tar.sign` signatures are made over the uncompressed `.tar`, so the correct verification pattern is to stream-decompress the `.tar.xz` and pass the resulting tar stream to GPG verification. The corresponding signer identity/fingerprint for this specific LLVM archive still must be established independently; do not assume the generic Linux kernel release keys are the signer.
- Attempted direct download of the signature/checksum files from the current execution container, but outbound DNS/network access is unavailable. The browser index confirms filenames and sizes only; it does not expose the detached signature bytes or signed checksum contents. Therefore archive signature, SHA-256, package layout, exact `clang --version` / `ld.lld --version`, and host runtime dependencies remain **unverified**.
- Re-fetched `.github/workflows/development.yml` and `.github/workflows/galaxy-a50.yml`: they still build only Android 11/12 variants, do not provision a pinned LLVM 23.1.5 toolchain, and do not build Android 14 One UI KSU. The README's A14 KSU CLI is `./build.sh -d a50 -a 14 -v oneui -k`; the previously noted long-form invocation is supported by the parser, but short flags match the README's documented build path.
- No source code, build script, or workflow was changed. No archive was downloaded, no signature/checksum verified, no compiler executed, and no kernel build/package/boot test was run.
- **Next:** use a disposable GitHub Actions runner on a dedicated audit branch to fetch the exact archive and signature, establish and pin the signer fingerprint, verify the uncompressed tar signature and signed SHA-256 metadata, inspect archive contents, then execute and record exact Clang/LLD version outputs and required shared libraries. Only after that should provisioning be integrated and the A14 One UI KSU CI job added. Do not alter `main` build behavior or claim a successful build before these checks pass.

## Build Continuation — 2026-11-19 (18:39 PKT)
- Revalidated live main HEAD: latest commit is `cfe7bfbc8265f6241d5f271414c0fd8179713847`; current `build.sh` is the 825-line restored baseline (blob `27238dbec68279e6af3b067c9c6251ba9360f9fa`).
- Confirmed `build.sh` defaults to `BUILD_PREF_COMPILER_VERSION='neutron'`, and `verify_toolchain()` requires `$HOME/toolchains/neutron-clang` to exist. It does not check that Clang and LLD are 23.1.5.
- **New build blocker found:** for the Neutron/Clang branch, `build_kernel()` invokes make with Clang and LLVM binutils but does not explicitly pass `LD=ld.lld`. The current path therefore does not prove that LLD 23.1.5 is actually used. The RUI branch explicitly sets `LD=ld.lld`, but it is not the configured default.
- The existing `.github/workflows/development.yml` uses `--magisk` and Android 11/12; it does not provide the requested Android 14 One UI KernelSU build. Its `workflow_dispatch` trigger exists, but the connected GitHub integration exposes no workflow-dispatch or workflow-run listing action, so a run cannot be initiated or monitored from this session.
- Kernel.org currently lists `llvm-23.1.5-x86_64.tar.xz` (83 MiB) and a detached `.tar.sign`, but this is a kernel.org LLVM build, not yet verified as the requested ClangBuiltLinux distribution. Do not silently substitute it or describe it as ClangBuiltLinux. LLVM 23.1.6 is newer but remains outside the specified 23.1.5 contract.
- No source changes, toolchain installation, build, ZIP packaging, or boot test were performed in this continuation. Main branch remains unchanged except this handoff note.
- Next safe implementation: on a dedicated branch, add an exact Clang/LLD 23.1.5 verification after PATH setup, pass `LD=ld.lld` explicitly in both configuration and compile make invocations, then add an Android 14 One UI KSU workflow that provisions the verified ClangBuiltLinux distribution from a pinned immutable source/checksum. Run CI and inspect logs/artifacts before merging.


## Toolchain Investigation Correction — 2026-11-19 (20:31 PKT)
- Rechecked official Linux kernel LLVM documentation: it explicitly recommends the prebuilt stable LLVM toolchains hosted on kernel.org for kernel builds, and links the ClangBuiltLinux `tc-build` project as the toolchain build system. The kernel.org slim toolchains are built from signed `llvmorg-<version>` tags and PGO-optimized with tc-build; they are therefore an official ClangBuiltLinux/kernel-build toolchain path, not an unrelated generic LLVM package. This corrects the earlier overly cautious wording that treated kernel.org as potentially outside the requested ClangBuiltLinux distribution.
- Confirmed the official kernel.org files index lists `llvm-23.1.5-x86_64.tar.xz` (83 MiB), matching `.tar.sign` (228 bytes), and `sha256sums.asc`. LLVM 23.1.6 is also listed, but the SOVR contract remains exactly 23.1.5.
- Confirmed kernel.org's LLVM toolchain instructions require PATH + `LLVM=1` for kernels older than 5.18; this is compatible with SOVR's Linux 4.14.357 make invocation model. Published host dependency baseline is glibc 2.28+ with libgcc, libstdc++, ICU, libxml2, xz/lzma, zlib and zstd.
- Confirmed ClangBuiltLinux `tc-build` repository HEAD at audit time: `6d56f5e32d7a718bc3a63156e66fb036dfc550bf` (GitHub reports the commit signature as verified). Its `build-llvm.py` supports explicit LLVM tag selection via `--ref`, ThinLTO via `--lto thin`, and kernel-focused distribution profiles; this is a source-build fallback if the official binary's signature cannot be safely pinned.
- Remaining verification blocker: this session cannot download the archive/signature bytes or execute GPG/compiler binaries. The archive's actual signer fingerprint, detached signature, signed SHA-256, archive layout, exact `clang --version` and `ld.lld --version`, and runtime library resolution are still unverified. Do not add a checksum or signer fingerprint by guesswork, and do not change the active toolchain selector yet.
- Revalidated SOVR fork main HEAD before this documentation update: `b49265e31c3776fae7c661de4d1a36c17d35d551`. `build.sh` still defaults to Neutron, does not verify exact 23.1.5, and does not explicitly select `LD=ld.lld` in the Neutron path. Existing workflows still lack Android 14 One UI KSU.
- No kernel source, build script or workflow changed. No compile, ZIP package, or device boot test was run.
- **Next:** run a disposable verification job against the kernel.org 23.1.5 archive: obtain Nathan Chancellor's kernel.org WKD key, record and pin its independently checked fingerprint, verify the uncompressed tar signature and signed SHA-256, inspect the extracted toolchain, assert exact Clang/LLD versions and host dependencies, then stage a dedicated branch patch that selects this pinned toolchain and passes `LD=ld.lld` explicitly. Add the Android 14 One UI KSU job only after this contract passes.


## Work Branch Update — 2026-11-19
- Created isolated branch `work/sovr42-explicit-lld` from main HEAD `7ed3f5ab8d0e2d35da0354e6079ecc93982d2d74`; main was not modified.
- Updated only the Neutron/Clang build branch in `build.sh`: both defconfig and compile make invocations now pass `LD=ld.lld LLVM=1` explicitly, alongside the existing LLVM binutils. This makes linker selection explicit but does **not** prove the selected executable is LLD 23.1.5; exact binary validation remains required.
- Change commit: `8a8cce0836c1088e5f61c0e0b685472ccc6e85fe`. Re-fetched the file: still 825 lines / 32,356 characters; confirmed both Neutron make invocations include the new flags. The existing `rui` path already explicitly used `LD=ld.lld`.
- Additional packaging blocker found from recursive repository tree: `tools/make/package` contains only `files_aosp`, `files_fresh`, and `files_oneui`; there is no `files_oneui14` directory. In `build_package()`, One UI copies `files_oneui` for Android 11 and `files_fresh` only for Android 12 or 13. Android 14 copies neither set, so an A14 One UI ZIP would omit these variant-specific installer payloads. Do **not** silently assume the A12/13 Fresh payload is safe for One UI 14. Audit its init service, fstab and vendor assumptions, then add a deliberate A14 payload mapping only after compatibility review.
- Build verification not run: this connector does not provide a shell/runner, and no CI run has been launched. No compiler, image, ZIP, or boot result is claimed.
- Next: review `files_fresh/system/etc/init/init.fresh.perf.rc` and A14 One UI vendor/init/fstab expectations; separately verify toolchain provenance/version; then add a dedicated A14 KSU workflow on this branch. Keep main untouched pending tests and review.

- Follow-up compatibility review of `files_fresh/system/etc/init/init.fresh.perf.rc`: it applies many runtime writes to Mali sysfs, CPU policy schedutil/energy_adaptive nodes, MMC CRC, `/sys/block/sda`, MGLRU, blkio and cgroup uclamp/stune nodes. The A50 vendor's actual Android 14 init/cgroup/sysfs layout has not been proven to expose all these paths. This file is **not** safe to copy into the A14 One UI ZIP solely because its property label says Fresh Performance Kit 14.2.5.2. Keep the A14 payload gap open until every write is checked against the target vendor and kernel interfaces; consider guarded init actions only after compatibility evidence.
- `files_oneui/system/etc/init/init.mint.rc` is an older One UI payload that handles RAM Plus writeback and network tuning, but its Android 14 compatibility also remains unproven. The existing `files_oneui/vendor/etc/fstab.sqzr` configures 4 GiB ZRAM with 1 GiB backing, which should not be copied blindly over the user's actual ROM fstab.


## Continuation Audit — 2026-11-19 (latest)
- Re-fetched the current experimental branch and confirmed HEAD `8a8cce0836c1088e5f61c0e0b685472ccc6e85fe` (`work/sovr42-explicit-lld`) is three commits ahead of `main`, with no divergence. The branch is isolated; `main` was not changed.
- Reviewed commit `8a8cce0`: the two LLVM/Neutron make invocations now explicitly pass `LD=ld.lld LLVM=1`. This fixes linker selection in those build commands, but it does **not** pin or prove that the resolved `clang` and `ld.lld` are version 23.1.5.
- Reconfirmed the A50 device DB still sets legacy `PLATFORM_VERSION=12.0.0` and `PLATFORM_PATCH_LEVEL=2022-09`; `build.sh` overrides only OS version using selected Android target. Do not change patch level without a verified ROM/vendor policy.
- Reconfirmed Android 14 One UI KSU path: `--ksu` injects KSU/SuSFS config and One UI 14 DTB selection is present. Existing workflows remain Android 11/12; no connected action can dispatch a new workflow in this session.
- Fresh official kernel.org index confirms `llvm-23.1.5-x86_64.tar.xz` exists (83 MiB, dated 2026-11-04) and the official `sha256sums.asc` lists SHA-256 `b69433120ad62420d789f601c58a5472873c724be088c99a70b72fd30ca4af3c`. The checksum file is PGP signed, but the signer identity/fingerprint and detached archive signature verification have **not** been established in this session. Treat the archive as a candidate only; do not provision it yet.
- LLVM 23.1.6 is now also listed, but the user's fixed project requirement remains Clang/LLD 23.1.5; do not silently upgrade.
- No source code, kernel config, workflow, or toolchain files were changed in this continuation. No archive was downloaded or cryptographically verified; no compiler was executed; no kernel compile, ZIP package, CI run, or device boot test occurred.
- **Next:** establish the PGP signer fingerprint for kernel.org's signed checksum file and/or archive signature, verify the 23.1.5 archive on a disposable runner, inspect its layout and runtime dependencies, then add a strict compiler+linker version gate and pinned provisioning on a dedicated branch. Only after that add the Android 14 One UI KSU enforcing CI job and inspect all build artifacts before flash.


## Build Gate Update — 2026-11-19 (23:32 PKT)
- Re-audited branch head before this change: `b68a83d4db59b62ea3f25eb89f9ea3b6a1fa38f5`; `main` remains the common ancestor and is not modified.
- Updated `build.sh` on `work/sovr42-explicit-lld` to require both `clang --version` and `ld.lld --version` to match exactly 23.1.5 before continuing. The check is unconditional, so alternate `--toolchain` selections cannot bypass the SOVR toolchain contract. It fails closed when either executable is missing, exits unsuccessfully, or reports another version. Both version outputs are captured before matching; no version-output pipe is truncated with `head`.
- Explicit `LD=ld.lld LLVM=1` remains in both Neutron defconfig and compile make invocations. The version gate now checks that the resolved PATH executables satisfy the documented Clang/LLD pair. It does not provision the compiler and does not itself validate ThinLTO code generation.
- Build script update commit: `140fcdd9f182a24b9ede0ae4976149824b42ce17`; blob `eebb7eb044028996ed5660858b144cfadfb14a6c`; re-fetched file is 848 lines / 33,449 characters and the exact version gate is present. **Shell syntax and runtime tests have not been run** because no shell runner is available through the connected GitHub integration. Do not treat this as tested or compiled.
- Corrected the earlier A14 packaging concern: `build_package()` copies no extra One UI payload for Android 14, but `tools/make/package/mint.sh` explicitly detects SDK 34/35/36 and selects “pure SOVR kernel defaults (EROFS system)” without copying `files_fresh` or `files_oneui`. Therefore the absence of an A14-specific payload directory is not by itself a packaging defect. Keep the Android 12/13 Fresh performance init script and One UI 3 fstab/RAM Plus payload out of A14 packages; their sysfs, cgroup and swap assumptions are not established for the target ROM.
- The active build remains blocked until a trusted, exact ClangBuiltLinux 23.1.5 / LLD 23.1.5 toolchain is installed at the expected path. No toolchain archive was provisioned, no compiler executed, no CI workflow was dispatched, and no kernel Image/DTB/DTBO/ZIP was built or boot-tested.
- **Next:** authenticate and provision the pinned LLVM 23.1.5 toolchain; then run `bash -n build.sh`, test the version gate with matching and mismatching mock executables, and execute the A50 Android 14 One UI KSU build. Validate generated config, Image, DTB/DTBO, ZIP file list and checksums before considering flash.


## Build Script Audit Fix — 2026-11-20
- Audited all pipeline sites in `build.sh` after the script-wide `set -o pipefail` addition.
- Found one latent interaction in the Magisk packaging helper: `tr ... /dev/urandom | head -c 16` can cause the producer to receive SIGPIPE when `head` exits, leaving a nonzero pipeline status under `pipefail`.
- Replaced that unbounded producer pipeline with a finite 8-byte read using `od -An -N8 -tx1 /dev/urandom | tr -d ' \\n'`, plus strict 16-hex-character validation and an explicit error return. This preserves the existing random-seed format and avoids changing kernel configuration or runtime tuning.
- Commit: `eab3233ca8339b7b711f731d3a7c93a8da6a22db`; new `build.sh` blob: `9553a67ac9ccfa211d46be141a1150395c2ef8af`. Re-fetched the file and verified the replacement block.
- Not yet run: `bash -n`, execution with `/dev/urandom` mocks, full build, packaging, or device test. No compile success is claimed.
- Next: add/run automated shell regression tests for the seed helper and exact compiler/linker gate on a runner; then verify and provision the immutable ClangBuiltLinux 23.1.5 toolchain before A14 One UI KSU CI.


## Automated Build-Script Validation CI — 2026-11-20
- Added `.github/workflows/sovr42-build-script-validation.yml` on the isolated work branch. It runs on branch pushes affecting `build.sh`/the workflow, pull requests, and manual dispatch.
- The job checks `bash -n build.sh`, asserts the exact Clang 23.1.5 / LLD 23.1.5 gate and explicit `LD=ld.lld LLVM=1` make arguments, exercises the finite random-seed formatting pipeline, and checks stale-Image removal/compile-abort guards.
- Workflow commits: `2b0fb56bb3cb78349c9f8cdfa18f895f9bdfea12` (initial workflow), `55e50ba25b848b45d208e480148fda150d490fba` (corrected regex/trim escaping). Re-fetched and inspected the final workflow content.
- The workflow has been committed but its Actions run has not yet been observed. Static content inspection is not a substitute for a passing CI run. No kernel build was triggered.
- Next: inspect the first Actions run and fix any validation failures; only then continue the pinned-toolchain provisioning and A14 One UI KSU build job.


## Validation Workflow Review — 2026-11-20 (06:44 PKT)
- Rechecked live branch against current `main`: experimental branch is 13 commits ahead and 0 behind; `main` HEAD is `7ed3f5ab8d0e2d35da0354e6079ecc93982d2d74`. No merge performed.
- Found a test defect in the validation workflow's seed smoke test: the `tr -d` character set was over-escaped, so it would remove literal backslash/`n` rather than a newline. Corrected the workflow to assert the exact production command and run the smoke test with the proper newline escape.
- Workflow correction commit: `088f9594ad1f02eb2ed98a615d793d819c5c2c6d`; workflow blob `ffe54287ec0829a22dd18feec33b63ff3b57448a`.
- Re-fetched and inspected branch files. The validation workflow still has no observed Actions run/status; the GitHub connector exposes no workflow-run listing or dispatch action. The current main commit has no reported status checks through the connected status endpoint (empty statuses), which is not proof of a passing build.
- Next: run the workflow in GitHub Actions and inspect the result; then perform signed LLVM 23.1.5 archive verification and runtime checks before adding toolchain provisioning or the Android 14 One UI KSU build job. Do not merge or claim kernel build success until artifacts are validated.


## LLVM 23.1.5 Provisioning Research — 2026-11-20
- Rechecked the kernel.org LLVM files index: the exact x86_64 archive `llvm-23.1.5-x86_64.tar.xz` is published (83 MiB), with a matching `llvm-23.1.5-x86_64.tar.sign` (228 bytes). The index also lists 23.1.6, but SOVR's required version remains exactly 23.1.5; do not silently upgrade.
- Official kernel.org signature guidance states that these detached `.tar.sign` signatures are made over the uncompressed `.tar` stream. Verification should therefore use `xz -cd llvm-23.1.5-x86_64.tar.xz | gpg --verify llvm-23.1.5-x86_64.tar.sign -` (or decompress to `.tar` then verify). Kernel.org documents WKD key retrieval as `gpg --locate-keys <developer>@kernel.org` and recommends independently validating the key via its web of trust/TOFU.
- Sources reviewed: kernel.org LLVM files index and kernel.org signature instructions. This confirms availability and verification procedure only; it does not establish the signer fingerprint or validate the archive bytes/signature in this session.
- Outstanding security gate: retrieve the archive, detached signature, and signer public key on a disposable runner; record the complete fingerprint from the key material and independently verify it against the developer's published identity before accepting the signature. Do not pin an unverified fingerprint or embed a guessed SHA-256.
- No toolchain archive has been downloaded or installed, and no compiler version command, runtime-library check, kernel compile, package build, or device boot test has been run. Main remains untouched; experimental branch remains isolated.
