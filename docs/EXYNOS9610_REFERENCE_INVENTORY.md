# Exynos9610 reference-source inventory (Linux 5.15 -> Linux 5.1)

Date: 2026-11-17

## Scope and safety

Reference repository: https://github.com/crypto143007-ship-it/android_kernel_samsung_exynos9610_a50
Reference branch: `exynos9610-port`
Reference commit: `ace96fa34c0d8303a23c5518aae751a91274552b`
Reference kernel version: Linux 5.15.211 (confirmed from its top-level Makefile).

Target repository: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50
Target branch: `linux-5.1-exynos9610-integration`
Target baseline: Linux 5.1.0.

This is an inventory, not a blind copy instruction. Linux 5.15 vendor code is not source-compatible with Linux 5.1 by default. Port each subsystem against Linux 5.1 APIs, Kconfig, regmap/clock/PM frameworks and existing Exynos code. Preserve authorship and GPL notices. Do not alter the original SOVR-Technologies upstream.

## Confirmed critical gap in the target baseline

The successful generic Linux 5.1 baseline currently has only Exynos5433 and Exynos7 DTB targets in `arch/arm64/boot/dts/exynos/Makefile`. It does not include Exynos9610. Its Samsung clock Makefile also lacks `clk-exynos9610.o`; its Samsung SoC Makefile lacks CAL_IF/CMUCAL/PMUCAL integration and Exynos9610 platform data. A generic ARM64 success therefore does not constitute A50 support.

## Reference files to collect and port

### 1. Device tree (first priority)

Directory: `arch/arm64/boot/dts/exynos/`

- `exynos9610.dts` — SoC-level DTS and peripheral topology.
- `exynos9610-universal9610.dts` — A50/UNIVERSAL9610 board overlay; plugin-style DTS.
- `exynos9610-pinctrl.dtsi`
- `exynos9610-rmem.dtsi`
- `exynos9610-pm-domains.dtsi`
- `exynos9610-sysmmu.dtsi`
- `exynos9610-debug.dtsi`
- `exynos9610-mfc.dtsi`
- `exynos9610-camera.dtsi`
- `exynos9610-display-lcd.dtsi`
- `exynos9610-universal9610-triple-camera.dtsi`
- `exynos9610-tmu-sensor-conf.dtsi`
- `exynos9610_battery_data.dtsi`
- `dtb_exynos.cfg` and the directory Makefile (build integration reference only).

Do not use `exynos9610-erd9610.dts` as the A50 board file without proving the board identity. `exynos9610-universal9610.dts` identifies UNIVERSAL9610 A50 Rev 0.1 and is the relevant board reference.

**Critical RAM warning:** the reference `exynos9610.dts` declares three 2-GiB memory banks (6 GiB total): 0x80000000..0xffffffff, 0x880000000..0x8ffffffff, and 0x900000000..0x97fffffff. This is not safe for this SM-A505F 4-GiB device. Rebuild the memory map from the live device tree / bootloader handoff and verified A50 DTBO; never copy these memory nodes unchanged. Reserved-memory entries also need a full overlap/range audit against the live DT and actual firmware carveouts.

### 2. Exynos9610 CAL / PMUCAL / CMUCAL

Directories:
- `drivers/soc/samsung/cal-if/`
- `drivers/soc/samsung/cal-if/exynos9610/`
- `drivers/soc/samsung/exynos9610/`

Reference files include:
- `cal-if.c`, `cmucal.c`, `cmucal-debug.c`
- `pmucal_common.h`, `pmucal_{cp,cpu,gnss,local,powermode,rae,shub,system}.{c,h}`
- `pwrcal-env.h`, `pwrcal-rae.h`, `pwrcal.h`
- Exynos9610 platform data: `cal_data.c`, `cmucal-node.{c,h}`, `cmucal-qch.{c,h}`, `cmucal-sfr.{c,h}`, `cmucal-vclk.{c,h}`, `cmucal-vclklut.{c,h}`, `pmucal_*_exynos9610.h`, `acpm_dvfs_exynos9610.h`, `asv_exynos9610.h`, and `clkout_exynos9610.{c,h}`.

