# Exynos9610 Clock / CAL Porting Plan for Linux 5.1

## Scope and evidence

This note records a source-level comparison between the SOVR vendor kernel's Exynos9610 clock implementation and the pinned upstream Linux v5.1 baseline documented in [LINUX_51_BASELINE.md](LINUX_51_BASELINE.md). It is an engineering plan, not a claim that the clock driver has been ported or tested.

Inspected vendor sources on `main`:
- `drivers/clk/samsung/clk-exynos9610.c` (blob `1ecdd4ea5b66601c2a68a1d8eefaf992505b2061`)
- `drivers/clk/samsung/Makefile` (blob `6df73d234c68de7480ab8237cac6ff8149727fd8`)

Inspected upstream source at commit `e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd`:
- `drivers/clk/samsung/Makefile`

## Confirmed architectural mismatch

The vendor Exynos9610 clock driver is not a conventional standalone Samsung CCF clock table. Its opening includes:
- `<soc/samsung/cal-if.h>`
- Exynos9610 `cmucal-vclk.h`, `cmucal-node.h`, `cmucal-qch.h`, and `clkout_exynos9610.h`
- the vendor `composite.h`

The driver declares large `struct init_vclk` tables using `HWACG_VCLK(...)` and `VCLK_GATE`, alongside a Samsung fixed-rate clock declaration. These are vendor CAL / CMUCAL / HWACG integration points. They are not safely replaceable by copying an upstream Exynos5433/Exynos7 clock driver or by adding only a Makefile object rule.

The vendor Makefile conditionally builds `composite.o` and `clk-exynos9610.o` under `CONFIG_COMPOSITE_CLK_SAMSUNG`. The pinned upstream v5.1 Samsung clock Makefile contains the generic Samsung clock objects and older SoC drivers, but no Exynos9610 object rule and no matching composite-clock conditional. Thus the upstream baseline has no directly buildable Exynos9610 clock implementation at this path.

## Port blockers to resolve before enabling the driver

1. **CAL contract:** port or replace the Exynos9610 CAL interface and all functions/types consumed by the clock driver. Inventory every external symbol and its implementation; do not stub rate, gate, or suspend operations.
2. **CMUCAL data:** preserve and validate the VCLK, node, Q-channel, and clock-output identifiers against the Exynos9610 hardware data. These headers are part of the functional hardware description, not incidental includes.
3. **Composite clock framework:** determine which vendor composite operations differ from upstream CCF in v5.1. Port only the minimum required framework and document semantic differences.
4. **Provider registration:** trace the complete provider initialization, parent-clock resolution, error handling, and deferred-probe behavior before changing registration APIs.
5. **Power management:** audit clock save/restore, runtime PM, suspend/resume ordering, and dependencies on ACPM / firmware. Clock operation cannot be considered correct merely because the kernel links.
6. **DTS / binding consistency:** cross-check every clock ID and provider reference in the A50 DTS against the exported binding header and the registered provider. No DTS node should be silently left with unresolved clocks.
7. **Build validation:** compile the clock subsystem first, then the full ARM64 Image and DTBs with the A50 defconfig. Treat warnings, unresolved symbols, and missing provider references as blockers.

## Recommended implementation sequence

- **Stage A — dependency inventory:** enumerate all externally defined types, macros, functions, and data referenced by `clk-exynos9610.c`; map each to its source file and configuration guard. Include CAL, CMUCAL, composite, ACPM, and clock-output dependencies.
- **Stage B — API compatibility:** compare the vendor CAL / composite interfaces against Linux v5.1 CCF APIs. Record signature and behavior differences before editing code.
- **Stage C — minimal framework port:** port the CAL and composite prerequisites as isolated commits, without enabling the Exynos9610 driver by default.
- **Stage D — clock provider port:** add the Exynos9610 driver and Makefile/Kconfig integration only after prerequisites compile. Keep the implementation behind an explicit SoC configuration.
- **Stage E — static and build checks:** build the clock objects, full Image, and DTBs; inspect link map and unresolved symbols; verify all DTS clock references.
- **Stage F — device validation:** only after successful builds, test boot, suspend/resume, CPU/devfreq behavior, display, camera, audio, storage, and thermal behavior on hardware. Preserve the known-booting 4.14 kernel as the recovery path.

## Explicit non-goals / safety

- Do not replace the vendor driver with guessed fixed rates or no-op clock operations.
- Do not delete clock consumers from DTS merely to make a build pass.
- Do not enable a partially ported provider in a daily-driver image.
- Do not infer hardware correctness from a successful compile.
- No Linux 5.1 Exynos9610 clock build, flash, or boot test is claimed by this document.

## Current disposition

**Blocked / discovery required.** The first real porting unit is the CAL + CMUCAL + composite dependency boundary, not the Exynos9610 clock table alone. The next code change should follow a complete symbol/dependency inventory and API diff.


## Follow-up dependency findings (vendor source)

