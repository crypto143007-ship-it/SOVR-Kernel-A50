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


## 5. Phase 2 follow-up: RAW_WAIT is present in the unconditional LPM initialization sequence

This follow-up supersedes the earlier statement that A50 reachability had not been established.

### 5.1 Exact source occurrence

The Exynos9610 source header `drivers/soc/samsung/cal-if/exynos9610/pmucal_system_exynos9610.h` defines the array `pmucal_lpm_init[]`. It contains exactly one `PMUCAL_RAW_WAIT` descriptor in the inspected system sequence data:

```c
PMUCAL_SEQ_DESC(PMUCAL_RAW_WAIT, "OSC_CON0_OSC",
                0x11860000, 0x0c00,
                (0x1 << 29), (0x1 << 29),
                0, 0, 0xffffffff, 0),
```

The descriptor polls PMU register physical base 0x11860000, offset 0x0c00, until bit 29 is set.

### 5.2 Initialization call chain establishes reachability

The source path is:

1. Both A50 core and default defconfigs set `CONFIG_SOC_EXYNOS9610=y` and `CONFIG_PMUCAL=y`.
2. `drivers/soc/samsung/cal-if/Makefile` selects `pmucal_system.o` and `pmucal_rae.o` under `CONFIG_PMUCAL`, and selects `exynos9610/cal_data.o` under `CONFIG_SOC_EXYNOS9610`.
3. `exynos9610/cal_data.c` includes `pmucal_system_exynos9610.h`, defining the A50 SoC LPM init data.
4. `cal_if_init()` calls `pmucal_system_init()` and propagates any negative return.
5. `pmucal_system_init()` converts the full `pmucal_lpm_init[]` array through `pmucal_rae_phy2virt()`, then calls `pmucal_rae_handle_seq(pmucal_lpm_init, pmucal_lpm_init_size)`.
6. `pmucal_rae_handle_seq()` dispatches `PMUCAL_RAW_WAIT` directly to `pmucal_rae_raw_wait()`.
7. `pmucal_rae_raw_wait()` loops until bit 29 reads as set. It has no timeout, delay, `cpu_relax()`, or error return.

Conclusion: this is not merely an unused optional sequence descriptor. It is part of the PMUCAL system initialization array executed by the A50 CAL initialization path when that path is enabled. A failure of the oscillator-ready condition can therefore hang the CPU in early CAL initialization rather than return an error to the caller.

### 5.3 Correct risk assessment

Risk: **critical boot-time hang path**, conditional on the hardware register bit not reaching the expected state. The normal hardware transition is not proven faulty; this audit identifies the consequence if the condition does not complete.

Do not change the wait semantics until the hardware requirement and expected oscillator startup latency are understood. A safe future patch must:
- determine the documented maximum oscillator startup time and any required sequencing constraints;
- choose a timeout with sufficient hardware margin based on specifications or validated traces;
- emit register value and sequence index on timeout;
- propagate `-ETIMEDOUT` through `pmucal_system_init()` and `cal_if_init()`;
- confirm that aborting this initialization sequence is safer than proceeding with incomplete clock/oscillator setup;
- validate cold boot, warm reboot, suspend/resume, and repeated boot cycles on physical A50 hardware.

A timeout is not automatically safe: if the oscillator is required for subsequent clock setup, returning an error may still prevent boot, but it converts an indefinite silent hang into a diagnosable failure. The hardware recovery strategy must be determined before implementation.

### 5.4 Source-level occurrence count boundary

The six inspected Exynos9610 sequence headers (system, local, CPU, CP, GNSS, SHUB) contain one active `PMUCAL_RAW_WAIT` occurrence, in the system LPM init array. Other `PMUCAL_WAIT` operations are bounded by `pmucal_rae_wait()`; commented-out descriptors are not active sequence entries. This count applies to these six checked files, not to unrelated SoC data or future revisions.

### 5.5 Updated status

