# Exynos9610 CAL Dependency Map — Phase 1

Audit date: 2026-11-17  
Repository: `crypto143007-ship-it/SOVR-Kernel-A50`  
Branch: `migration/linux-5.1-assessment`  
Audited commit: `e7ad835e51322d8fa0adbd1017f876205851889e`  
Target: pinned upstream Linux v5.1 baseline in `LINUX_51_BASELINE.md`

## Scope and evidence

This is a source-level dependency inventory based on the checked-out vendor source files in the migration branch. It is not a Linux 5.1 port, build, or hardware validation. The purpose is to identify compilation units, textual inclusions, public interfaces, and hard runtime dependencies before changing code.

## 1. Kbuild entry and object selection

The parent Samsung SoC Kbuild gate is `CONFIG_CAL_IF`; once entered, `drivers/soc/samsung/cal-if/Makefile` selects:

| Selection | Objects / data |
|---|---|
| unconditional in CAL directory | `cal-if.o` |
| `CONFIG_PMUCAL` | `pmucal_system.o pmucal_local.o pmucal_cpu.o pmucal_rae.o` |
| `CONFIG_FLEXPMU` | `pmucal_powermode.o` |
| `CONFIG_CP_PMUCAL` | `pmucal_cp.o` |
| `CONFIG_GNSS_PMUCAL` | `pmucal_gnss.o` |
| `CONFIG_SHUB_PMUCAL` | `pmucal_shub.o` |
| `CONFIG_CMUCAL` | `cmucal.o ra.o vclk.o pll_spec.o` |
| `CONFIG_CMUCAL_DEBUG` | `cmucal-debug.o` |
| `CONFIG_ACPM_DVFS` | `acpm_dvfs.o fvmap.o` |
| `CONFIG_SOC_EXYNOS9610` | `exynos9610/cal_data.o` |

The A50 defconfigs enable the relevant Exynos9610 CAL, PMUCAL, CMUCAL, ACPM DVFS and ECT configuration family (see the preceding init-order audit). This means the port must preserve the effective dependency graph, not just make `cal-if.o` compile.

## 2. Important compilation-unit detail: Exynos9610 data

`drivers/soc/samsung/cal-if/exynos9610/cal_data.c` textually includes these C files:

- `cmucal-node.c`
- `cmucal-qch.c`
- `cmucal-sfr.c`
- `cmucal-vclk.c`
- `cmucal-vclklut.c`
- `clkout_exynos9610.c`

They are included after the PMUCAL common and Exynos9610 data headers. Treat these as part of the `cal_data.o` translation unit in this vendor tree. Do not also add the included C files as independent Kbuild objects: that would risk duplicate definitions. This inclusion pattern must be checked against the Linux 5.1 integration design before any refactor.

The same translation unit includes the Exynos9610-specific CPU, local power-domain, physical-to-virtual map, system, CP, GNSS and sensor-hub PMUCAL data headers, plus ACPM DVFS and ASV data headers.

## 3. CAL public API and direct implementation dependencies

`include/soc/samsung/cal-if.h` is the consumer-facing interface. In the non-`CONFIG_PWRCAL` branch it declares:

- clock and QCH operations;
- power-domain control/status and SMC configuration;
- system suspend entry/exit/early-wakeup;
- CPU and cluster power control/status;
- DVFS rate, table, boot/resume and ASV queries;
- CP and GNSS control/status hooks;
- `cal_if_init(void *)` and `cal_init(void)`.

The interface also directly includes the vendor path `drivers/soc/samsung/cal-if/pmucal_system.h`. That source-tree-relative include is a portability/integration concern for a Linux 5.1 upstream-style layout and must be resolved deliberately (prefer a stable exported include path; do not silently move or duplicate definitions).

In `cal-if.c`, the CAL facade directly includes ECT parser, CAL interface, power-control environment/RAE, CMUCAL, resource allocator, ACPM DVFS/FVMAP/ASV and PMUCAL system/local/CPU/CP/GNSS/SHUB/RAE headers. Its exported facade functions dispatch into VCLK/CMUCAL, RA, PMUCAL and ACPM routines. The CAL layer therefore cannot be meaningfully validated as an isolated source file.

## 4. PMUCAL execution dependencies

The inspected common PMUCAL source establishes these direct dependencies:

- `pmucal_system.c` uses PMUCAL RAE sequence conversion/handling/save/restore and the per-mode LPM sequence tables; FLEXPMU adds power-mode hints.
- `pmucal_local.c` uses PMUCAL RAE sequence operations and, for secure domains, TrustZone power-domain save/restore SMC hooks (`exynos_pd_tz_save/restore`).
- `pmucal_cpu.c` uses PMUCAL RAE and conditionally FLEXPMU power-mode support.
- `cal_data.c` supplies the Exynos9610-specific sequence tables and physical-address mapping data consumed by the common PMUCAL routines.

These are not interchangeable stubs. The PA-to-VA conversion, sequence counts, register tables, secure-call behavior and return propagation are runtime correctness requirements. Any missing dependency must remain a build blocker until its real provider or a proven compatible implementation is present.

## 5. ACPM / DVFS dependency boundary

The CAL facade calls ACPM DVFS for ACPM-managed VCLK rate changes and uses FVMAP/ASV data for voltage tables. The ACPM driver directory contains separate transport/device and IPC implementation units (`acpm.c`, `acpm_ipc.c`, MFD/S2D support and firmware protocol headers). This creates a second port boundary beyond CAL/PMUCAL: the transport protocol, mailbox/IPC primitives, firmware ABI and device registration must be mapped independently against Linux 5.1.

Do not claim ACPM DVFS functional merely because `acpm_dvfs.o` links. The A50 firmware/DT resources and actual transport operation need later verification.

## 6. Porting risks identified before implementation

1. **Textually included C sources:** avoid duplicate object linkage when porting `cal_data.c`.
2. **Source-relative exported header:** replace the relative include of `pmucal_system.h` with a stable include contract, after checking all consumers.
3. **Configuration split:** `CONFIG_PMUCAL`, `CONFIG_FLEXPMU`, CP/GNSS/SHUB PMUCAL, CMUCAL and ACPM DVFS are independently selected; verify dependencies and legal combinations in Kconfig.
4. **Vendor-only services:** debug-snapshot, TrustZone PD SMC, ACPM and Samsung ECT interfaces require explicit provider/API checks in v5.1.
5. **Boot-critical failure semantics:** preserve negative error returns from CAL/PMUCAL and the early clock provider's fatal initialization behavior until a complete, justified redesign is proven.
6. **Data integrity:** Exynos9610 PMUCAL/CMUCAL register and sequence tables are silicon-specific; do not substitute Exynos8895/9810 tables.

## 7. Next required work

1. Complete an exact symbol-provider map for each CAL/PMUCAL/CMUCAL/ACPM translation unit, including all external references and conditional branches.
2. Inventory every included header and its transitive vendor-only dependencies.
3. Compare those dependencies with the pinned Linux v5.1 tree and record API/semantic mismatches.
4. Audit the ECT parser implementation and its data source/lifetime assumptions.
5. Audit ACPM IPC/firmware ABI and DT resources separately.
6. Only after these maps are complete, create isolated compatibility patches and run targeted object builds.

## Validation status

- Source files and Kbuild entries inspected on the migration branch at `e7ad835`.
- No source implementation changed by this audit.
- No Linux 5.1 CAL/PMUCAL/ACPM object build is claimed.
- No full Image/DTB build, device boot, suspend/resume or hardware validation is claimed.
- Preserve the known Linux 4.14.357 recovery baseline; do not flash an incomplete 5.1 port.
