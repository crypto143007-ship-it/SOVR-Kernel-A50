# Exynos9610 vendor porting audit

Reference: `Vothcito/android_kernel_samsung_exynos9610_a50`, branch `exynos9610-port`.
Reference revision inspected: `ace96fa34c0d8303a23c5518aae751a91274552b` (Linux 5.15).

## Findings

The reference tree contains Samsung's Exynos UFS host driver at
`drivers/scsi/ufs/ufs-exynos.c` and its header
`drivers/scsi/ufs/ufs-exynos.h`. It also contains Samsung UFS PHY code under
`drivers/phy/samsung/`, including `phy-exynos7-ufs.c` and
`phy-samsung-ufs.c`.

The guessed path `drivers/scsi/ufs/ufs-cal-9610.c` does not exist in that
reference revision. Do not create or import a file under that name based only
on the earlier inventory label.

The reference contains Exynos9610 CAL files:
- `drivers/soc/samsung/cal-if/cal-if.c`
- `drivers/soc/samsung/cal-if/exynos9610/cal_data.c`
- `drivers/soc/samsung/cal-if/exynos9610/cmucal-node.c`
- `drivers/soc/samsung/cal-if/exynos9610/pmucal_cpu_exynos9610.h`

The CAL implementation has a broad dependency surface (PMUCAL headers,
ACPM DVFS, ASV, ECT, FVMAP and Samsung power-management interfaces). These
files are Linux 5.15 references, not drop-in Linux 5.1 sources. Port only
after auditing every dependency and API change against this branch.

## Porting gate

1. Resolve the actual Exynos9610 UFS PHY/CAL source set and its DT bindings.
2. Compare UFS host, PHY, clocks, resets, regulators and FMP integration.
3. Port one subsystem at a time and compile it with the target 5.1 tree.
4. Keep vendor features disabled until their drivers and device-tree resources
   are complete.
5. Do not package or flash an image until boot-chain, memory map and hardware
   tests pass.

A successful generic ARM64 Image/DTB/DTBO build is not evidence that UFS,
TEEGRIS, CAL/ACPM or the complete A50 hardware stack is operational.


## CAL/CMUCAL dependency closure refinement (reference branch audit, 2026-11-19)

A directory-level inspection of the Vothcito Linux 5.15 reference branch shows that the Exynos9610 CAL implementation is a subsystem, not a small clock-driver helper. The reference `drivers/soc/samsung/cal-if/` contains the CAL core, CMUCAL core, virtual-clock and power-management layers, ACPM DVFS, ASV/FVMAP support, and shared PMUCAL helpers.

The Exynos9610-specific directory contains these source/data units:

- `cal_data.c`
- `cmucal-node.c/.h`
- `cmucal-qch.c/.h`
- `cmucal-sfr.c/.h`
- `cmucal-vclk.c/.h`
- `cmucal-vclklut.c/.h`
- `clkout_exynos9610.c/.h`
- `acpm_dvfs_exynos9610.h`
- `asv_exynos9610.h`
- PMUCAL data headers for CP, CPU, GNSS, local, P2V map, SHUB and system.

Shared CAL dependencies in the same reference directory include `cal-if.c`, `cmucal.c/.h`, `vclk.c/.h`, `acpm_dvfs.c/.h`, `asv.h`, `fvmap*.c/.h`, `pll_spec.c`, `pmucal_*.c/.h`, `pwrcal*.h`, `ra*.c/.h`, and the CAL Makefile. This list is a source inventory, not a declaration that every unit is needed by the clock provider. Build the minimal transitive dependency graph from actual symbol references and Kconfig selections before porting.

**Port order / gating:**

1. Establish CAL type definitions, register access, SFR mapping and error semantics; keep all runtime users disabled.
2. Port only the CMUCAL node/QCH/VCLK/LUT data and helpers required by the selected clock provider; compile these as isolated objects.
3. Add clockout support only if the A50 DTS and consumers require it.
4. Add ACPM DVFS/ASV/FVMAP only for consumers proven to require those services. ACPM transport and firmware ABI must be independently audited; do not silently stub successful DVFS operations.
5. Port PMUCAL CPU/system/power-domain paths separately, after clock primitives compile and initialization ordering is understood.
6. Enable a provider only after its parent clocks, reset controls, register resources, firmware dependencies and failure paths are complete.

The existing successful CI run is a generic ARM64 upstream Image/DTB smoke build plus a diagnostic universal9610 overlay compile/merge. It does **not** compile the vendor CAL/CMUCAL/ACPM sources and does not prove A50 runtime readiness. The generic `exynos9610-universal9610.dts` overlay uses board_id/board_rev and is not Samsung's stock hw_rev DTBO table; it must remain diagnostic and must not be packaged as the replacement for the stock DTBO partition.


## Exynos9610 pinctrl gap — v5.1 versus Vothcito reference (2026-11-19)

A direct comparison of the target branch and the Vothcito `exynos9610-port` reference found a concrete missing runtime implementation, despite the DTS compiling:

