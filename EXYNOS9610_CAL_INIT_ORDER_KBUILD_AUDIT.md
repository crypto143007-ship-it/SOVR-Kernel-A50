# Exynos9610 CAL / Clock Kbuild and Initialization-Order Audit

Audit date: 2026-11-17  
Repository: `crypto143007-ship-it/SOVR-Kernel-A50`  
Audit branch: `migration/linux-5.1-assessment`  
Vendor source baseline: fork `main` content carried into the migration branch  
Target: pinned upstream Linux v5.1 baseline documented in `LINUX_51_BASELINE.md`

## Scope and evidence

This is a targeted source audit of the vendor Kconfig/Makefile selection chain and the actual early clock-provider initialization path. It records source-level facts and porting constraints; it does not claim Linux 5.1 compatibility, compilation, device-tree validation, or hardware operation.

Files inspected:

- `drivers/soc/samsung/Makefile`
- `drivers/soc/samsung/Kconfig`
- `drivers/soc/samsung/cal-if/Makefile`
- `drivers/soc/samsung/cal-if/cal-if.c`
- `drivers/clk/samsung/Makefile`
- `drivers/clk/samsung/Kconfig`
- `drivers/clk/samsung/clk-exynos9610.c`
- `arch/arm64/configs/exynos9610-a50_core_defconfig`
- `arch/arm64/configs/exynos9610-a50_default_defconfig`

## 1. Actual Kbuild reachability chain

The vendor Samsung SoC Makefile adds the CAL directory only through:

```make
obj-$(CONFIG_CAL_IF) += cal-if/
```

Inside `drivers/soc/samsung/cal-if/Makefile`, the core CAL translation unit is unconditional *within that directory*:

```make
obj-y += cal-if.o
obj-$(CONFIG_PMUCAL) += pmucal_system.o pmucal_local.o pmucal_cpu.o pmucal_rae.o
obj-$(CONFIG_CP_PMUCAL) += pmucal_cp.o
obj-$(CONFIG_GNSS_PMUCAL) += pmucal_gnss.o
obj-$(CONFIG_SHUB_PMUCAL) += pmucal_shub.o
obj-$(CONFIG_CMUCAL) += cmucal.o ra.o vclk.o pll_spec.o
obj-$(CONFIG_CMUCAL_DEBUG) += cmucal-debug.o
obj-$(CONFIG_ACPM_DVFS) += acpm_dvfs.o fvmap.o
obj-$(CONFIG_SOC_EXYNOS9610) += exynos9610/cal_data.o
```

This distinction matters: `cal-if.o` is not independently guarded by a symbol inside the subdirectory; the parent `CONFIG_CAL_IF` controls whether the directory is entered. The other runtime components are selected independently. A Linux 5.1 Kbuild port must preserve both levels instead of flattening all CAL sources into unconditional objects.

The vendor clock Makefile has a separate conditional branch:

```make
ifeq ($(CONFIG_COMPOSITE_CLK_SAMSUNG), y)
    obj-y += composite.o
    obj-$(CONFIG_SOC_EXYNOS9610) += clk-exynos9610.o
else
    obj-$(CONFIG_COMMON_CLK) += clk.o clk-pll.o clk-cpu.o
    obj-$(CONFIG_EXYNOS_ARM64_COMMON_CLK) += clk-exynos5433.o
    obj-$(CONFIG_EXYNOS_ARM64_COMMON_CLK) += clk-exynos7.o
endif
```

The corresponding vendor Kconfig defines `COMPOSITE_CLK_SAMSUNG` as a hidden bool, default y, dependent on `ARCH_EXYNOS9 || ARCH_EXYNOS8 || ARCH_EXYNOS7`. The A50 defconfigs explicitly set `CONFIG_ARCH_EXYNOS9=y` and `CONFIG_COMPOSITE_CLK_SAMSUNG=y`. This selects the vendor composite framework and Exynos9610 clock provider, not the alternate generic Samsung clock-object branch.

**Porting implication:** the Linux 5.1 target must deliberately supply or redesign the relevant SoC architecture/configuration symbols and the composite clock dependency. Merely adding `clk-exynos9610.o` to a Makefile is insufficient.

## 2. Confirmed A50 config selection

Both checked-in A50 configurations select the CAL/CMUCAL/PMUCAL/ACPM/ECT chain.

| Symbol | Core defconfig | Default defconfig |
|---|---:|---:|
| `SOC_EXYNOS9610` | y | y |
| `ARCH_EXYNOS9` | y | y |
| `COMPOSITE_CLK_SAMSUNG` | y | y |
| `CAL_IF` | y | y |
| `CMUCAL` | y | y |
| `CMUCAL_QCH_IGNORE_SUPPORT` | y | y |
| `EXYNOS_ACPM` | y | y |
| `EXYNOS_ACPM_MFD` | y | y |
| `ACPM_DVFS` | y | y |
| `PMUCAL` | y | y |
| `CP_PMUCAL` | y | y |
| `GNSS_PMUCAL` | y | y |
| `SHUB_PMUCAL` | y | y |
| `ECT` | y | y |
| `ECT_DUMP` | y | y |
| `CMUCAL_DEBUG` | disabled | y |

