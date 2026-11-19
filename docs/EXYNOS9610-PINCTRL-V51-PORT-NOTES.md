# Exynos9610 pinctrl Linux 5.1 port notes

Date: 2026-11-19

Target: `crypto143007-ship-it/SOVR-Kernel-A50`, branch
`linux-5.1-exynos9610-integration`, pinned upstream Linux v5.1 base.

Reference (read-only): `Vothcito/android_kernel_samsung_exynos9610_a50`,
branch `exynos9610-port`. This is a Linux 5.15-era reference and is not
copied wholesale.

## Confirmed source differences

The v5.1 `drivers/pinctrl/samsung/pinctrl-samsung.h` defines
`struct samsung_pin_bank_data` with `type`, `pctl_offset`,
`pctl_res_idx`, `nr_pins`, `eint_func`, `eint_type`,
`eint_mask`, `eint_offset`, and `name`. It has no
`fltcon_offset` member.

The reference header adds `u32 fltcon_offset` to the init-time bank
description. Its `EXYNOS9_PIN_BANK_EINTG` and
`EXYNOS9_PIN_BANK_EINTW` macros take six arguments and populate both
`eint_offset` and `fltcon_offset`. Therefore the reference Exynos9610
bank tables cannot be pasted into v5.1 unchanged. The port must preserve
the distinct EINT and filter-control offsets; treating them as one offset
would silently target the wrong registers.

The reference ARM64 pinctrl data defines six controller instances:
ALIVE, CMGP, DISPAUD, FSYS, TOP, and SHUB. It supplies the Exynos9610
bank tables and `exynos9610_of_data`. The target v5.1 ARM64 file has
Exynos5433 and Exynos7 data only, and its Samsung pinctrl OF match table
does not currently bind `samsung,exynos9610-pinctrl`.

## Porting decisions

1. Keep the six controller datasets separate and preserve their exact bank
   order, pin counts, register offsets, EINT offsets, and filter offsets
   from the reference. Cross-check each controller's resource order against
   the target Exynos9610 DTS before enabling it.
2. Do not add `fltcon_offset` as a passive field only. Trace every reference
   read/write site that consumes it (EINT filter programming), then port
   that behavior to the v5.1 EINT implementation with bounds checks against
   the mapped resource size.
3. Audit v5.1 versus reference IRQ setup, wakeup IRQ demultiplexing,
   resource indexing, suspend/resume, and pin-bank initialization before
   enabling the OF match. The reference controller callbacks differ by
   instance; retain only callbacks supported by the A50 DTS/resources.
4. Add the OF match only after the data model, EINT filter path, and six
   controller resources compile together.
5. Build with `CONFIG_PINCTRL_EXYNOS_ARM64=y`; inspect probe-time resource
   mapping and bank names for all six instances. A DTB-only build cannot
   validate this runtime binding.

## Current status

This is a source/API audit note only. No pinctrl C/header/Kconfig/Makefile
code was changed and no device kernel build or hardware test is claimed.
The next implementation unit is the minimal v5.1 data-model plus EINT
filter-control adaptation, followed by the six bank tables and OF match.
Keep the feature disabled until that unit compiles and its resource offsets
are validated. Do not flash intermediate artifacts.