- The target Linux 5.1 `drivers/pinctrl/samsung/pinctrl-exynos-arm64.c` contains only 425 lines and its ARM64 data ends with `exynos7_of_data`. It has no Exynos9610 pin-bank tables and no `exynos9610_of_data`.
- The target `pinctrl-samsung.c` OF match table has no `samsung,exynos9610-pinctrl` entry. Therefore the six Exynos9610 pinctrl controller nodes in `exynos9610.dts` can compile into a DTB but do not bind to an Exynos9610-specific pinctrl data set in this kernel.
- The Vothcito reference adds Exynos9610-specific ALIVE, CMGP, DISPAUD, FSYS, TOP and SHUB bank tables, plus `exynos9610_of_data` and the OF match entry.
- The reference also extends the pin-bank data model with `fltcon_offset` and defines `EXYNOS9_PIN_BANK_EINTN/G/W` macros. The target v5.1 `struct samsung_pin_bank_data` and runtime `struct samsung_pin_bank` do not contain `fltcon_offset`; blindly copying the 5.15 data block will not compile and could misprogram EINT filter registers even if mechanically adapted.

**Porting gate:** first compare the v5.1 and reference pinctrl suspend/resume, EINT filter programming, wakeup IRQ demultiplexing, resource indexing and pin-bank initialization semantics. Port the minimum required structure/macro changes with explicit v5.1 adaptations, then add the Exynos9610 bank tables and OF match entry. Build `CONFIG_PINCTRL_EXYNOS_ARM64=y` and verify all six controller instances resolve the expected resources and bank names. Do not enable this DTS pinctrl set as operational until the driver match and EINT paths are complete.

This is a source/API audit only; no pinctrl code was changed in this phase. The existing DTB/DTBO smoke compile cannot detect this missing runtime binding.

## Latest baseline CI observation (2026-11-19)

Run `44459925266` for commit `12bee58939e07e0bf5736f55af7147c95ce41d5c` was still in progress at the time of inspection. Job `arm64-baseline` completed checkout, dependency installation and ARM64 defconfig; its upstream ARM64 Image/DTB build step was still running. DTBO diagnostic compile, vendor source inventory, readiness audit and artifact publication were pending, and no artifact had yet been published. Do not report this run as passed until GitHub records a completed successful conclusion.


## Pinctrl audit correction — verified against current integration branch (2026-11-19)

The earlier section titled “Exynos9610 pinctrl gap” is superseded by the current branch state and must not be treated as the present blocker.

Direct inspection of the current Linux 5.1 integration branch confirms:

- `drivers/pinctrl/samsung/pinctrl-exynos-arm64.c` now defines Exynos9610 pin-bank tables for ALIVE, CMGP, DISPAUD, FSYS, TOP and SHUB, plus `exynos9610_of_data`.
- `drivers/pinctrl/samsung/pinctrl-samsung.c` contains the `samsung,exynos9610-pinctrl` OF match entry.
- `drivers/pinctrl/samsung/Kconfig` selects `PINCTRL_EXYNOS_ARM64` for ARM64 + ARCH_EXYNOS.
- The successful CI artifact for run `44459925266` contains `CONFIG_PINCTRL_EXYNOS_ARM64=y` and the Exynos9610 Image/DTB build completed.

This closes the previously documented *source-presence and build-configuration* gap. It does not establish electrical correctness, interrupt/wakeup behavior, suspend/resume reliability, or successful pinctrl operation on physical SM-A505F hardware. Those remain runtime validation tasks.

## CI artifact inspection — run 44459925266 (2026-11-19)

The published artifact was downloaded and inspected, not inferred from the workflow log alone. It contains:

- `arch/arm64/boot/Image` (20,492,800 bytes)
- `arch/arm64/boot/dts/exynos/exynos9610.dtb` (128,154 bytes)
- `arch/arm64/boot/dts/exynos/exynos9610-universal9610.dtbo` (80,355 bytes)
- `out/a50-dtbo/exynos9610-universal9610-merged.dtb` (189,422 bytes)
- `exynos9610-smoke.config` with `CONFIG_SOC_EXYNOS9610=y`, `CONFIG_ARCH_EXYNOS=y`, and `CONFIG_PINCTRL_EXYNOS_ARM64=y`.

The base DTB string inventory contains the three expected memory node names `memory@80000000`, `memory@880000000`, and `memory@900000000`, and the Exynos9610 clock compatible. The overlay contains the A50 universal board model string and both `__fixups__` and `__symbols__`; CI successfully applied it to the base DTB with `fdtoverlay`.

These checks prove the DTB and diagnostic overlay were compiled and merged. They do not prove that this overlay is a drop-in replacement for the stock DTBO partition, nor that the merged tree matches every stock bootloader/ROM revision. Continue to preserve the stock DTBO path until a byte-level/table-index and hardware compatibility audit is complete.

The vendor readiness report still identifies major missing Linux 5.1 runtime pieces in the target tree: Samsung Exynos UFS host/FMP, Exynos CAL/CMUCAL/PMUCAL, ACPM, TZDEV and Samsung Mali platform integration. The successful CI run is therefore a platform-DTB and generic kernel build milestone, not a bootable daily-driver release.
