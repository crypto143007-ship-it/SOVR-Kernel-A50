# SOVR-Kernel-A50 Development State

**Project baseline:** SOVR v4.2 / Linux 4.14.357 / Samsung Galaxy A50 (SM-A505F, Exynos 9610)  
**Branch:** `main`  
**State recorded against HEAD:** `9811fd3818f8dd6668a13a643702f4aba2387b76`

## Done / Committed
- Existing repository baseline inspected; no kernel source, configuration, or workflow changes made in this session.
- Confirmed v4.2 release documentation in `README.md` and existing workflows:
  - `.github/workflows/development.yml`
  - `.github/workflows/galaxy-a50.yml`
- Confirmed A50/Exynos9610 device-tree sources exist, including `arch/arm64/boot/dts/exynos/oneui14/exynos9610.dts` and `arch/arm64/boot/dts/exynos/exynos9610-universal9610.dts`.
- Added this state file to establish a persistent project handoff.

## Failed / Do Not Repeat
- Do not restore `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md` to `main`: commit `9811fd3` explicitly reverted its accidental addition.
- Do not treat SOVR 4.0 as the current baseline; current baseline is SOVR 4.2.
- Do not modify the original `SOVR-Technologies/SOVR-Kernel-A50` repository; work only in this fork.

## Active Bug / Current Focus
- Linux 5.1 migration is not yet implemented or validated; current source remains Linux 4.14.357.
- Build-system reproducibility needs audit:
  - `build.sh` selects Neutron and expects `$HOME/toolchains/neutron-clang`, while README documents LLVM/Clang 23.1.5.
  - Existing GitHub Actions workflows use legacy Mint build invocations and need comparison against current `build.sh` options and packaging outputs.
  - Inspect compiler provisioning, build failure propagation, artifact validation, and per-ROM configuration selection before changing CI.
- Early-boot compatibility needs a source-backed audit across the A50 DTS variants and TZDEV/TEEGRIS handoff; do not infer Linux 5.1 compatibility from documentation alone.

## Next Step
- Audit `build.sh`, device database/config fragments, and both workflows end-to-end. Record exact toolchain, option, output, and failure-propagation mismatches; then propose the smallest safe CI/build-system correction without changing the Linux 4.14.357 bootable baseline. After that, continue the Linux 5.1 DTS/early-boot compatibility audit.
