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


## Continuation audit — 2026-11-19 (live fork inspection)

### Branch and PR inventory
- Fork inspected: `crypto143007-ship-it/SOVR-Kernel-A50`; original upstream remains read-only/out of scope.
- Branches returned by GitHub: `main`, `migration/linux-5.1-assessment`, and `linux-5.1-exynos9610-integration`.
- No open pull requests were returned for this fork.
- Main's recent commit search shows `b49265e31c3776fae7c661de4d1a36c17d35d551` as the newest commit at this inspection; the audited-HEAD field above was stale.
- Created isolated working branch `build/llvm-23.1.5-enforcement` from main. Main was not modified.

### Build-script edit safety correction
- The first staged automated edit to `build.sh` expanded the file unexpectedly. It was immediately reverted on the isolated branch.
- Restoration commit: `5c4e7720b06a7a8069af330af1915f6546646e46`.
- Re-fetched the file and verified it is byte-for-byte identical to main's baseline blob `27238dbec68279e6af3b067c9c6251ba9360f9fa`, 32,322 characters / 825 lines.
- No malformed script remains on the branch. No kernel build was launched. Do not rely on the failed edit or claim the LLVM/LLD gate is implemented.
- Next script change must be a small, exact, single-purpose patch, checked by a diff and shell syntax validation before any further update.

### Toolchain source clarification
- The ClangBuiltLinux kernel.org documentation states that its stable prebuilt LLVM toolchains are provided on kernel.org, built from signed `llvmorg-<version>` tags and PGO-optimized using tc-build. It explicitly recommends PATH plus `LLVM=1` for kernel trees older than 5.18, which applies to this Linux 4.14.357 tree.
- The kernel.org index lists `llvm-23.1.5-x86_64.tar.xz` and a matching detached `.tar.sign`; LLVM 23.1.6 is also listed but is not permitted by the project's fixed 23.1.5 requirement.
- This makes the kernel.org 23.1.5 slim archive the official ClangBuiltLinux stable-toolchain candidate, not a rolling Neutron substitute. Still pending: verify the archive's detached signature and signer fingerprint, signed checksum, extracted layout, exact `clang --version` and `ld.lld --version`, host dependencies, and actual Linux 4.14.357 build compatibility. No archive was downloaded or executed in this session.
- Source: https://kernel.org/pub/tools/llvm/ and https://www.kernel.org/doc/html/latest/kbuild/llvm.html.

### Linux 5.1 integration branch — critical A50 memory finding
- The dedicated integration branch is a Linux 5.1.0 source tree and has a generic ARM64/Exynos9610 baseline workflow. Its successful Image/DTB/DTBO smoke artifacts are not a bootable A50 kernel.
- The current `arch/arm64/boot/dts/exynos/exynos9610.dts` declares three 2-GiB memory banks: `memory@80000000`, `memory@880000000`, and `memory@900000000` (6 GiB total).
- The current `exynos9610-universal9610.dts` overlay does not override or remove those memory nodes. The workflow explicitly asserts all three nodes, so the merged diagnostic DTB retains the 6-GiB declaration.
- The earlier live-vs-SOVR DTB audit records the user's SM-A505F live map as four ranges totaling approximately 3.893 GiB: 0x80000000/0x3ab00000, 0xc0000000/0x20000000, 0xe1900000/0x1e700000, and 0x880000000/0x80000000. It explicitly warns against using the 6-GiB SOVR base map for the 4-GiB device.
- This is a P0 device-tree blocker. Do not package or flash the integration branch DTB/DTBO. Before any A50 boot image work, reconcile the exact live DTB, reserved-memory carveouts, bootloader handoff and stock DTBO selection; then make the board-specific 4-GiB memory map authoritative and update CI assertions accordingly.
- The A50 overlay itself is diagnostic only; it is not proven to replace the stock DTBO partition.

### Remaining integration blockers
- Pinctrl Exynos9610 source and Kconfig wiring are present in the integration tree; physical EINT/wakeup/suspend/resume remain untested.
- Samsung Exynos UFS host/PHY/FMP, CAL/CMUCAL/PMUCAL, ACPM, TZDEV/TEEGris and Mali platform integration remain major porting blockers according to the current vendor audit.
- The migration assessment branch remains Linux 4.14.357 source with partial ACPM hardening, not a Linux 5.1 port. Keep it separate from the dedicated upstream v5.1 tree.

