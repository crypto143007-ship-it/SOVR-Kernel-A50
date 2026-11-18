# Exynos9610 Linux 5.1 port map

Status date: 2026-11-18

## Scope and source versions

This is a dependency and compatibility audit for bringing Exynos9610/A50 support into the clean upstream Linux 5.1 integration branch.

| Source | Exact version observed | Role |
|---|---:|---|
| Target integration branch | upstream Linux 5.1.0 | Port destination |
| Vothcito reference | Linux 5.15.211 | Primary missing-driver and DTS reference |
| Original SOVR main | Linux 4.14.357 | Existing known-working vendor implementation reference |
| Samsung stock files | user-provided `boot.img`, `dt.img`, `dtbo.img` | Boot-chain and DT compatibility baseline |

**Critical compatibility rule:** Vothcito is not a Linux 5.1 tree. Its Exynos9610 source is valuable, but it must be ported by dependency and API closure. Do not copy its 5.15 source wholesale into 5.1. Original SOVR is also a 4.14 vendor tree; it is a behavioural and hardware reference, not a drop-in 5.1 patchset.

## Confirmed source inventory in Vothcito `exynos9610-port`

### Architecture selector

- `arch/arm64/Kconfig.platforms`: defines `SOC_EXYNOS9610`, selecting `ARCH_EXYNOS`.
- `arch/arm64/configs/exynos9610-a50_core_defconfig`: enables `SOC_EXYNOS9610`, `ARCH_EXYNOS`, Samsung ARM64 clocks, CAL_IF, CMUCAL, ACPM DVFS, PMUCAL, Exynos PMU and PM domains.
- The target upstream 5.1 branch did not contain the `SOC_EXYNOS9610` selector. The first isolated Kconfig patch now adds the same minimal selector to the target branch. This alone does not add device support.

### Clock controller

- `drivers/clk/samsung/clk-exynos9610.c`
- `drivers/clk/samsung/Makefile` adds `composite.o clk-exynos9610.o` under `CONFIG_EXYNOS_ARM64_COMMON_CLK`.
- `include/dt-bindings/clock/exynos9610.h`
- Driver directly includes Samsung CAL headers: `cal-if.h`, `cmucal-vclk.h`, `cmucal-node.h`, `cmucal-qch.h`, and `clkout_exynos9610.h`. It calls `cal_if_init()` and `cal_clk_setrate()`.
- Therefore the clock driver cannot be enabled independently of a compatible CAL/CMUCAL port and its matching clock IDs and node tables.

### Samsung CAL / PMUCAL

- `drivers/soc/samsung/Kconfig` contains CAL_IF, CMUCAL, PMUCAL and QCH-ignore options.
- `drivers/soc/samsung/Makefile` descends into `cal-if/` under CAL_IF.
- `drivers/soc/samsung/cal-if/Makefile` builds common CAL/PMUCAL objects and `exynos9610/cal_data.o` under `CONFIG_SOC_EXYNOS9610`.
- Exynos9610 data directory contains `cal_data.c`, CMUCAL node/QCH/SFR/VCLK/VCLK LUT tables, clockout data, ACPM DVFS data, ASV data, and PMUCAL CPU/local/system/CP/GNSS/SHUB/p2vmap headers.
- The reference `cal_data.c` textually includes multiple implementation/data files and refers to optional subsystems. Port the selected dependency closure, not the entire feature set by default.

### ACPM and cross-subsystem dependencies

The reference common CAL implementation includes or references:
- `soc/samsung/acpm_ipc_ctrl.h`
- `soc/samsung/ect_parser.h`
- `soc/samsung/exynos-devfreq.h`
- `soc/samsung/tmu.h`
- Samsung debug-snapshot and BCM debug interfaces
- optional CP, GNSS, SHUB and FLEXPMU PMUCAL paths

These are explicit dependency checks for later stages. Do not enable ACPM_DVFS, FLEXPMU, CP/GNSS/SHUB PMUCAL, debug snapshot, or thermal hooks until their provider drivers, headers, Kconfig symbols, and runtime firmware contracts are verified in the 5.1 target.

### Device tree

Reference source files include:
- `arch/arm64/boot/dts/exynos/exynos9610.dts`
- `exynos9610-pinctrl.dtsi`
- `exynos9610-rmem.dtsi`
- `exynos9610-debug.dtsi`
- `exynos9610-sysmmu.dtsi`
- `exynos9610-pm-domains.dtsi`
- camera, MFC and display includes
- A50 board overlay sources under `arch/arm64/boot/dts/samsung/`, including `exynos9610-a50_common.dtsi` and board/revision-specific `.dts` / `.dtsi` files

The A50 common overlay pulls in board-specific modem, LCD, camera, sound, MST and input-booster descriptions. It is not a self-contained generic A50 DTS. Each include and binding must be mapped to the target tree before compilation.

## Target 5.1 work already committed

1. `arch/arm64/Kconfig.platforms`: added:
   ```kconfig
   config SOC_EXYNOS9610
           bool "Samsung Exynos9610"
           select ARCH_EXYNOS
   ```
2. `.github/workflows/arm64-upstream-baseline.yml`: configure stage is being extended to enable `SOC_EXYNOS9610`, run `olddefconfig`, and assert both `CONFIG_SOC_EXYNOS9610=y` and `CONFIG_ARCH_EXYNOS=y` before compiling.
3. The three-bank RAM declaration and Samsung/SOVR DTB/DTBO boot compatibility rules remain documented in `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md`. Do not alter those memory entries as part of the SoC selector patch.

## Port order and acceptance gates

1. **Kconfig selector smoke test:** prove the new selector resolves correctly in upstream 5.1 and still builds generic ARM64. This is not an Exynos9610 driver build.
2. **DTS parsing base:** bring over only the Exynos9610 SoC DTS and required binding headers/includes needed to compile it. Keep the Samsung/SOVR three-bank memory declaration and board overlay contract intact. Do not enable peripherals with missing drivers.
3. **Pinctrl/GPIO and interrupt/timer dependencies:** map each binding and driver to upstream 5.1 APIs and validate DTS phandles.
4. **PM domains and PMU:** port only after power-domain and PMU interfaces match target 5.1.
5. **CAL/CMUCAL and clock provider:** port common interfaces and Exynos9610 data as a unit; first compile with runtime DVFS and optional PMUCAL features disabled if the tree permits a safe reduced configuration.
6. **ACPM and firmware:** only after mailbox/IPCs and firmware protocol compatibility are demonstrated.
7. **A50 board devices:** add board overlay components in dependency order, preserving stock DTBO revision selection.
8. **Full image and runtime:** verify boot, memory reservations, storage, display, touch, sensors, charging, suspend/resume, thermal and stability on real hardware.

## Non-goals for the first integration pass

- No blind copy of the Vothcito 5.15 defconfig.
- No blind import of its 5.15 CAL, clock, ACPM or PMUCAL implementation into 5.1.
- No replacement of Samsung stock DTB/DTBO structure with a generic upstream board tree.
- No fabricated 6 GB-specific RAM layout.
- No claim that the current generic ARM64 Image is bootable on A50.

## Current status

The source audit has identified the main port groups and their dependency boundaries. The first Kconfig selector is a deliberately small source change. Exynos9610 driver, DTB and A50 board support are **not yet integrated**. The next pass is to compile the selector smoke test, then map the DTS include/binding closure before importing hardware nodes.
