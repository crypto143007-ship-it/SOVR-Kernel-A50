# Exynos9610 / Galaxy A50 Linux 5.1 compatibility matrix

Status: discovery baseline, 2026-11-17. Target remains Linux v5.1. This file distinguishes directly verified 4.14 source/config references from driver paths that still require tracing. A DTS compatible string is not proof of a bound driver.

## Confirmed top-level platform integration

| Layer | Verified 4.14 source/config location | Exact evidence | v5.1 status | Priority |
|---|---|---|---|---|
| SoC Kconfig | `arch/arm64/Kconfig.platforms` | `config SOC_EXYNOS9610` | Missing in upstream v5.1 | P0 |
| SoC DT build | `arch/arm64/boot/dts/exynos/Makefile` | Builds `exynos9610.dtb` and Universal9610 DTBO | DTS and Makefile entries missing upstream | P0 |
| SoC clock provider | `drivers/clk/samsung/clk-exynos9610.c`; `drivers/clk/samsung/Makefile` | Object selected by `CONFIG_SOC_EXYNOS9610`; DT compatible `samsung,exynos9610-clock` | Driver/object missing upstream v5.1 | P0 |
| CAL/CMUCAL | `drivers/soc/samsung/cal-if/Makefile`; `drivers/soc/samsung/cal-if/exynos9610/` | Exynos9610 `cal_data.o` selected by SoC config | Vendor CAL framework/data absent from upstream v5.1 | P0 |
| TZDEV/TEE | `drivers/misc/tzdev/Makefile`; `drivers/misc/tzdev/` | `CONFIG_TZDEV`, `CONFIG_TZDEV_DEPLOY_TZAR`, Exynos9610-specific compile flags | Vendor TZDEV absent upstream v5.1 | P0 |
| SCSC WLAN/BT | `arch/arm64/configs/exynos9610-a50_core_defconfig` | `CONFIG_SCSC_CORE`, `CONFIG_SCSC_WLAN`, `CONFIG_SCSC_BT`, firmware path `/vendor/etc/wifi` | Driver subtree/API compatibility not yet mapped | P0 |
| UFS + RPMB | `arch/arm64/configs/exynos9610-a50_core_defconfig` | `CONFIG_SCSI_UFSHCD`, `CONFIG_SCSI_UFSHCD_PLATFORM`, `CONFIG_SCSI_UFS_EXYNOS`, `CONFIG_UFS_SRPMB` | Exact vendor host-driver delta not yet mapped | P0 |
| Board DT overlay | `arch/arm64/boot/dts/exynos/exynos9610-universal9610.dts` | A50/Universal9610 board compatible; PMIC, touch, audio and SRPMB nodes | File absent upstream v5.1 | P0 |
| SoC DT | `arch/arm64/boot/dts/exynos/exynos9610.dts` | SoC clock, pinctrl, ACPM, TMU, UFS, display, USB, IOMMU, TEE and SCSC nodes | File absent upstream v5.1 | P0 |
| USB DWC3 | `drivers/usb/dwc3/Makefile` | Generic DWC3 plus Exynos glue selection exists | Must trace exact Samsung glue and PHY implementation/API | P1 |
| GPU | DTS compatible `arm,mali`; defconfig and vendor GPU subtree | Mali Bifrost vendor driver expected | Exact R38P1 source/API contract not yet pinned | P0 |
| Display | SoC DTS compatibles `samsung,exynos9-dpp`, `exynos9-decon`, `exynos9-dsim` | Samsung display pipeline declared | Vendor display driver subtree/API delta not yet mapped | P0 |
| Audio | DTS `samsung,abox`, board RT5665/TFA98xx | ABOX and board codec endpoints declared | Vendor ABOX/ASoC driver mapping pending | P1 |
| Touch | Board DTS `melfas,mms_ts` | Melfas touchscreen endpoint declared | Exact driver path/API mapping pending | P1 |
| Thermal | SoC DTS `samsung,exynos9610-tmu` | TMU node declared | Exact driver/Kconfig/API mapping pending | P0 |
| Pin control | SoC DTS `samsung,exynos9610-pinctrl` | Exynos9610 pinctrl node declared | Exact driver/Kconfig/API mapping pending | P0 |
| ACPM/DVFS | SoC DTS `samsung,exynos-acpm*` | ACPM IPC and DVFS endpoints declared | Exact driver/Kconfig/API mapping pending | P0 |
| IOMMU/SysMMU | SoC DTS `samsung,exynos-iommu-bus` | Exynos IOMMU bus declared | Exact driver/Kconfig/API mapping pending | P0 |

