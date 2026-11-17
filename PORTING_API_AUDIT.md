# Exynos9610 Linux 5.1 Porting API and Build-Wiring Audit

**Status:** source-inventory audit; not a patch series and not a build validation.  
**Target:** Samsung Galaxy A50 (SM-A505F), Exynos9610, vendor kernel baseline 4.14.357.  
**Comparison target:** upstream Linux tag `v5.1`.

## Scope and evidence rules

This document records source files, Kconfig symbols, Makefile object wiring, and whether corresponding paths exist in upstream v5.1. File existence alone does not establish API compatibility, runtime binding, or hardware operation. No API migration is declared complete unless a concrete call-site/type/signature difference has been inspected. The audit is intentionally conservative.

## Confirmed platform integration points

| Area | Vendor-tree evidence | Required integration |
|---|---|---|
| SoC selection | `arch/arm64/Kconfig.platforms` defines `CONFIG_SOC_EXYNOS9610`; A50 defconfig enables it | Reintroduce/port SoC Kconfig and architecture selection in a v5.1-compatible way |
| DT build | `arch/arm64/boot/dts/exynos/Makefile` builds `exynos9610.dtb`, `exynos9610-universal9610.dtbo`, and `exynos9611-universal9611.dtbo` under `CONFIG_SOC_EXYNOS9610` | Port SoC DTS/DTSI, board overlay, bindings, and all referenced include files |
| Clock controller | `drivers/clk/samsung/Makefile` builds `clk-exynos9610.o` under `CONFIG_SOC_EXYNOS9610` only in the vendor composite-clock branch; source file is present | Port driver, clock IDs/bindings, parent clocks, CMU register definitions, and clock-provider integration |
| CAL/CMUCAL | `drivers/soc/samsung/Makefile` includes `cal-if/` under `CONFIG_CAL_IF`; `cal-if/Makefile` builds `exynos9610/cal_data.o` under `CONFIG_SOC_EXYNOS9610` | Port CAL interface, Exynos9610 data, PMUCAL/CMUCAL and dependencies as a matched set |
| ACPM | `drivers/soc/samsung/acpm/Kconfig` has `EXYNOS_ACPM` and `EXYNOS9610_ACPM`; Makefile builds IPC objects | Port mailbox/IPC protocol, shared-memory layout, firmware interface and consumers |
| Thermal | `drivers/thermal/samsung/Makefile` builds `exynos_tmu.o` and optional `exynos_acpm_tmu.o`; Kconfig defines `EXYNOS_THERMAL` and `EXYNOS_ACPM_THERMAL` | Port TMU register data, ACPM plugin, thermal framework hooks, cooling-device integrations |
| Pin control | Samsung pinctrl Makefile builds generic Samsung, Exynos and ARM64 data objects; Exynos ARM64 implementation exists | Validate Exynos9610 bank data, EINT/wakeup handling, PMU retention, pinctrl binding and GPIO IRQ integration |
| UFS | `drivers/scsi/ufs/Makefile` builds vendor `ufs-exynos.o`, `ufs-exynos-dbg.o`, and `ufs-cal-9610.o` for Exynos9610 | Port UFS host extension, Exynos CAL, FMP/SRMPB integration, PHY/clock/reset/power sequencing |
| TrustZone | `drivers/misc/tzdev/Makefile` builds TZDEV transport and optional `tz_deploy_tzar.o`; Exynos9610 selects `ion_fd2phys_v1.o` and boost cluster 1 | Port TZDEV and secure-world ABI without changing firmware contract; preserve TZAR deployment and memory-sharing semantics |
| Power management | `drivers/soc/samsung/Makefile` wires Exynos PM, power mode, CPU PM, DVFS manager, PM domains and topology | Port dependencies and platform-specific idle/suspend/resume sequencing, then validate wake sources |

## Upstream Linux v5.1 comparison

The following checks were performed against `torvalds/linux` ref `v5.1`:

1. **Clock Makefile:** upstream v5.1 has the common Samsung clock framework and legacy Exynos controllers, but does not contain the vendor `CONFIG_SOC_EXYNOS9610` object rule or `clk-exynos9610.c`. The vendor driver must be ported and wired; simply setting the symbol will not build it.
2. **Samsung SoC Makefile:** upstream v5.1 has only a small set of Samsung SoC objects in this directory. It does not contain the vendor CAL/ACPM/Exynos PM integration set found in this tree.
3. **Pin control:** upstream v5.1 does contain `pinctrl-exynos-arm64.c`, so this is not a wholly missing subsystem. However, the vendor file is not byte-identical to the upstream file (different blob IDs); its Exynos9610-specific bank/interrupt/retention data and dependencies still require a focused diff and validation.
4. **Thermal:** upstream v5.1 contains `drivers/thermal/samsung/exynos_tmu.c`, but the vendor implementation has additional Samsung platform integrations (including ACPM TMU plugin and vendor cooling/debug hooks). Presence of the generic filename is not proof of Exynos9610 support.
5. **UFS:** upstream v5.1 has the generic UFS host framework and `drivers/scsi/ufs/Makefile`, but does not have vendor `ufs-exynos.c` at that path. The Exynos host driver and Exynos9610 CAL are missing from the upstream target.
6. **TZDEV:** upstream v5.1 has no `drivers/misc/tzdev/Makefile`. This is a vendor-only secure-world subsystem in the current tree and must be treated as a P0 boot/security dependency, not replaced with a stub.
7. **DT:** the prior audit established that upstream v5.1's Exynos DT build list does not include Exynos9610 board/SoC files. The vendor DTS set is therefore a porting requirement, not an optional board customization.

