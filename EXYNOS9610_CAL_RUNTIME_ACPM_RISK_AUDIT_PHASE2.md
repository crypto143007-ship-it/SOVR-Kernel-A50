# Exynos9610 CAL Runtime / ACPM Risk Audit — Phase 2

Audit date: 2026-11-17
Repository: crypto143007-ship-it/SOVR-Kernel-A50
Branch: migration/linux-5.1-assessment
Scope: source-level review of PMUCAL RAE execution and ACPM DVFS initialization
Target: pinned upstream Linux v5.1 commit e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd

## Evidence boundary

This document records behavior visible in the vendor source carried by the migration branch. It is not a Linux 5.1 port, compiler result, runtime trace, or hardware validation. No kernel source implementation was changed.

## 1. PMUCAL RAE sequence execution

Source files:
- drivers/soc/samsung/cal-if/pmucal_rae.c
- drivers/soc/samsung/cal-if/pmucal_common.h
- drivers/soc/samsung/cal-if/pmucal_rae.h

### 1.1 Physical-to-virtual register mapping is a hard initialization dependency

pmucal_rae_phy2virt() walks every sequence entry and resolves base_pa and cond_base_pa against pmucal_p2v_list. A missing mapping returns -ENOENT. The CAL initializer propagates failures from pmucal_rae_init(), pmucal_system_init(), pmucal_local_init(), and pmucal_cpu_init(); the Exynos9610 clock provider's early-init path treats CAL initialization failure as fatal.

Porting requirement:
- Preserve the PA-to-VA map and its coverage for every sequence used by CPU, system, local, CP, GNSS and sensor-hub power control.
- Check phys_addr_t width and conversion behavior on ARM64 Linux 5.1.
- Do not replace missing mappings with NULL, identity mappings, or success returns.
- Add a static validation pass that checks all referenced sequence physical addresses against the SoC map before enabling the provider.

### 1.2 Register access and ordering semantics must be reviewed

The RAE implementation uses __raw_readl() and __raw_writel() for sequence operations, condition checks, and save/restore. The common sequence structure stores physical addresses and mapped __iomem pointers separately.

Porting requirement:
- Compare vendor and v5.1 MMIO access semantics and required ordering/barrier behavior for this platform.
- Preserve the intended register access width, masks, read-modify-write behavior, and sequence ordering.
- Do not mechanically replace raw accessors with relaxed or ordered accessors without checking the Samsung PMU/CMU programming requirements.
- Audit whether any sequence can be invoked concurrently and whether the existing serialization is provided by callers or by the RAE layer.

### 1.3 Two wait implementations have materially different failure behavior

pmucal_rae_wait() polls for up to approximately 1000 one-microsecond delays and returns -ETIMEDOUT if the masked register value never matches.

pmucal_rae_raw_wait() is an unbounded tight polling loop. It has no timeout, delay, cpu_relax(), or error return. pmucal_rae_handle_seq() dispatches PMUCAL_RAW_WAIT to this helper.

Risk classification: high-impact latent hang path; actual A50 reachability has not yet been established. The inspected A50 configuration enables PMUCAL, but that alone does not prove any selected Exynos9610 sequence uses PMUCAL_RAW_WAIT.

Required follow-up before changing behavior:
1. Search every Exynos9610 sequence table and all included CAL data for PMUCAL_RAW_WAIT.
2. Determine whether each occurrence is reachable during early clock init, power-domain transitions, CPU hotplug, suspend/resume, or peripheral power-up.
3. Establish the hardware-required maximum wait and timeout recovery behavior from the sequence specification or known-good device traces.
4. Only then consider a bounded wait. Do not blindly replace it with an arbitrary timeout that could interrupt a mandatory power sequence.

## 2. ACPM DVFS transport and initialization ordering

Source files:
- drivers/soc/samsung/cal-if/acpm_dvfs.c
- drivers/soc/samsung/acpm/acpm_ipc.c
- drivers/soc/samsung/cal-if/cal-if.c

### 2.1 CAL hands the clock-provider device node to ACPM DVFS

