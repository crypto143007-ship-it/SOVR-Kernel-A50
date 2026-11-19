# Exynos9610 CAL / clock integration audit — SOVR 4.2 baseline

Date: 2026-11-19
Target: `linux-5.1-exynos9610-integration`
Primary reference: this repository's `main` branch (SOVR 4.2 baseline)
Secondary reference: `Vothcito/android_kernel_samsung_exynos9610_a50`, branch `exynos9610-port`

## Baseline correction

Use the SOVR 4.2 source on this repository's `main` branch as the primary implementation reference. The Vothcito tree is a supplementary Exynos9610 source reference only; it must not override SOVR 4.2 behavior, boot packaging, DTB/DTBO handling, or memory initialization.

Confirmed SOVR 4.2 reference files on `main`:

- `drivers/clk/samsung/clk-exynos9610.c` — blob `1ecdd4ea5b66601c2a68a1d8eefaf992505b2061`
- `drivers/soc/samsung/cal-if/Makefile` — blob `00944ace1b772acd0193edf80792dd7b884e4c0a`
- `drivers/soc/samsung/Kconfig` — blob `1d2a3a8baa33a94d125eb912835452c84c43ed59`
- `include/soc/samsung/cal-if.h` — blob `65fe05a30e4251b0ca9d735ddbb29d7713374ac5`
- `drivers/pinctrl/samsung/pinctrl-exynos-arm64.c` — blob `85a30b5fe024506b8bb6d6f28145a8943fd1b0c8`
- `drivers/pinctrl/samsung/pinctrl-samsung.c` — blob `aa361d951ab9fe051eea504f45476d023a12d90d`

SOVR 4.2 places generated Exynos9610 CAL data under `drivers/soc/samsung/cal-if/exynos9610/`, not `drivers/soc/samsung/exynos9610/`. That directory contains `cal_data.c`, CMUCAL node/QCH/VCLK/SFR/VCLK LUT sources and headers, clock-output definitions, and Exynos9610 PMUCAL tables. Shared CAL implementation is under `drivers/soc/samsung/cal-if/`.

## Integration rules

1. Diff the target Linux 5.1 files against SOVR 4.2 `main` first; port only the compatible changes, preserving Linux 5.1 APIs.
2. Bring CAL shared sources and generated Exynos9610 data as a dependency-complete set. Do not copy only `clk-exynos9610.c`.
3. Keep SOVR 4.2's CAL Kconfig and Makefile relationships; adapt symbols to the target tree rather than introducing duplicate or conflicting configs.
4. Port the SOVR 4.2 clock provider and its binding only after CAL/CMUCAL dependencies compile.
5. Keep DTS clock names/IDs unchanged unless the A50 device tree proves a required correction.
6. Keep the SOVR 4.2 boot flow, stock DTBO, and single shared kernel/DTB memory approach unchanged for 4 GB and 6 GB models.

## Verification caveats

The SOVR 4.2 reference pinctrl file contains the six Exynos9610 controller groups. The integration branch has corresponding earlier commits, but those changes have not yet been validated by a real kernel build. The `fltcon_offset` metadata must not be treated as runtime functionality unless the bank runtime path actually consumes it.

No CAL/clock source copy or build is claimed by this audit. Compile and link checks remain mandatory before any provider is enabled or any boot image is packaged.