### Next steps
1. Verify the official kernel.org ClangBuiltLinux LLVM 23.1.5 archive signature, signer fingerprint and signed checksum; inspect package and runtime dependencies on a disposable runner.
2. Apply a small, reviewed build-script patch on this branch only: select the verified toolchain path, require exact Clang/LLD 23.1.5, and explicitly select `LD=ld.lld` in both config and compile invocations. Do not reintroduce rolling Neutron.
3. Resolve the A50 4-GiB DTB/DTBO memory map and reserved-memory overlap before treating the Linux 5.1 integration branch as a device build.
4. Continue UFS/PHY/FMP and CAL/ACPM/TZDEV dependency closure; compile each subsystem separately before enabling it.
5. Preserve main's known-good SOVR 4.2 / Linux 4.14.357 baseline. No full build, ZIP, flash or boot result is claimed by this audit.


## Continuation update — 2026-11-19 (LLVM 23.1.5 build gate and A50 KSU CI)

### Isolated build branch
- Working branch: `build/llvm-23.1.5-enforcement`.
- Compared with main: 9 commits ahead, 0 behind at this checkpoint. Main remains untouched.
- No pull request was created.

### Pinned toolchain implementation
- Added an explicit `--toolchain llvm_23.1.5` path in `build.sh`.
- The path is supplied through `SOVR_LLVM_TOOLCHAIN_DIR` or defaults to `$HOME/toolchains/llvm-23.1.5`.
- The script now fails closed if either compiler binary is absent or if `clang --version` is not exactly 23.1.5 or `ld.lld --version` is not exactly 23.1.5.
- The matching build path invokes both config and compile make steps with `LLVM=1`, explicit `LD=ld.lld`, `HOSTLD=ld.lld`, and LLVM binutils. Existing legacy toolchain selectors were not removed or silently redirected.
- Official ClangBuiltLinux kernel.org stable archive selected: `llvm-23.1.5-x86_64.tar.xz` (83 MiB).
- Signed SHA-256 entry from kernel.org `sha256sums.asc`: `b69433120ad62420d789f601c58a5472873c724be088c99a70b72fd30ca4af3c`.
- Kernel.org checksum-autosigner primary fingerprint pinned in CI: `B8868C80BA62A1FFFAF5FDA9632D3A06589DA6B1`.
- The CI job imports that full fingerprint from the Ubuntu keyserver, verifies the signed checksum manifest and checks the archive hash before extraction. The extracted binaries are then checked for exact Clang/LLD versions and the AArch64 backend.
- This is the kernel.org stable LLVM distribution documented by ClangBuiltLinux, built from LLVM release tags and PGO-optimized with tc-build. It is not rolling Neutron and does not substitute LLVM 23.1.6.

### KernelSU compatibility correction
- Audited `drivers/kernelsu/Kconfig` and `drivers/kernelsu/Kbuild`: the Kprobes hook option explicitly warns it should not be used below Linux 5.10.
- Confirmed `kernel/reboot.c` already contains the required `ksu_handle_sys_reboot` manual-hook integration.
- Added `CONFIG_KSU_MANUAL_HOOK=y` to the A50 core defconfig so the Linux 4.14.357 build selects the manual hook path instead of the Kprobes hook path.
- CI checks `CONFIG_KSU=y`, `CONFIG_KSU_SUSFS=y`, `CONFIG_KSU_MANUAL_HOOK=y`, and that `CONFIG_KSU_KPROBES_HOOK` is disabled.

### Dedicated Android 14 CI
- Added `.github/workflows/sovr-a50-android14-ksu.yml`, scoped to this isolated branch plus manual dispatch.
- Build target: SM-A505F / Exynos9610 / Android 14 / One UI / SELinux Enforcing / KernelSU + SuSFS.
- Uses the pinned LLVM 23.1.5 toolchain, `BUILD_JOBS=2`, shell syntax validation, and strict pipeline failure handling.
- CI checks `CONFIG_LTO_CLANG=y`, `CONFIG_THINLTO=y`, and the existing O3 optimization symbol. The correct ThinLTO symbol in this tree is `CONFIG_THINLTO`, not `CONFIG_LTO_CLANG_THIN`.
- Artifact validation requires a nonempty boot image, a KSU ZIP containing Image, dtb.img and the AnyKernel installer, plus the final config, package manifest and SHA-256 hashes.
- The build workflow has been committed and its source files re-fetched for verification. A completed GitHub Actions run, successful compile, artifact, install or device boot has **not** yet been observed. Do not mark this build passed until the actual run conclusion and artifacts are inspected.