The reference repository has duplicate-looking Exynos9610 platform-data directory entries under `drivers/soc/samsung/exynos9610/` and `drivers/soc/samsung/cal-if/exynos9610/`; inspect the actual Kbuild inclusion path and hashes before choosing one canonical destination.

### 3. Exynos9610 clock controller

- `drivers/clk/samsung/clk-exynos9610.c`
- `drivers/clk/samsung/composite.c`, `composite.h`
- Supporting Samsung clock framework files only where Linux 5.1 lacks compatible equivalents: `clk.c`, `clk.h`, `clk-pll.c`, `clk-pll.h`, `clk-cpu.c`, `clk-cpu.h`.
- `include/dt-bindings/clock/exynos9610.h`

Target 5.1 Kconfig/Makefile currently has no Exynos9610 clock object. Port the minimal compatible delta; do not replace the whole Samsung clock framework wholesale.

### 4. Device-tree binding headers

- `include/dt-bindings/clock/exynos9610.h`
- `include/dt-bindings/power/exynos-power.h`
- `include/dt-bindings/thermal/thermal.h` (compare target version first)
- `include/dt-bindings/ufs/ufs.h` (compare target version first)
- `include/dt-bindings/soc/samsung/debug-snapshot-table.h`
- `include/dt-bindings/soc/samsung/exynos-bcm_dbg.h`
- `include/dt-bindings/soc/samsung/exynos9610-devfreq.h`
- `include/dt-bindings/soc/samsung/exynos9610-dm.h`
- `include/dt-bindings/soc/samsung/exynos9610-seclog.h`
- Other included binding headers identified by preprocessing each DTSI.

### 5. Pinctrl, thermal and PM domains

- Compare `drivers/pinctrl/samsung/pinctrl-exynos-arm64.c`, `pinctrl-exynos.c`, `pinctrl-samsung.c` and their headers; target already has Samsung pinctrl infrastructure, so port only missing compatible changes.
- Compare `drivers/thermal/samsung/exynos_tmu.c` and its Kconfig/Makefile; adapt only if target 5.1 implementation cannot handle the A50 sensor configuration.
- Port Exynos PM-domain CAL integration only after the CAL/PMUCAL dependency is understood. The 5.15 DTS uses Samsung-specific `cal_id` and `need_smc` properties; a generic Linux 5.1 PM-domain driver will not automatically implement them.

### 6. Additional hardware subsystems to inventory after base SoC

Use the A50 DTS references to determine which drivers are actually enabled/required, then compare these target paths: UFS host/PHY, USB/DWC3 and gadget, regulators/PMIC S2MPU09, I2C/HSI2C/SPI/USI, ADC, thermal, devfreq/DSU/MIF/INT, SysMMU/IOMMU, MFC, display/DSIM/DECON/DPP, Mali GPU, camera/FIMC-IS, audio/ABOX, sensor hub, modem, Wi-Fi/Bluetooth. Do not port every driver just because it exists in the reference tree.

## Required validation before any boot image

1. Verify the selected DTBO overlay index and decompile the actual live A50 DTB/DTBO.
2. Reconcile CPU topology, memory banks, reserved memory, secure carveouts, SMC IDs, clocks, regulators and UFS addresses with live hardware.
3. Preprocess and compile the board DTS with Linux 5.1 dtc; resolve missing binding headers and symbols.
4. Build the CAL/CMUCAL/PMUCAL and clock dependencies independently before enabling dependent DT nodes.
5. Produce a config audit showing each required driver built-in or modular and its firmware dependency.
6. Keep the working 4.14 kernel as recovery. No experimental flash until serial/pstore/log capture and a known-good recovery image are available.

## Current decision

The reference repository is a useful Linux 5.15.211 Exynos9610/A50 vendor-source donor and device-tree map. It is not a ready-made Linux 5.1 patchset. The first safe porting unit is the Exynos9610 DTS + binding headers + clock/CAL dependency map, with RAM/reserved-memory corrected for the actual 4-GiB SM-A505F before any device-tree build is considered boot-testable.