cal_if_init(void *dev) calls exynos_acpm_set_device(dev) after ECT, VCLK, SoC data, and PMUCAL initialization. exynos_acpm_set_device() stores the pointer in acpm_dvfs.dev.

The ACPM DVFS init function is registered with fs_initcall(). It requests the DVFS IPC channel using acpm_dvfs.dev and then registers the samsung_acpm_dvfs_driver. The platform driver's probe separately requests the MIF notification channel from its matched device node and adds a PM QoS request.

Porting requirement:
- Preserve the ordering between early clock-provider CAL initialization, storage of the OF node, fs_initcall, IPC channel allocation, and platform probe.
- Validate that the device node passed by CLK_OF_DECLARE is the node expected by the ACPM DT binding.
- Do not move the ACPM registration to a later probe or deferred-probe path without tracing early DVFS and clock consumers.

### 2.2 ACPM rate operations depend on firmware IPC protocol

exynos_acpm_set_rate(), exynos_acpm_get_rate(), exynos_acpm_set_init_freq(), and exynos_acpm_set_volt_margin() construct four-word IPC commands and call acpm_ipc_send_data() on the channel assigned during initialization. The command words encode clock/DVFS ID, rate or voltage, operation code, and subcommand.

Porting requirement:
- Treat command layout, channel ownership, response semantics, firmware shared-memory layout, and timeout behavior as a firmware ABI.
- Port the ACPM IPC transport and its mailbox/interrupt/waiting primitives as a matched subsystem.
- A successful link is not proof that firmware accepts the protocol or that the correct channel is assigned.

### 2.3 Error propagation needs explicit review

The inspected exynos_acpm_get_rate() logs an IPC error but returns config.cmd[1] regardless of ret. The caller therefore does not receive a conventional negative error code from this function.

Risk classification: API-contract hazard. It may be an intentional firmware response convention in this downstream tree, but the current source alone does not establish that. The Linux 5.1 port must trace all callers and the expected failure representation before changing the signature or return behavior. Do not silently convert it to 0, ULONG_MAX, or a negative errno without updating and validating every consumer.

## 3. Porting and validation gates

| Gate | Required evidence | Status |
|---|---|---|
| RAE sequence address coverage | Every sequence PA resolves through the Exynos9610 map | Not yet audited exhaustively |
| RAW_WAIT reachability | All occurrences enumerated and call paths classified | Not yet audited exhaustively |
| MMIO ordering | Vendor access semantics compared with v5.1 ARM64 primitives | Not started |
| ACPM DT node ordering | Early CAL node and DVFS platform node relationship proven | Source path identified; runtime unverified |
| ACPM IPC ABI | Firmware command/channel/shared-memory contract documented | Not complete |
| DVFS error contract | All callers and error expectations traced | Not complete |
| Linux 5.1 compile | CAL/PMUCAL/ACPM objects compile and link | Not run |
| Device validation | Boot, DVFS, suspend/resume, thermal and storage tested | Not performed |

## 4. Next source-analysis sequence

1. Enumerate PMUCAL_RAW_WAIT occurrences across all Exynos9610 sequence data and determine whether they are selected by the A50 configuration.
2. Build a complete symbol-to-object map for pmucal_rae_init(), pmucal_system_init(), pmucal_local_init(), pmucal_cpu_init(), CP/GNSS/SHUB initializers, and ACPM DVFS calls.
3. Trace the ACPM IPC channel request implementation, DT compatible strings, mailbox/IRQ resources, shared-memory mapping, and response timeout behavior.
4. Trace every caller of exynos_acpm_get_rate() and record its failure handling.
5. Compare the required Linux APIs with v5.1 before making the first CAL compatibility patch.
6. Keep the Exynos9610 clock provider disabled until all required CAL/PMUCAL/ACPM dependencies compile and their init order is validated.

## Safety

- No vendor source implementation was changed.
- No Linux 5.1 Exynos9610 build or boot test is claimed.
- No release, flashable ZIP, or boot image was produced.
- Preserve the working Linux 4.14.357 recovery baseline.
- All future modifications remain restricted to the user's fork; the SOVR-Technologies repository is reference-only.