### Safety boundary and next step
- No Linux 5.1 integration-branch files were changed in this step.
- The 6-GiB Exynos9610 base-DTB memory declaration versus the user's approximately 3.893-GiB live A50 memory map remains a P0 blocker on the Linux 5.1 integration branch. Do not package or flash that branch.
- Next: inspect the new LLVM 23.1.5 CI run and logs; fix any toolchain, Kbuild, KSU, ThinLTO or packaging failure; verify artifact contents and manifest. Only after a clean build should the package be considered for controlled installation testing.


## Final continuation checkpoint — 2026-11-19

- Pinned the exact x86_64 LLVM 23.1.5 archive SHA-256 in the CI workflow in addition to verifying the signed kernel.org checksum manifest. Expected digest: `b69433120ad62420d789f601c58a5472873c724be088c99a70b72fd30ca4af3c`.
- Corrected the CI package naming path so KernelSU builds are labelled `KSU`, not misleadingly `NoRoot`, for both mainline and beta CI package naming.
- Re-fetched the final files from the branch. Current `build.sh`: 857 lines / 34,819 characters; exact LLVM gate present; both config and compile make invocations select LLD explicitly. New workflow: 150 lines; archive hash, signer fingerprint, ThinLTO, KSU manual-hook and package checks present. A50 defconfig retains O3 and ThinLTO and selects the 4.14-compatible KernelSU manual hook.
- Last observed compare before this note: branch was 11 commits ahead and 0 behind main; four files changed: build script, A50 core defconfig, new Android 14 KSU workflow, and DEV_STATE. Main was not modified.
- The commit combined-status endpoint returned no legacy status entries for the latest build-script commit. This is not proof of a successful or failed Actions run; no completed run conclusion or artifact has been inspected. No kernel compilation or boot success is claimed.
- Next action: obtain the actual GitHub Actions run result for `SOVR 4.2 — Galaxy A50 Android 14 One UI KSU`, inspect logs and artifacts, and fix the first concrete failure. Do not merge to main, publish a release, or flash the ZIP until the build and package checks pass and a recovery-backed device test is completed.


### Branch count correction
- Final post-check compare: this branch is **14 commits ahead, 0 behind** main; the same four files are changed. The earlier 11-ahead figure above was from the preceding checkpoint, before the last three documentation/workflow commits.


### Default compiler selection correction
- Changed the build script's default toolchain selector and the `--toolchain` omitted-value fallback to `llvm_23.1.5`. Ordinary builds on this branch now select the pinned compiler without requiring an extra CLI argument.
- The dedicated LLVM 23.1.5 path fails closed if its binaries are absent or either version is wrong; it does not auto-download or fall back to Neutron. Other legacy selectors remain explicit opt-ins, not defaults.
- Latest compare after this change: 16 commits ahead, 0 behind main; changed files remain .github/workflows/sovr-a50-android14-ksu.yml, DEV_STATE.md, arch/arm64/configs/exynos9610-a50_core_defconfig, build.sh. Main remains unchanged.
- CI has not yet produced an observable completed result or artifact in this session. The next engineering step remains reviewing the actual Actions run.


## CI failure diagnosis and correction — 2026-11-19 (20:47 PKT)
- Inspected the latest Android 14 One UI KSU workflow run (run 9, commit e9d0667). The archive download, signed checksum manifest verification, pinned SHA-256 check, extraction, and execution of both compiler binaries succeeded.
- Actual version output is prefixed with `ClangBuiltLinux`: `ClangBuiltLinux clang version 23.1.5` and `ClangBuiltLinux LLD 23.1.5`. The workflow's anchored regular expressions incorrectly expected `clang` / `LLD` at column 1, causing a false failure before build-script validation or kernel compilation.
- Fixed only those two regex anchors in `.github/workflows/sovr-a50-android14-ksu.yml`; they now match the version token anywhere in the vendor-identifying output while still requiring exact 23.1.5.
- Fix commit: `a7e05af95248598d87ef2f5a2d1470288471e2a1` (`ci: accept ClangBuiltLinux version prefixes`). This push triggers a fresh CI run on the isolated branch.
- No kernel compilation, ZIP packaging, artifact validation, or device boot has yet succeeded. Main branch is unchanged. Do not flash or merge until the new run is inspected through build and artifact-validation completion.
- Next: inspect the run triggered by `a7e05af`; if toolchain validation passes, diagnose the first actual Kbuild/config/package failure. Retain the exact Clang/LLD 23.1.5 pin and explicit LLD selection.