| Gate | Updated status |
|---|---|
| RAW_WAIT active occurrence in Exynos9610 data | One active occurrence found |
| A50 configuration selects PMUCAL and Exynos9610 CAL data | Confirmed in both checked defconfigs and Makefile |
| RAW_WAIT included in system LPM init array | Confirmed |
| LPM init array executed by pmucal_system_init | Confirmed |
| Hardware bit-29 normal/maximum startup timing | Not established |
| Runtime failure reproduction on A50 | Not performed |
| Timeout patch safety and recovery | Not yet established |


## 6. Phase 2 follow-up: A50 PMUCAL data selection and P2V map spot-check

### 6.1 A50 selects the system PMUCAL path

Both `exynos9610-a50_core_defconfig` and `exynos9610-a50_default_defconfig` enable `CONFIG_PMUCAL=y` and `CONFIG_SOC_EXYNOS9610=y`. The CAL Makefile selects the generic PMUCAL system/RAE objects and Exynos9610 `cal_data.o` with those symbols. The SoC data translation unit includes the Exynos9610 PMUCAL system header.

This independently confirms that the system LPM init array containing the oscillator RAW_WAIT is part of the configured A50 build inputs.

### 6.2 P2V mapping inventory

The Exynos9610 P2V table contains 58 `DEFINE_PHY()` entries. The active PMUCAL sequence data uses the expected mapped register regions for the system, local, CPU, CP, GNSS and SHUB sequence families.

One CP sequence header line refers to physical base `0x12300000`, but it is explicitly commented out in the source. It is not an active sequence descriptor and must not be treated as a missing active mapping. It should remain commented unless the CP sequence is deliberately re-enabled and its mapping is validated.

This is a source-level spot-check, not a complete generated parser proof of every sequence's base and condition address. The exhaustive address-coverage gate therefore remains open until a parser that handles multiline macro arguments and C preprocessor branches is run against the exact selected configuration.

### 6.3 Updated engineering decision

- Do not disable PMUCAL as a workaround: it is a dependency of the A50 clock/power integration, and disabling it would mask rather than solve the oscillator initialization issue.
- Do not edit the vendor sequence table or change the RAW_WAIT operation yet.
- Prioritize finding the oscillator ready-bit timing specification and validating the expected startup transition on known-good hardware.
- Keep all source changes on the fork's migration branch and retain the known-good 4.14 recovery path.


## 7. Phase 3: exact oscillator sequence ordering and wait semantics

A focused reread of the complete descriptor and RAE implementation establishes the following ordered operations in `pmucal_lpm_init[]`:

1. Write bit 31 to `OSC_CON0_OSC` at physical base `0x11860000`, offset `0x0c00`.
2. Poll the same register until bit 29 reads as 1, using `PMUCAL_RAW_WAIT`.
3. Only after the poll succeeds, write bit 4 to the same register.
4. Continue with reference-clock PMU and oscillator mux configuration.

The poll compares `(readl_value & BIT(29)) == BIT(29)`. It does not test bit 31, and it does not test a transition or a timeout counter.

The RAE implementation confirms:
- `PMUCAL_WAIT` uses a 1-microsecond delay and returns `-ETIMEDOUT` after its approximately 1 ms loop.
- `PMUCAL_RAW_WAIT` is a tight `while (1)` loop around `__raw_readl()`; it does not call `udelay()`, `cpu_relax()`, or a scheduler/yield primitive.
- The sequence dispatcher does not have a return value to propagate from the RAW_WAIT helper because the helper returns `void`.
- `pmucal_system_init()` invokes the full LPM init sequence after P2V conversion and propagates errors from the sequence dispatcher to `cal_if_init()`.

This clarifies the failure mode: if bit 29 never asserts after bit 31 is written, the executing CPU remains in the RAW_WAIT loop and the remaining oscillator/reference-clock setup is never performed. The source does not establish what bit 29 physically represents, its maximum assertion latency, or whether any silicon revision requires a special wait policy. Those facts must come from the Exynos9610 register guide, validated vendor documentation, or measured traces; they must not be guessed from the field name.

