# Linux 5.1 Exynos9610 A50 Integration State

**Active target:** Linux 5.1.0 kernel baseline for Samsung Galaxy A50 SM-A505F / Exynos 9610 / ARM64.  
**Branch:** `linux-5.1-exynos9610-integration`  
**Priority:** establish a complete, buildable and bootable kernel before adding performance optimizations.  
**Do not use:** SOVR 4.2 / Linux 4.14.357 build workflow or its LLVM 23.1.5 pin as assumptions for this branch.

## Current source audit — 2026-11-20

- Confirmed top-level Makefile reports VERSION=5, PATCHLEVEL=1, SUBLEVEL=0.
- The branch is a Linux 5.1.0 source baseline, not yet a complete A50 board integration: `build.sh`, `README.md`, `DEV_STATE.md`, and the previously assumed `arch/arm64/configs/exynos9610-a50_core_defconfig` path are absent on this branch at the time of audit.
- `arch/arm64/boot/dts/Makefile` lists the Exynos subdirectory; `arch/arm64/boot/dts/exynos/Makefile` contains an `exynos9610.dtb` target, but the expected `exynos9610.dtsi` file could not be fetched at that path. Resolve exact DTS filenames and dependencies before treating DT build as complete.
- Generic UFS core and platform support exist, but the target branch's `drivers/scsi/ufs/Kconfig` and `Makefile` have no `SCSI_UFS_EXYNOS` option/object.
- Target branch's `drivers/phy/samsung/Kconfig` and `Makefile` have no `PHY_SAMSUNG_UFS` option/object.
- Reference repository `Vothcito/android_kernel_samsung_exynos9610_a50` contains an Exynos UFS host implementation (`drivers/scsi/ufs/ufs-exynos.c` and `ufs-exynos.h`) and its Kconfig/Makefile wiring, plus Samsung UFS PHY Kconfig/Makefile wiring. This is a donor reference only; it has not been copied or declared Linux 5.1 compatible.
- The donor UFS host implementation includes Exynos HCI/UniPro register handling, clocks, PHY coordination, link/power-change callbacks and platform-specific setup. A complete port must identify the correct PHY source files and A50-specific compatible strings, clocks, regulators, resets, syscon and DT bindings.
- No source files have been modified in this checkpoint except this state document. No compiler or build environment is available through this GitHub source inspection, so no compile, DT validation, image packaging or boot test is claimed.

## Done / committed
- Created this state document to establish an accurate 5.1-specific continuation record.

## Blockers
1. Locate/restore the exact A50 Exynos9610 DTS/DTSI and a matching 5.1 defconfig.
2. Confirm whether the current 5.1 source is a clean upstream v5.1.0 base or contains additional Samsung vendor changes; record its exact base commit.
3. Port the Exynos UFS host + Samsung UFS PHY as a coherent set, including all dependencies, rather than adding only a Kconfig symbol.
4. Audit essential A50 platform drivers: clock/CMU/CMUCAL, regulators, pinctrl, PMU, thermal, cpufreq/devfreq, Mali, SCSC/Wi-Fi, Bluetooth, sensors, USB, display and storage.
5. Establish exact boot image header, page size, offsets, DTB/DTBO and vendor boot requirements from the working A50 ROM before packaging.

## Next step
- Compare the 5.1 branch's Exynos DTS directory and config directory against the known A50 donor tree. Identify exact missing files and dependency chains, then create a board-integration patch series. Do not attempt a full build until the defconfig, DTS, UFS host and UFS PHY dependencies are all present. Do not change the 4.14 main branch.