## Confirmed vendor source identifiers

Blob IDs below identify the exact files audited on branch `migration/linux-5.1-assessment`:

- `drivers/clk/samsung/Makefile`: `6df73d234c68de7480ab8237cac6ff8149727fd8`
- `drivers/clk/samsung/Kconfig`: `dc14633a4a0618f7ba2c7cecf455e4c1a95cc123`
- `drivers/soc/samsung/Makefile`: `aaf1d109a3ec8ee58d9c449c45e8b498e6fe49b4`
- `drivers/soc/samsung/Kconfig`: `1d2a3a8baa33a94d125eb912835452c84c43ed59`
- `drivers/soc/samsung/cal-if/Makefile`: `00944ace1b772acd0193edf80792dd7b884e4c0a`
- `drivers/soc/samsung/acpm/Kconfig`: `4752c97930cf95f643f2c5f30e254ad8bb3c045f`
- `drivers/soc/samsung/acpm/Makefile`: `f4a35695d98b3dd47581cf1783dd641548b763ac`
- `drivers/pinctrl/samsung/Makefile`: `6d7bd226e3364d3e05b4f011709c66705e95ecea`
- `drivers/pinctrl/samsung/pinctrl-exynos-arm64.c`: `85a30b5fe024506b8bb6d6f28145a8943fd1b0c8`
- `drivers/thermal/samsung/Kconfig`: `0706ea57d6be72a06b2785e2a8d40327fe2ad8d3`
- `drivers/thermal/samsung/Makefile`: `aba173d43cf59b29d94323ef9d2453459c8123b6`
- `drivers/thermal/samsung/exynos_tmu.c`: `f22f5f8f3bab9b2ed2fe0ce9e3085f4e1ecdbe86`
- `drivers/thermal/samsung/exynos_acpm_tmu.c`: `e03707a5985893f21b75341ca458d4550f36fe9b`
- `drivers/scsi/ufs/Makefile`: `6059a1f755db85bb1a82e490568c1312b584cd7b`
- `drivers/scsi/ufs/ufs-exynos.c`: `5980407d3716bc86f5677b7d9e41bdfbce2778af`
- `drivers/misc/tzdev/Makefile`: `b51f0b1d97a9021b63f29465263e001da1e800a6`
- `drivers/misc/tzdev/Kconfig`: `463d4969fcd65b51d126d27b09d2d7ab35e60478`
- `arch/arm64/configs/exynos9610-a50_core_defconfig`: `c3b98544257220d284cbebc290d45c913025c050`

## Port priority and sequencing

### P0 — boot, secure world, storage and clock correctness
1. Establish the v5.1 ARM64 Exynos9610 SoC/Kconfig and device-tree build foundation.
2. Port clock controller and CAL/CMUCAL/PMUCAL as one dependency group. Validate every referenced clock ID and provider before enabling consumers.
3. Port TZDEV and TZAR deployment without changing secure firmware interfaces, memory ownership, PFN width, or ION fd-to-physical behavior.
4. Port UFS host/CAL/FMP and storage power sequencing. Preserve the existing FMP/SRPMB security requirements.
5. Port pinctrl/GPIO/EINT and PMU retention before relying on board DT pin states or wakeup sources.

### P1 — thermal, power and daily-driver hardware
1. Port ACPM IPC and its firmware-facing protocol.
2. Port TMU and ACPM thermal plugin; preserve CPU/GPU/ISP cooling relationships and thermal trip semantics.
3. Port suspend/resume, cpuidle, CPU hotplug, DVFS, PM domains, regulator and power-mode integrations.
4. Continue with display, Mali, multimedia, camera, audio, modem, SCSC/WLBT, USB and peripheral drivers.

## API migration work still required

This audit has not yet performed function-by-function API diffs. The next source-level tasks are:

- Diff vendor vs upstream v5.1 versions of common pinctrl and thermal files, identify each changed structure member, callback signature, helper, and locking/lifetime assumption.
- For vendor-only clock/CAL/UFS/TZDEV/ACPM files, compare every external kernel API use against v5.1 headers and implementation. Record exact compiler errors only after a real v5.1 build.
- Resolve every Kconfig dependency and Makefile object rule, including symbols selected indirectly by the A50 defconfig.
- Trace all Exynos9610 DT `compatible` values to a driver `of_match_table`; a compatible string in DT alone does not prove a driver exists or binds.
- Validate firmware blobs, TZAR payloads, UFS FMP/SRPMB, panel firmware and other non-source dependencies separately.

## Explicit non-claims

- No Linux 5.1 kernel has been compiled by this audit.
- No boot image, flashable ZIP, or release artifact has been produced.
- No device has been flashed or boot-tested.
- No API compatibility is implied by source-file presence.
- The target remains Linux 5.1 as requested; its age and security maintenance burden must be addressed with a documented backport policy.