### Required evidence before a code change

- Identify the exact OSC_CON0_OSC register definition and bit-29 field description from the Exynos9610 PMU register guide.
- Determine whether bit 29 is a sticky ready/status bit, a handshake acknowledgement, or another condition.
- Establish documented min/max assertion latency and any clock-source prerequisites.
- Confirm the sequence is identical in the known-good A50 vendor kernel/release used as the recovery baseline.
- If adding diagnostics or a timeout, preserve the write-bit31 -> wait-bit29 -> write-bit4 ordering and ensure failure cannot proceed into the reference-clock mux steps with an unready oscillator.
- Prefer a narrowly scoped timeout with an evidence-based bound and explicit failure propagation over a global change to every PMUCAL RAW_WAIT. Do not merge or flash such a patch until cold/warm boot and suspend/resume have been validated.

No kernel implementation was modified as part of this phase. This is a source-analysis update only.


## 8. Phase 4: PMUCAL descriptor-to-P2V source audit

A balanced-parenthesis, string-aware macro argument scan was run over the six Exynos9610 PMUCAL sequence headers after removing C block and line comments. The scan recognizes all ten arguments of `PMUCAL_SEQ_DESC`; it does not assume descriptors fit on one line.

### 8.1 Source inventory

| Sequence header | Descriptor definitions | Active RAW_WAIT descriptors in source |
|---|---:|---:|
| pmucal_system_exynos9610.h | 2,344 | 1 |
| pmucal_local_exynos9610.h | 373 | 0 |
| pmucal_cpu_exynos9610.h | 51 | 0 |
| pmucal_cp_exynos9610.h | 34 | 0 |
| pmucal_gnss_exynos9610.h | 31 | 0 |
| pmucal_shub_exynos9610.h | 35 | 0 |
| **Total** | **2,868** | **1** |

The P2V table contains 58 literal `DEFINE_PHY()` entries.

### 8.2 Address coverage result

For every parsed descriptor in these six files:
- Every nonzero literal base physical address matched an entry in the P2V table.
- Every nonzero literal condition-base physical address matched an entry in the P2V table.
- A literal zero condition-base is a sentinel meaning no separate condition register; it is intentionally excluded from P2V lookup.
- No nonzero literal unmapped address was found.
- No non-literal base/condition-base expression was found by this scan.

This corrects an earlier preliminary scan that mistakenly treated the valid zero sentinel as an unmapped address. It also confirms the previously noted `0x12300000` CP address does not occur in an active descriptor after C comments are stripped.

### 8.3 Limits of this result

This is a lexical source audit, not a full C preprocessor evaluation. It counts descriptor definitions after comment removal, including any definitions inside conditional-compilation branches. It does not prove every descriptor is linked into a particular binary or reachable at runtime. A full configuration-specific result still requires preprocessing with the exact A50 defconfig, include paths, generated headers, and compiler flags.

The scan also validates address membership, not mapping correctness: it does not prove the physical register exists on every board revision, the mapping size is sufficient, or the register access is safe at every call site.

### 8.4 Reference repository comparison

The exact blob SHA for `pmucal_system_exynos9610.h` and `pmucal_p2vmap_exynos9610.h` in the separately supplied Vothcito reference repository matches the fork's corresponding blobs. This confirms the files are byte-identical at the checked revision, but it is not independent corroboration of the hardware sequence or register semantics.

### 8.5 Updated status

| Gate | Status |
|---|---|
| Nonzero literal PMUCAL base-address membership | Passed for six scanned headers |
| Nonzero literal PMUCAL condition-base membership | Passed for six scanned headers |
| Zero condition-base sentinel handling | Corrected and documented |
| Preprocessor-selected descriptor inventory | Still open |
| Register-map correctness / silicon revision coverage | Not established |
| OSC bit-29 hardware meaning and timing | Not established |
| Linux 5.1 compile and A50 runtime validation | Not performed |

No kernel source implementation was changed. This phase adds reproducible source-audit findings only.
