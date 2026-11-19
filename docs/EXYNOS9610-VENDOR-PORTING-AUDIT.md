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