The public vendor header `include/soc/samsung/cal-if.h` (blob `65fe05a30e4251b0ca9d735ddbb29d7713374ac5`) makes the configuration split explicit:

- With `CONFIG_PWRCAL`, it includes the vendor `pwrcal.h` implementation and supplies inline no-op implementations for `cal_qch_init()` and `cal_if_init()`. This branch must not be mistaken for proof that the full CMUCAL runtime is present.
- Without `CONFIG_PWRCAL`, it includes `pmucal_system.h` and declares the CAL clock, power-domain, PM, CPU/cluster, DFS, ASV, CP, GNSS, and initialization interfaces. These are a much larger platform contract than the clock provider alone.
- The header also declares `cal_clk_setrate`, `cal_clk_getrate`, `cal_clk_enable`, and `cal_clk_disable`; any CCF adapter must preserve their error and rate semantics rather than silently returning success.

The vendor `drivers/soc/samsung/cal-if/Makefile` (blob `00944ace1b772acd0193edf80792dd7b884e4c0a`) builds:
- core CAL/CMUCAL objects (`cal-if.o`, `cmucal.o`, `ra.o`, `vclk.o`, `pll_spec.o`) under separate configuration symbols;
- PMUCAL objects under `CONFIG_PMUCAL`;
- ACPM DVFS / FVMAP under `CONFIG_ACPM_DVFS`;
- the Exynos9610-specific `cal_data.o` under `CONFIG_SOC_EXYNOS9610`.

The vendor `drivers/clk/samsung/composite.h` defines custom PLL, mux, divider, gate, user-mux, and virtual-clock descriptor structures and registration functions. It also carries vendor-specific VCLK flags including DFS and QCH operations. Therefore, even where upstream CCF offers a similarly named clock type, semantic equivalence is not established.

### Revised dependency boundary

Treat the clock port as a dependency graph with at least four independently audited layers:

1. **CCF adapter / composite layer** — clock descriptor types, operations, registration, locking, and parent handling.
2. **CMUCAL layer** — virtual-clock IDs, Q-channel/node data, VCLK operations and SoC-specific `cal_data.o`.
3. **PMUCAL / firmware layer** — power sequencing, PMU state, ACPM communication and any firmware-mediated DVFS behavior.
4. **SoC clock provider / DTS layer** — Exynos9610 provider initialization, binding IDs, parent clocks, and every consuming DTS node.

Do not select the `CONFIG_PWRCAL` stub path as a shortcut unless the complete build configuration and runtime call graph prove that all required clock and power operations are implemented elsewhere. A stubbed initialization routine can make compilation look easier while leaving hardware clocks or power domains uncontrolled.


## CAL runtime audit: initialization and behavior hazards

A further inspection of vendor `drivers/soc/samsung/cal-if/cal-if.c` (blob `35c62490a906259667bc347231a7e35dc8b0b514`) exposed important runtime behavior that must be preserved or consciously redesigned:

- `cal_clk_is_enabled()` currently returns `0` unconditionally in this implementation. Do not assume it provides a real hardware gate-state query.
- `cal_dfs_set_rate()` routes ACPM-managed VCLK IDs through `exynos_acpm_set_rate()`, updates the CMUCAL node's cached rate only on success, and routes other IDs through `vclk_set_rate()`.
- `cal_clk_setrate()`, `cal_clk_getrate()`, `cal_clk_enable()`, and `cal_clk_disable()` delegate to CMUCAL VCLK operations. These are not plain register writes and depend on initialized VCLK metadata.
- `cal_pd_control()` validates the `BLKPWR_MAGIC` ID prefix and then delegates to PMUCAL local power-domain sequencing. Power-domain control therefore has an independent dependency chain from CCF clock registration.
- `cal_if_init(void *dev)` is an ordered initialization path: ECT binary parsing, VCLK initialization, optional SoC CAL data initialization, PMUCAL RAE, system, local, and CPU initialization, optional CPU-inform / CP / GNSS / sensor-hub setup, then ACPM device registration. Errors from the core PMUCAL stages abort initialization.

The Exynos9610 CAL data directory is substantial, not a small table: it contains SoC-specific `cal_data.c`, CMUCAL node/QCH/SFR/VCLK/VCLK-LUT sources and headers, plus PMUCAL CPU/local/system/CP/GNSS/sensor-hub data. Several files are hundreds of kilobytes. This reinforces that the port must preserve generated hardware sequencing data and its initialization order; mechanically adapting only the clock provider would leave major runtime dependencies unresolved.

### Additional gating decision

Before enabling the driver in a Linux 5.1 build, identify the exact A50 defconfig values for `CAL_IF`, `CMUCAL`, `PMUCAL`, `ACPM_DVFS`, `CONFIG_PWRCAL`, and the Exynos9610 SoC symbol. Then trace every caller of `cal_if_init()` and verify that the selected init path is actually invoked before clock consumers probe. A compile-only result cannot validate this ordering.