## Follow-up: internal build-script version gate — 2026-11-19 (20:48 PKT)
- Static review after correcting the workflow matcher found the same anchored-prefix assumption inside `build.sh`'s pinned toolchain gate: it required the first line to begin exactly with `clang version` and `LLD`, while the verified distribution prints `ClangBuiltLinux clang version` and `ClangBuiltLinux LLD`.
- Corrected both Bash regexes to match the required version token while retaining exact 23.1.5 enforcement. No compiler/version fallback was added.
- Commit: `0effcad12ddc028ed452ac2ffa06c87e4ca7feaf` (`build: accept ClangBuiltLinux version prefixes`). The change triggers another isolated-branch CI run.
- Workflow matcher correction is in `a7e05af`; this second correction is necessary or the build would still stop before make.
- No kernel compilation or package has yet been produced. Main remains unchanged. Await the new CI run and inspect every stage, especially Kconfig resolution, KernelSU manual-hook selection, ThinLTO and package/DTB output.

### CI run 10 diagnosis
- Run 10 (`a7e05af`) passed archive authentication, exact compiler/linker validation in the workflow, and `bash -n build.sh`; it then stopped inside `verify_toolchain()` because the script's own anchored Clang regex rejected the `ClangBuiltLinux` prefix. No make command ran.
- That internal false-negative is corrected in commit `0effcad`; run 11 on that commit is the authoritative validation attempt. It was still queued/in progress at the last poll. Do not interpret run 10 as a kernel compile failure.


## Build Continuation — 2026-11-19 (run 11 investigation)
- Inspected GitHub Actions run 11 for commit `0effcad12ddc028ed452ac2ffa06c87e4ca7feaf`.
- The pinned ClangBuiltLinux LLVM 23.1.5 archive authentication, checksum validation, compiler/linker version checks and `bash -n build.sh` all passed.
- The Android 14 One UI KernelSU build step completed successfully: Kbuild reached `LD vmlinux` and `OBJCOPY arch/arm64/boot/Image`; mkbootimg reported Android OS version `14.0.0`; ZIP packaging completed and emitted `MintBeta-11.A14.OneUI6-Enforcing-KSU_A50.CI.zip`.
- Overall run 11 failed in the subsequent artifact-validation step, not in the build step. Artifact upload was skipped, so no downloadable validation artifact was retained. The old validation script did not print which assertion failed; do not claim the generated config, boot image, ZIP or DTB has passed validation.
- Build log contains repeated `LLVM ERROR: IO failure on output stream: Broken pipe` messages even though make returned success and reached vmlinux/Image. Treat these as an unresolved compiler/logging warning; inspect their origin and confirm output/object integrity in the next run.
- CI package naming is currently branch-sensitive: the isolated branch generated a MintBeta filename although the workflow is titled SOVR 4.2. This is a packaging identity issue to resolve before treating the ZIP as a release candidate.
- Commit `f6ab309e8cb0348d2226a08614e7f5be6d4b1e4b` updates only `.github/workflows/sovr-a50-android14-ksu.yml`: validation now records every individual PASS/FAIL, collects partial config/boot/ZIP diagnostics even after earlier failure, and attempts artifact upload with `if: always()`. This commit is on `build/llvm-23.1.5-enforcement`; `main` remains untouched.
- The new workflow run triggered by `f6ab309` must be inspected for its per-check `artifacts/VALIDATION.txt`, generated config summary, package listing and SHA-256 files. Do not flash or merge based only on the successful build step.
- No device boot test has been run. No Linux 5.1 migration changes were made.

