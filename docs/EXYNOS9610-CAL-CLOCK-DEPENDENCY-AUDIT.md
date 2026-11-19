# Exynos9610 CAL / clock integration dependency audit

Date: 2026-11-19
Target: `linux-5.1-exynos9610-integration`
Reference: `Vothcito/android_kernel_samsung_exynos9610_a50` (`exynos9610-port`)

## Findings

The reference provides `drivers/clk/samsung/clk-exynos9610.c` (28,338 bytes), but the target branch does not yet contain it. It is not a standalone clock driver: it includes the Samsung CAL interface and Exynos9610-generated CMUCAL headers.

Confirmed reference files missing from target:

- `include/soc/samsung/cal-if.h`
- `drivers/soc/samsung/exynos9610/cmucal-vclk.h`
- `drivers/soc/samsung/exynos9610/cmucal-node.h`
- `drivers/soc/samsung/exynos9610/cmucal-qch.h`
- `drivers/soc/samsung/exynos9610/clkout_exynos9610.h`
- `drivers/soc/samsung/exynos9610/cal_data.c`
- CAL implementation and generated Exynos9610 tables under `drivers/soc/samsung/cal-if/`

The Exynos9610 clock binding header `include/dt-bindings/clock/exynos9610.h` already exists in the target and matches the reference blob SHA `87f9b98cd72a3217fe5137f38ff9d4046834dc25`.

The target clock Kconfig and Makefile are older/smaller than the reference. They need a controlled Kconfig/Makefile integration after the CAL dependency tree is ported. Do not add `clk-exynos9610.o` alone: it will fail to compile or link without CAL and CMUCAL.

## Pinctrl validation caveat

The imported Exynos9610 bank tables include `fltcon_offset` metadata, but the target runtime `struct samsung_pin_bank` and Samsung bank-data copy path do not carry that field, and the reference runtime driver also continues to calculate EFLTCON addresses from `eint_offset`. Do not claim that the independent filter offset is currently consumed by runtime code. Keep this metadata as reference compatibility only until the Exynos9610 register map proves whether a separate runtime field is needed.

The target pinctrl match is under `CONFIG_PINCTRL_EXYNOS_ARM64`; that symbol is selected by the existing `PINCTRL_EXYNOS` ARM64/ARCH_EXYNOS dependency. No separate build-system object entry is required for the existing `pinctrl-exynos-arm64.o`.

## Next safe implementation sequence

1. Port `cal-if.h` and its required public types/APIs, after checking Linux 5.1 include/API compatibility.
2. Port the minimum shared CAL implementation and the Exynos9610 CMUCAL generated data as a coherent set; preserve source license headers and generated-file provenance.
3. Audit all includes and symbols referenced by `clk-exynos9610.c`; do not omit dependencies simply to make the file appear present.
4. Add the SoC CAL Kconfig/Makefile wiring and the clock Kconfig/Makefile entry together.
5. Compile the CAL objects and Exynos9610 clock provider with the A50 defconfig before enabling the provider in DTS.
6. Validate clock IDs and provider names against the existing A50 DTS; do not change clock assignments without matching hardware evidence.

## Status

This is a dependency audit only. No CAL or clock driver has been copied or enabled and no kernel build is claimed. The SOVR 4.2 boot/DTB/stock-DTBO contract and one-kernel/one-DTB 4 GB/6 GB compatibility requirement remain unchanged.
