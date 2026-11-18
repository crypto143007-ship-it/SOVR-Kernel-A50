# Vothcito Exynos9610 Clock / CAL Layout and Kbuild Delta

Audit date: 2026-11-18
Reference: `Vothcito/android_kernel_samsung_exynos9610_a50`, branch `exynos9610-port`
Reference HEAD previously observed: `ace96fa34c0d8303a23c5518aae751a91274552b`
Comparison baseline: SOVR 4.14 source in `crypto143007-ship-it/SOVR-Kernel-A50`
Requested destination remains Linux v5.1. Vothcito remains read-only.

## Executive finding

Vothcito's Exynos9610 clock-driver relocation is accompanied by a material Kbuild selection change and a parallel SoC-header layout. It is not a self-contained, verified Linux 5.15 port and must not be copied as a unit into the Linux 5.1 integration.

## Verified path and blob observations

1. Vothcito `drivers/clk/samsung/clk-exynos9610.c` has blob `dcd2d2f8c85fa1f741db0beb5d70b7dc21138579`. Its four Exynos9610 headers are included from `../../soc/samsung/exynos9610/`.
2. The reference has `drivers/soc/samsung/exynos9610/cmucal-vclk.h` (blob `95bed84ad2b46c342f948a431b7c524ada8deb4a`). The same path under `drivers/soc/samsung/cal-if/exynos9610/cmucal-vclk.h` has the same blob. Thus at least this header is duplicated byte-for-byte in two directory layouts.
3. Vothcito `drivers/soc/samsung/exynos9610/cal_data.c` and `drivers/soc/samsung/cal-if/exynos9610/cal_data.c` both resolve to blob `fb578d3120abe11723345ad2162b9056cde18e99`. The CAL Makefile selects `exynos9610/cal_data.o` from within `drivers/soc/samsung/cal-if/`, so the build-selected translation unit is the latter path.
4. Vothcito `drivers/soc/samsung/Makefile` still enters only `cal-if/` via `obj-$(CONFIG_CAL_IF) += cal-if/`; it has no `exynos9610/` subdirectory object rule. The separate `drivers/soc/samsung/exynos9610/` directory is therefore not shown as an independently compiled object directory by this parent Makefile. Its files are used as a header/source-layout mirror by the clock driver's relative includes.
5. Vothcito CAL Makefile retains the vendor CAL/PMUCAL/CMUCAL object graph and builds `exynos9610/cal_data.o` under `CONFIG_SOC_EXYNOS9610`. It also adds `pmucal_powermode.o` under `CONFIG_FLEXPMU`, unlike the earlier SOVR CAL Makefile manifest.
6. Vothcito Samsung clock Makefile places `composite.o clk-exynos9610.o` under `CONFIG_EXYNOS_ARM64_COMMON_CLK`. In SOVR, the custom composite framework and Exynos9610 clock driver are selected through the `CONFIG_COMPOSITE_CLK_SAMSUNG` conditional, with `clk-exynos9610.o` additionally guarded by `CONFIG_SOC_EXYNOS9610`. This is a meaningful selection-scope difference: Vothcito's rule does not visibly gate the Exynos9610 object itself on the SoC symbol at this Makefile line.
7. Vothcito clock Kconfig defines the generic `EXYNOS_ARM64_COMMON_CLK` under `COMMON_CLK_SAMSUNG`; the Vothcito clock Makefile uses that symbol for both the composite implementation and Exynos9610 object. This differs from SOVR's vendor-specific `COMPOSITE_CLK_SAMSUNG` design.

## Engineering interpretation

- The four-header relocation is not enough to establish a port. The clock driver still includes `<soc/samsung/cal-if.h>`, custom `composite.h`, and calls the same vendor CAL initialization path.
- The duplicate SoC-header layout introduces a consistency hazard: a future change could update the CAL-selected copy but leave the clock driver's include copy stale, or vice versa. Before reuse, compare all four headers by blob and ensure the two trees remain identical.
- The changed Kbuild guard may broaden compilation of the Exynos9610-specific driver beyond the intended SoC selection, depending on the exact architecture/configuration graph. Do not transplant this rule without a Linux 5.1 Kconfig design that explicitly selects the object only for Exynos9610 and resolves every dependency.
- The extra FLEXPMU object is a real delta requiring caller, symbol, config and init-order tracing. It must not be enabled merely because it exists in the reference.
- The reference still has not established a successful compile, boot, or hardware test. Its Linux 5.15 version and early-stage status remain separate from the requested Linux 5.1 target.

## Next required checks

1. Compare all four mirrored headers (`cmucal-vclk.h`, `cmucal-node.h`, `cmucal-qch.h`, `clkout_exynos9610.h`) by blob between both Vothcito locations and SOVR's CAL location.
2. Trace `CONFIG_FLEXPMU`, `pmucal_powermode.o`, all callers and required symbols before deciding whether it belongs in the A50 configuration.
3. Build a precise Kconfig truth table for `SOC_EXYNOS9610`, `ARCH_EXYNOS`, `EXYNOS_ARM64_COMMON_CLK`, `COMPOSITE_CLK_SAMSUNG`, and `CAL_IF`; ensure the Exynos9610 clock object cannot be selected for unrelated ARM64 Exynos SoCs.
4. Compare the Vothcito clock provider and all CAL interfaces against pinned upstream Linux v5.1 APIs. Keep the provider disabled until its complete dependency set compiles.
5. Continue the A50 DT compatible-to-driver map and compare the exact board overlay/DTBO contract. Do not infer production A505F compatibility from the reference's Rev 0.1 overlay.

## Safety / change record

- This is a read-only comparative audit.
- No source, Kconfig, Makefile, DTS, defconfig, workflow, installer or release was changed in either SOVR or Vothcito.
- No build, flash, boot or hardware validation is claimed.
- Original `SOVR-Technologies/SOVR-Kernel-A50` remains untouched.


## Follow-up verification — all four mirrored clock headers

A direct blob comparison was completed for all four headers included by the Vothcito clock driver. For every header, the copy under `drivers/soc/samsung/exynos9610/`, the copy under `drivers/soc/samsung/cal-if/exynos9610/`, and the SOVR `cal-if/exynos9610/` copy have identical Git blob IDs:

| Header | Identical blob in all three locations |
|---|---|
| `cmucal-vclk.h` | `95bed84ad2b46c342f948a431b7c524ada8deb4a` |
| `cmucal-node.h` | `81ba3058001177fdcd62f08051f2c2ec30d26a45` |
| `cmucal-qch.h` | `5eb21beb0d7802fa43c8f611163ea67bb268ed64` |
| `clkout_exynos9610.h` | `49abfdf57f42f32b993879283ed608fb1796bbce` |

This confirms that the four-file duplicate directory is currently a byte-identical mirror, not a separately maintained implementation. It does not remove the future drift risk; a Linux 5.1 port should choose one canonical source location and keep any compatibility include path generated or mechanically verified.

A GitHub code-search attempt for `CONFIG_FLEXPMU`, `pmucal_powermode` and `pmucal_powermode_init` returned no indexed matches. This is an index limitation, not proof that the symbol or callers are absent. The FLEXPMU Kconfig definition, call graph, init ordering and object dependencies remain open audit items and must be traced from the actual source tree before enabling the object.
