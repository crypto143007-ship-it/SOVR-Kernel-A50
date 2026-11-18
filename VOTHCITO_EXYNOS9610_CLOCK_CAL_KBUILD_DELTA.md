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


## Follow-up verification — FLEXPMU implementation and enablement risk

Reference source inspected directly at `Vothcito/android_kernel_samsung_exynos9610_a50:exynos9610-port`:

- `drivers/soc/samsung/cal-if/Makefile` builds `pmucal_powermode.o` when `CONFIG_FLEXPMU` is set.
- `drivers/soc/samsung/cal-if/pmucal_powermode.c` implements `pmucal_powermode_hint()`, `pmucal_powermode_hint_clear()` and `pmucal_cpuinform_init()`.
- `pmucal_system.c` calls the hint functions around system powerdown and early wakeup when FLEXPMU is enabled.
- `pmucal_cpu.c` calls the hint functions on CPU and cluster enable/disable paths.
- `cal-if.c` adds a spinlock around CPU/cluster CAL operations when FLEXPMU is enabled and calls `pmucal_cpuinform_init()` after PMUCAL CPU initialization.
- The hint implementation reads MPIDR_EL1, converts affinity fields to a linear physical CPU index, then indexes `pmucal_cpuinform_list[phycpu]` without a visible bounds check in this function. Its correctness depends on the CPU-inform table covering every possible computed index and on the table having been initialized successfully.
- `pmucal_cpuinform_init()` resolves each CPU-inform physical base address through the PMUCAL physical-to-virtual list and fails with `-ENOENT` if an entry is absent. That means enabling FLEXPMU changes a real initialization failure path, not just optional logging or tuning.

### Kconfig finding — not yet proven selectable

The inspected Vothcito `drivers/soc/samsung/Kconfig` defines `CAL_IF`, `CMUCAL` and `PMUCAL`, but the inspected file does not define `FLEXPMU`. The SOVR `drivers/soc/samsung/Kconfig` inspected on `main` likewise has no `FLEXPMU` definition. GitHub indexed code search returned no matches for `FLEXPMU`, but search-index absence is not proof that no other Kconfig source defines it.

Therefore the correct status is **unresolved Kconfig provenance**. Do not set `CONFIG_FLEXPMU=y` in the A50 defconfig or port the object until a repository-wide Kconfig/source scan identifies the symbol definition (or confirms it is undefined). If it is truly undefined, the Makefile entry is dead conditional code under normal Kconfig generation and the guarded C paths will not be compiled.

### Linux 5.1 port decision

Do not bring FLEXPMU into the first bootable A50 Linux 5.1 milestone. First port the minimum CAL/PMUCAL functionality needed for CPU/cluster and system power management with FLEXPMU disabled. Only consider FLEXPMU as a later, separately reviewed feature after:
1. symbol definition and selection dependencies are located;
2. CPU-inform table dimensions are proven against A50 MPIDR topology;
3. every CPU-inform PA is present in the PMUCAL PA-to-VA table;
4. spinlock context and hint register ordering are reviewed against the A50 suspend/hotplug call paths; and
5. the non-FLEXPMU baseline boots and passes suspend/resume and CPU hotplug tests.

This is a source-level risk assessment only; no hardware validation is claimed.


## Correction and deeper source verification — FLEXPMU / PMUCAL

This section supersedes any earlier wording that implied FLEXPMU is an enabled, selectable feature in the inspected Vothcito branch.

### Kconfig and build truth

The complete inspected `drivers/soc/samsung/Kconfig` (114 lines) defines `CAL_IF`, `CMUCAL`, `PMUCAL` and unrelated Samsung SoC options, but contains no `FLEXPMU` symbol. The inspected `drivers/soc/samsung/cal-if/Makefile` has:

- `obj-y += cal-if.o`
- `obj-$(CONFIG_PMUCAL) += pmucal_system.o pmucal_local.o pmucal_cpu.o pmucal_rae.o`
- `obj-$(CONFIG_FLEXPMU) += pmucal_powermode.o`
- `obj-$(CONFIG_SOC_EXYNOS9610) += exynos9610/cal_data.o`

The inspected `pmucal_system.c`, `pmucal_cpu.c`, `cal-if.c` and `pmucal_powermode.h` guard FLEXPMU-specific declarations/calls with `#ifdef CONFIG_FLEXPMU`, or provide no-op inline stubs when it is not defined. Therefore, **unless a different included Kconfig file defines FLEXPMU, the reference branch's FLEXPMU-specific code is not selected by normal Kconfig configuration**. The symbol's repository-wide provenance remains unverified; the absence in this one complete Kconfig file is now directly confirmed.

### Corrected CAL data path

There is no `drivers/soc/samsung/cal-if/exynos9610/Makefile` in the inspected reference. The actual selection is the root `drivers/soc/samsung/cal-if/Makefile` rule for `exynos9610/cal_data.o`. That translation unit includes the Exynos9610 PMUCAL headers and CMUCAL data C fragments. The earlier shorthand describing an Exynos9610 subdirectory Makefile should not be relied on.

### A50 topology facts from the reference data

- `pmucal_cpu_exynos9610.h` declares `pmucal_cpu_list_size = 8` and `pmucal_cluster_list_size = 2`.
- `pmucal_p2vmap_exynos9610.h` declares `pmucal_p2v_list_size = 58`.
- The PMUCAL CPU-inform table itself was not located in the inspected Exynos9610 headers or by the available repository code-search index. Its existence, size, CPU numbering and register addresses are therefore **not verified** by this audit. Do not infer that 8 CPU entries means the CPU-inform table has exactly 8 entries.

### Concrete FLEXPMU risk boundary

The helper computes a linear physical CPU index from MPIDR affinity fields and directly indexes `pmucal_cpuinform_list[phycpu]` in both hint and clear paths. No bounds check is present in those two functions. The init function resolves each configured `base_pa` by matching it against the 58-entry P2V map and returns `-ENOENT` if a mapping is absent. If FLEXPMU is ever enabled, review must establish:
1. every possible A50 MPIDR-derived index is below `cpu_inform_list_size`;
2. the CPU-inform table entries correspond to the actual A50 physical CPU topology;
3. each `base_pa` maps to a valid P2V entry;
4. the hint register offsets and access ordering are valid on A505F silicon; and
5. initialization completes before any CPU hotplug, cluster powerdown or system suspend path can issue a hint.

### Revised Linux 5.1 recommendation

Keep FLEXPMU out of the first port. The minimum CAL dependency sequence to validate is:
`cal_if_init() -> ect_parse_binary_header()/vclk_initialize() -> cal_data_init() -> pmucal_rae_init() -> pmucal_system_init() -> pmucal_local_init() -> pmucal_cpu_init()`.
Then verify the clock-provider and PM-domain callers that invoke this interface, their init ordering, and the DT/regmap resources they require. Do not claim this sequence is complete until all callers and initcall sites have been traced.

This is static source inspection only; no compile or device test was run.