### Next steps
1. Inspect the run triggered by `f6ab309` and identify the exact failed validation assertion from `artifacts/VALIDATION.txt`.
2. Download/review the uploaded package, resolved config, boot image, DTB and checksums if the diagnostics run retains them; independently validate ZIP structure and boot-image metadata.
3. Resolve the branch-sensitive MintBeta/SOVR filename/manifest mismatch without changing release behavior on `main`.
4. Investigate repeated LLVM broken-pipe diagnostics and confirm whether they originate from toolchain output handling, ccache, or build subprocesses; require a clean log or documented benign cause.
5. Audit whether DTBO is required for this A50 packaging path and whether the current installer/package includes the necessary DTB/DTBO assets.
6. Only after these checks pass, consider merging the isolated Android 14 KSU workflow/build changes. Preserve SOVR 4.2 Linux 4.14.357 as the control baseline; resume Linux 5.1 migration separately.


## Branch synchronization check — 2026-11-19
- After the diagnostic workflow commit, compared `build/llvm-23.1.5-enforcement` with `main`: isolated branch is 24 commits ahead and 2 commits behind; merge base is `b49265e31c3776fae7c661de4d1a36c17d35d551`. Current `main` HEAD is `7ed3f5ab8d0e2d35da0354e6079ecc93982d2d74`.
- Do not merge this branch yet. Reconcile the two newer main commits and review the complete diff first; preserve main as source of truth.
- Diagnostic CI run 12 was created for `f6ab309e8cb0348d2226a08614e7f5be6d4b1e4b` (run ID `44592526809`). At this check it was still in progress before dependency installation; no result or artifact is available yet.


## Continuation update — run 12 and SOVR release identity
- Run 12 (`44592526809`, commit `f6ab309`) has passed checkout, dependencies, authenticated LLVM archive/signature/SHA-256, exact Clang/LLD 23.1.5 checks, and `bash -n build.sh`; its kernel compilation step was still running at the last poll. No artifacts were available yet. The connected log endpoint returned NOT_FOUND while the job was active; do not infer a result.
- Re-read the run 11 build log: compilation generated `arch/arm64/boot/dtb_exynos.img`, `dtbo_exynos.img`, and individual A50 DTBO overlays; package step added `dtb.img`. It also printed repeated LLVM broken-pipe diagnostics and two modpost section mismatch warnings. These remain to be investigated; the prior log does not prove they are harmless.
- Root cause of misleading `MintBeta` package naming is confirmed: `build.sh` always assigned `BUILD_KERNEL_BRANCH=${GITHUB_REF##*/}`; any feature branch name was non-empty and entered the generic Mint Beta naming path, bypassing the SOVR release naming path.
- Fixed branch selection to permit an explicit empty override: `BUILD_KERNEL_BRANCH=${SOVR_BUILD_BRANCH-${GITHUB_REF##*/}}`. The dedicated A50 workflow now sets `SOVR_BUILD_BRANCH: ''`, which intentionally selects the existing SOVR v4.2 naming/LOCALVERSION path. Existing workflows without this variable retain their prior branch-based behavior.
- Commits: `56d2081` (explicit SOVR branch override) and `437b432` (set empty override in dedicated A14 workflow). These changes trigger a fresh run; they do not alter `main`.
- New package audit finding: `build_package()` only stages `files_oneui` for Android 11 and `files_fresh` for Android 12/13. For Android 14 it stages neither directory, even though One UI 14 DTS selection explicitly references Fresh 6 / One UI 6. This may omit required installer payload/config assets. Do not blindly copy both directories; inspect their contents and installer logic to establish the correct Android 14 payload before treating the ZIP as installable.
- Next: inspect run 12's validation report/artifacts once complete; audit `mint.sh` and all files under `files_oneui` / `files_fresh` to identify required Android 14 installer payload; verify DTB/DTBO packaging and memory map; check run 13 built from the SOVR naming override. Keep branch isolated and do not flash.


### Android 14 installer payload finding — resolved by source inspection
- Inspected `tools/make/package/mint.sh`: for SDK 34/35/36 (One UI 6+ / Fresh 6), the installer explicitly selects "pure SOVR kernel defaults (EROFS system)" and does not copy any `files_oneui` or `files_fresh` assets. The Android 14 package staging omission is therefore intentional for this installer branch, not a missing-payload defect.
- The `files_oneui` / `files_fresh` payloads are used for older One UI 3 and One UI 4/5 paths respectively. Do not add them to Android 14 without changing installer behavior and a demonstrated requirement.
- The Android 14 package still must be checked for correct Image/DTB, AnyKernel scripts, boot metadata and safe target device handling.