The default defconfig enables CMUCAL debug while the core defconfig disables it. Keep this difference explicit during config migration; do not silently inherit debug interfaces into a production configuration.

The selected `ECT=y` is significant because `cal_if_init()` calls `ect_parse_binary_header()` unconditionally in the inspected implementation. The ECT parser object is separately selected by `CONFIG_ECT` in the parent Samsung SoC Makefile. A target config that enables CAL but drops ECT would therefore need a deliberate compatible implementation or stub contract, not an accidental unresolved symbol.

## 3. Early boot ordering and fatal failure behavior

The Exynos9610 provider is registered with:

```c
CLK_OF_DECLARE(exynos9610_clk, "samsung,exynos9610-clock",
               exynos9610_clk_init);
```

Within `exynos9610_clk_init()`, the inspected order is:

1. Map the clock-controller registers with `of_iomap(np, 0)`; failure calls `panic()`.
2. Call `cal_if_init(np)`.
3. If CAL initialization returns nonzero, call `panic()`.
4. Allocate the Samsung clock provider with `samsung_clk_init()`; allocation failure calls `panic()`.
5. Register external fixed-rate clocks and the Exynos9610 HWACG and special VCLK tables.
6. Register the OF clock provider.
7. Assign `late_time_init = exynos9610_vclk_init`.
8. Log clock setup completion.

This is a boot-critical, early DT clock initialization path. It is not a normal late platform-driver probe that can safely defer until all services have started. Changing it to deferred probing requires a complete audit of early clock consumers and proof that no boot dependency cycle is introduced.

The CAL initializer in `cal-if.c` performs the following ordered operations:

1. Return early if its static initialized flag is already set.
2. Parse the ECT binary header.
3. Run `vclk_initialize()`.
4. Run `cal_data_init()` when its function pointer is populated.
5. Initialize PMUCAL RAE.
6. Initialize PMUCAL system data.
7. Initialize PMUCAL local data.
8. Initialize PMUCAL CPU data.
9. Conditionally initialize FLEXPMU CPU-inform, CP, GNSS and sensor-hub paths.
10. Register the ACPM device pointer with `exynos_acpm_set_device(dev)`.
11. Set the initialized flag only after the sequence completes.

Negative returns from the core PMUCAL stages abort CAL initialization and consequently trigger the clock-provider panic path. The port must preserve the error propagation and ordering. It must not turn failures into success returns or use empty implementations to make the provider appear initialized.

## 4. Required dependency and API port boundary

The first implementation unit is larger than the clock table. At minimum, the source/Kbuild graph includes:

- Samsung composite CCF adapter and vendor clock descriptor/operation semantics.
- CAL interface and its ECT parser dependency.
- CMUCAL core, resource allocator, VCLK and PLL specification objects.
- Exynos9610 SoC CAL data and the CMUCAL node/QCH/VCLK identifiers.
- PMUCAL RAE, system, local and CPU initialization.
- CP/GNSS/sensor-hub PMUCAL paths selected by the A50 config.
- ACPM transport/device registration and ACPM DVFS/FVMAP.
- Clock provider registration and all DTS clock IDs/consumers.

The A50 defconfigs enable these components together. A partial port that builds the provider while omitting one of the selected initialization dependencies is not a valid migration.

## 5. Next engineering sequence

1. Build a symbol-to-object matrix for every function called from `cal_if_init()` and every external symbol referenced by the CAL translation units.
2. Recursively resolve header includes and Kconfig dependencies under the exact A50 core and default defconfigs.
3. Compare each required Linux API against the pinned v5.1 headers and implementation, recording signature and semantic changes.
4. Port the smallest dependency layer in isolated commits; keep the Exynos9610 provider disabled until its prerequisites compile.
5. Add a target Kconfig/Makefile integration and run `olddefconfig`/configuration-diff checks before attempting compilation.
6. Compile CAL/CMUCAL/PMUCAL/ACPM objects first, then the clock provider, full ARM64 Image and DTBs.
7. Inspect link symbols and DT clock-provider references; only after successful build evidence should device boot and functional testing begin.

## Safety / current status

- No kernel source implementation was changed by this audit.
- No Linux 5.1 Exynos9610 CAL or clock object has been compiled by this document.
- No Image/DTB, flash, boot, suspend/resume or hardware validation is claimed.
- Preserve the existing SOVR Linux 4.14.357 baseline and recovery image.
- Do not enable a partially ported Exynos9610 clock provider in a daily-driver image.