## Defconfig hard gates confirmed

The checked-in core defconfig enables:
- `CONFIG_SOC_EXYNOS9610=y`
- `CONFIG_TZDEV=y`, `CONFIG_TZDEV_DEPLOY_TZAR=y`, `CONFIG_TZDEV_BOOST=y`, `CONFIG_TZDEV_SK_MULTICORE=y`
- SCSC core, WLAN, Bluetooth and FM components
- UFS host, platform host, Exynos UFS, SMU and SRPMB
- These selections must be retained or deliberately replaced only after equivalent A50 hardware behavior is demonstrated.

## Required next source-tracing work

For each row marked pending:
1. Enumerate the actual 4.14 driver source files by searching for the exact DT compatible string and reading each driver's `of_match_table`.
2. Record its Kconfig symbol, Makefile object, included vendor headers, exported symbols and dependent subsystems.
3. Locate the closest upstream v5.1 implementation and diff the relevant APIs (clock provider, pinctrl, thermal, UFS, IOMMU, USB, DRM, ASoC, cfg80211/mac80211 as applicable).
4. Identify all vendor-only dependencies and their owners; do not substitute a superficially similar upstream driver without matching register layout, firmware protocol and DT binding.
5. Add compile-only port status, runtime test status and hardware acceptance status as separate columns. No item becomes "ported" solely because it compiles.

## Port sequencing / acceptance gates

1. **Boot foundation:** ARM64 config, Exynos9610 Kconfig, DTB/DTBO, GIC/timer, clock/CAL, pinctrl, PMU, regulators, interrupt controller and console.
2. **Secure/storage foundation:** TZDEV/TEEGris/TZAR deployment, UFS/FMP/RPMB, crypto and required firmware.
3. **Platform stability:** ACPM/DVFS, thermal, devfreq, suspend/resume, watchdog, IOMMU/SysMMU and DMA.
4. **Daily-driver hardware:** display/Mali, touch, USB, audio, modem interfaces, SCSC Wi-Fi/Bluetooth.
5. **Android integration:** boot image/DTB contract, vendor modules, KernelSU, EROFS, fstab, SELinux and One UI userspace.
6. Require a preserved 4.14 fallback and a tested recovery path before any physical-device trial. Do not flash a partially ported kernel.

## Source anchors

- SOVR 4.14: [SoC Kconfig](arch/arm64/Kconfig.platforms), [Exynos DT Makefile](arch/arm64/boot/dts/exynos/Makefile), [A50 core defconfig](arch/arm64/configs/exynos9610-a50_core_defconfig), [Exynos9610 clock driver](drivers/clk/samsung/clk-exynos9610.c), [CAL-IF Makefile](drivers/soc/samsung/cal-if/Makefile), [TZDEV Makefile](drivers/misc/tzdev/Makefile), [SoC DTS](arch/arm64/boot/dts/exynos/exynos9610.dts), [board DTS](arch/arm64/boot/dts/exynos/exynos9610-universal9610.dts).
- Upstream comparison baseline: [Torvalds Linux v5.1](https://github.com/torvalds/linux/tree/v5.1).

## Safety / status

This is a source-discovery matrix, not a completed port. No kernel source, DTS, Kconfig, defconfig, installer or workflow has been changed by this matrix. No Linux 5.1 compile, device flash or boot test has been performed.
