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
