# Exynos9610 Linux 5.1 Port — Source Provenance and CAL Integration Audit

Date: 2026-11-18
Target: Samsung Galaxy A50 SM-A505F (4 GB RAM)
Working repository: crypto143007-ship-it/SOVR-Kernel-A50
Working branch: migration/linux-5.1-assessment

## 1. Critical version distinction

The current working branch is still a Linux 4.14.357 tree. Its top-level Makefile declares VERSION=4, PATCHLEVEL=14, SUBLEVEL=357.

The separate upstream baseline workflow previously passed with a pinned Linux 5.1 source commit, but that does not change this branch's kernel source version and does not constitute an Exynos9610 Linux 5.1 build.

Vothcito/android_kernel_samsung_exynos9610_a50 is a Linux 5.15.211 tree (top-level Makefile: VERSION=5, PATCHLEVEL=15, SUBLEVEL=211). Its checked-in `arch/arm64/configs/exynos9610-a50_core_defconfig` nevertheless identifies itself as a Linux/arm64 4.14.194 configuration. Treat it as a vendor-source/reference collection, not as proof that its board configuration or CAL stack has already been ported to 5.15, and certainly not as a 5.1-ready drop-in.

## 2. Verified useful Vothcito reference components

The following files exist on Vothcito branch `exynos9610-port`:

- `drivers/clk/samsung/clk-exynos9610.c`
  - blob: `dcd2d2f8c85fa1f741db0beb5d70b7dc21138579`
  - vendor clock provider consumes Samsung CAL headers and VCLK/QCH/clockout tables.
- `drivers/soc/samsung/Makefile`
  - blob: `1dd9fb4ab6ec6d7b93d096e4d8e12e23cc6192dd`
  - includes `cal-if/` through CONFIG_CAL_IF.
- `drivers/soc/samsung/Kconfig`
  - blob: `c77b97aeb5c92a8887761ef66ffe77f7b1bd5a63`
  - defines CAL_IF, CMUCAL, PMUCAL and related Samsung framework options.
- `drivers/soc/samsung/cal-if/Makefile`
  - blob: `00944ace1b772acd0193edf80792dd7b884e4c0a`
  - builds generic CAL/PMUCAL objects and the Exynos9610 `cal_data.o`.
- `drivers/soc/samsung/cal-if/exynos9610/cal_data.c`
  - blob: `fb578d3120abe11723345ad2162b9056cde18e99`
  - is an aggregation translation unit that textually includes multiple generated Exynos9610 .c tables and Samsung PMUCAL headers.
- `drivers/soc/samsung/cal-if/exynos9610/pmucal_cpu_exynos9610.h`
  - blob: `c87f8b4e622bc5946c8594aa1d7f080a2e6fc180`
  - contains SoC-specific CPU power sequences and physical register addresses.
- `arch/arm64/boot/dts/samsung/exynos9610-a50_common.dtsi`
  - blob: `b57f0f4859052ff913375904367f92f248720e70`
- `arch/arm64/boot/dts/samsung/exynos9610-a50_swa_open_00.dts`
  - blob: `140ee8c75c57f7af25c67b02fc18b04cb973bc30`
  - is a Samsung A50 SWA overlay, not a universal ready-to-boot upstream DTB.

## 3. Existing migration-branch state

The migration branch already contains:
- `drivers/clk/samsung/clk-exynos9610.c` (blob `1ecdd4ea5b66601c2a68a1d8eefaf992505b2061`)
- `drivers/soc/samsung/Makefile` with Samsung CAL and ACPM integration entries.
- `drivers/soc/samsung/Kconfig` with vendor Samsung configuration options.
- Samsung A50 and Exynos9610 device-tree material.

The branch clock driver is not byte-identical to the Vothcito reference: the include path and blob SHA differ. Do not overwrite it wholesale. Compare interfaces and dependencies before transplanting any individual change.

## 4. Porting implications

The Exynos9610 clock driver is not self-contained. It includes:
- `<soc/samsung/cal-if.h>`
- generated CMUCAL node, VCLK, QCH and clockout headers
- Samsung composite-clock support

The CAL implementation also has a broad dependency surface:
- CMUCAL and PMUCAL generic interfaces
- Exynos9610 generated clock tables and SFR descriptions
- PMUCAL CPU/local/system sequences
- ACPM DVFS and firmware-facing interfaces
- SoC-specific Kconfig symbols and build ordering

The Vothcito `cal_data.c` includes many source files directly. Copying only the Exynos9610 data directory or adding one Makefile line will not make this stack build. The Kconfig symbols, headers, generic implementations, generated tables, and exact include relationships must be ported as a coherent unit and adapted to Linux 5.1 APIs.

## 5. Safe next sequence

1. Keep the existing Linux 4.14.357 migration branch as a source/reference branch; do not label it a Linux 5.1 kernel.
2. Create a dedicated Linux 5.1 integration branch from the actual pinned upstream v5.1 commit, after ensuring that commit is available in the working repository.
3. Bring up upstream Exynos/ARM64 support and the minimum A50 DTB independently of Samsung vendor CAL.
4. Compare the existing migration-branch clock driver against Vothcito's driver and identify every missing header, symbol, table, and framework dependency.
5. Port a minimal clock-controller registration path first; keep DVFS, CPU hotplug/power sequencing, suspend/resume and ACPM disabled until their prerequisites are ported and tested.
6. Add only the A50-required DT fragments, starting from the actual A505F stock DTB/DTBO and verified RAM/reserved-memory map.
7. Compile with a real Exynos9610 configuration. Generic ARM64 defconfig success is only a toolchain baseline.
8. Do not package or flash until the resulting Image, DTB/DTBO, boot image layout, vendor interface and recovery path have been checked.

## 6. Memory safety constraint

The earlier three-bank DTB interpretation must not be copied as three unconditional 2 GiB banks. The user device is the 4 GB A505F. Establish the physical DRAM ranges from the actual stock DTB/bootloader handoff and reconcile secure/reserved regions before writing the final `memory` node. A DTB declaration cannot create physical RAM.

## 7. Validation boundary

This is a source-provenance and dependency audit, not a compile result. No Exynos9610 Linux 5.1 build, successful boot, DVFS test, thermal test, or battery test is claimed.

Keep the original SOVR-Technologies repository and Vothcito repository read-only. Keep the excluded crypto143007 integration branch out of the main SOVR project.
