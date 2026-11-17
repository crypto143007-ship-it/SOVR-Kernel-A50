# Exynos9610 Galaxy A50 Linux 5.1 integration branch

## Immutable base

- Upstream repository: https://github.com/torvalds/linux
- Release: Linux v5.1
- Base commit: `e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd`
- This branch was created directly from that commit.
- This branch is separate from `migration/linux-5.1-assessment`; the existing vendor tree and its audit history are preserved.

## Scope

This branch is the clean upstream integration workspace for the Samsung Galaxy A50 SM-A505F / Exynos9610 port. It does not yet contain Samsung vendor code, A50 defconfigs, DTBs/DTBOs, firmware blobs, or a bootable device image.

## Porting rules

1. Keep the pinned upstream base identifiable; record every imported vendor source and its origin.
2. Port only the minimum dependency closure required for Exynos9610 boot, then expand subsystem coverage.
3. Keep Kconfig and Kbuild integration explicit; do not add vendor objects unconditionally.
4. Preserve firmware ABI, DT resource order, clock IDs, PMUCAL sequencing and secure-world dependencies.
5. Add SRAM/firmware bounds checks and robust error unwinding before enabling ACPM IPC.
6. Do not import the Vothcito Linux 5.15 branch wholesale; use it only as a comparative reference.
7. Do not copy permissive SELinux boot arguments or unverified board overlays.
8. Do not claim build, boot, or runtime success until the corresponding reproducible test evidence exists.

## Initial subsystem order

1. Build and configuration infrastructure / cross-compiler baseline.
2. Exynos9610 SoC identification, GIC, timer, pinctrl and interrupt dependencies.
3. Samsung CAL / CMUCAL / PMUCAL and clock provider.
4. ACPM IPC, firmware shared-memory ABI and DVFS.
5. TZDEV / TEEGris and TZAR deployment path.
6. Regulators, PMIC, thermal, UFS, IOMMU and power management.
7. Display, touch, audio, modem and connectivity.
8. A50 DTB/DTBO composition and Android boot integration.

## First integration gate

Before importing code, establish a clean upstream v5.1 ARM64 build from this exact branch and retain its build log/configuration. Then add the smallest Exynos9610 platform patch set and compile after each subsystem.

No code is imported in this initial commit. No image is intended for flashing.


## Baseline source audit — upstream v5.1 platform gaps

Inspected the pinned v5.1 source files directly:

- `arch/arm64/Kconfig.platforms`
- `arch/arm64/boot/dts/Makefile`
- `arch/arm64/boot/dts/exynos/Makefile`
- `drivers/soc/samsung/Kconfig` and `Makefile`
- `drivers/clk/samsung/Kconfig` and `Makefile`

### What already exists

- Generic ARM64 Samsung Exynos platform selection exists as `ARCH_EXYNOS`.
- It selects the common Samsung clock framework, Exynos PMU, Exynos power domains (when enabled), and Exynos pinctrl.
- The upstream Exynos ARM64 DTB Makefile includes Exynos5433 TM2/TM2E and Exynos7 Espresso targets.
- Generic Samsung SoC infrastructure includes Exynos PMU and PM-domain support.
- The generic Samsung ARM64 clock framework includes Exynos5433/Exynos7 support.

### What is absent from this upstream v5.1 baseline

- No Exynos9610 SoC DTB target in `arch/arm64/boot/dts/exynos/Makefile`.
- No A50 SM-A505F board DTS/DTBO.
- No Exynos9610 clock-controller implementation or clock-ID binding integration.
- No vendor CAL/CMUCAL/PMUCAL Exynos9610 implementation in the generic Samsung SoC Kconfig/Makefile inspected.
- No Exynos9610 ACPM IPC/DVFS driver integration in the generic Samsung SoC Kconfig/Makefile inspected.
- No A50-specific defconfig in the clean upstream tree.

### Implications

Do not add a superficial `CONFIG_SOC_EXYNOS9610` symbol and claim the platform is ported. The platform needs a dependency graph and explicit Kconfig/Kbuild wiring for each imported component. Generic `ARCH_EXYNOS` selection alone is insufficient to initialize this SoC.

### Next source-port task

The first code patch should add only the SoC identification and minimal DT/Kconfig wiring needed to compile a non-booting Exynos9610 DTB, while leaving clock providers disabled until their driver and binding dependencies are imported. Then port the timer/GIC/interrupt/pinctrl dependencies, followed by CAL/clock and ACPM. Every patch must be built against the pinned v5.1 tree before proceeding.


## Comparative source audit — Exynos9610 reference port (2026-11-17)

Reference inspected read-only:
- Repository: `Vothcito/android_kernel_samsung_exynos9610_a50`
- Branch: `exynos9610-port`
- Repository description identifies it as a work-in-progress Linux 5.15 A50 port.
- This is a comparative source reference only. No write access was available or used, and no source has been copied into this integration branch in this audit.

### Confirmed reference assets

The reference branch contains a substantial Exynos9610 platform source set:
- Generic SoC DTS: `arch/arm64/boot/dts/exynos/exynos9610.dts` (100,826 bytes; blob `cc5814a86d1dac1215e37da6774db0a1ba581c00`).
- A50 universal board overlay: `exynos9610-universal9610.dts` (30,932 bytes; blob `eadc27822e505fc989274984097cbf4b7e32ffbd`).
- Dedicated pinctrl, reserved-memory, debug, PM-domain, SysMMU, MFC, camera, display and TMU DTS fragments.
- Exynos9610 clock driver: `drivers/clk/samsung/clk-exynos9610.c` (28,338 bytes).
- Exynos9610 CAL data and generated register/clock tables under `drivers/soc/samsung/cal-if/exynos9610/`, including large CMUCAL and PMUCAL tables.
- Exynos9610 clock binding header: `include/dt-bindings/clock/exynos9610.h`.
- Additional Samsung DT bindings under `include/dt-bindings/soc/samsung/`.

The reference Exynos9610 DTS includes more than a simple CPU/GIC description. Its include closure pulls in clock, pinctrl, reserved memory, debug snapshot, thermal, UFS, SysMMU, power-domain, devfreq, MFC and camera definitions. The node compatible inventory also includes Exynos9610 clock, MCT, Speedy, ACPM/IPC/DVFS, pinctrl, USI, HSI2C, SPI, UART, ABOX and other vendor-specific devices. These compatibles require corresponding drivers or must remain deliberately disabled until their implementations are ported.

### Critical board-overlay warning

The reference `exynos9610-universal9610.dts` contains a bootargs string with `androidboot.selinux=permissive`, vendor firmware paths, fixed reserved-memory assumptions and Samsung-specific boot setup. It is a vendor overlay, not a safe upstream A50 DTS to import verbatim.

For this project:
- Never copy permissive SELinux boot arguments into the upstream integration.
- Do not assume the reference memory map, reserved-memory layout, initrd addresses, partition names or firmware paths match the target A50 ROM/boot chain.
- Keep board-specific properties separate from the SoC-level DTS.
- Derive the actual A50 board description from the known SM-A505F device tree and bootloader/firmware contract, then validate every reserved-memory and peripheral resource.

### Version and ABI compatibility gate

The reference is a Linux 5.15 work-in-progress tree, while the target is upstream Linux 5.1. The presence of a driver or DTS node in the reference does not establish that it is source/API compatible with 5.1. In particular, the Exynos9610 clock driver, Samsung CAL/PMUCAL, ACPM, pinctrl, SysMMU and power-domain integration need per-file API and Kconfig/Kbuild review.

Do not import the complete 100-KiB DTS as a first patch. Its dependencies include binding headers and many drivers absent from upstream v5.1. The correct first code milestone is a deliberately minimal SoC DTS fragment with only validated architectural resources (GIC/timer/PSCI/CPU topology and required early console if proven), followed by one dependency group at a time. Keep unsupported devices disabled or omit their nodes until the driver exists.

### Next implementation work

1. Compare the reference Exynos9610 SoC DTS and the existing 4.14 vendor DTS structurally, not by filename alone.
2. Extract the minimal early-boot hardware description and verify its interrupt IDs, address ranges, PSCI interface and CPU topology against the A50 hardware/vendor DT.
3. Audit upstream v5.1 availability for each required binding and driver.
4. Port the Exynos9610 clock binding and clock driver only together with its complete helper/header dependencies and a Kconfig symbol that does not accidentally enable unsupported clock controllers.
5. Keep CAL/PMUCAL and ACPM out of the first DTS-only compile milestone; integrate them only after their ABI and initialization order are reviewed.
6. Build the DTB with the v5.1 in-tree DTC and validate it with dtc warnings and schema checks where supported.

### Current integration status

No executable source, DTS, Kconfig or Makefile was changed in this audit. Only this integration-plan document was updated. There is still no target-tree compile, DTB build, boot image or hardware boot result.


## Phase 10 — first-boot DTS contract audit (2026-11-17)

Inspected the reference SoC DTS (blob `cc5814a86d1dac1215e37da6774db0a1ba581c00`) and A50 overlay (blob `eadc27822e505fc989274984097cbf4b7e32ffbd`).

### Reference early-boot facts — not yet accepted as upstream values

- Eight CPU nodes: four Cortex-A53 cores (MPIDR 0–3) and four Cortex-A73 cores (MPIDR 0x100–0x103).
- CPU enable method is PSCI.
- Vendor PSCI node uses SMC and function IDs CPU_SUSPEND `0xC4000001`, CPU_OFF `0x84000002`, CPU_ON `0xC4000003`.
- Reference GIC uses `arm,cortex-a15-gic`, `arm,cortex-a9-gic` with distributor/CPU/virtual/hypervisor regions at 0x12301000, 0x12302000, 0x12304000 and 0x12306000.
- Architectural timer PPIs are 13, 14, 11 and 10 with an 8-CPU mask.
- Vendor timer node also contains 26-MHz clock-frequency and non-standard properties.

### Porting decisions

1. Confirm MPIDR affinity and cluster topology against SM-A505F hardware and the actual boot DT.
2. Do not copy vendor PSCI function IDs without confirming firmware PSCI version, conduit and ABI. Prefer standard PSCI binding semantics when supported.
3. Check the GIC compatible and four-region layout against Linux v5.1 GIC driver match data and hardware documentation; do not infer GIC-400 solely from the SoC family.
4. Use standard architectural timer properties only; vendor extensions require a Linux 5.1 consumer and hardware evidence.
5. Keep RAM banks, initrd addresses, reserved memory, ECT and bootargs out of the SoC-level first patch until the exact A50 boot-chain contract is verified.
6. Preserve correct address/size cell widths in all reg tuples.

### First patch gate — blocked pending device evidence

Required: actual SM-A505F boot DTB/DTBO or live DT dump; verified memory/reserved-memory map; GIC layout and interrupt routing; PSCI version/conduit/function behavior; and a successful v5.1 DTC build.

No DTS/Kconfig/Kbuild source was changed in this phase. This avoids committing a plausible but unverified early-boot description that could hang before console initialization. Next obtain `/sys/firmware/fdt` or the original DTB/DTBO and reconcile it with the reference before writing boot-critical nodes.


## Phase 11 — uploaded live DTB and SOVR 4.2 base-DTB reconciliation (2026-11-17)

The two user-supplied artifacts were inspected as binary inputs:

- `A50_live.dtb` is a raw FDT (219,477 bytes).
- `dtb.img` is an Android DT table image (134,948 bytes), with one table entry; its FDT payload begins at offset 64 and is 134,884 bytes.
- The live FDT bootargs include `androidboot.dtbo_idx=5`. Device-specific bootargs and identifiers are intentionally excluded from repository documentation.
- The uploaded SOVR artifact is the base DTB table/payload only. No matching SOVR 4.2 `dtbo.img` was included.

### Findings that can be accepted from the uploaded blobs

- Both trees describe eight CPUs (four Cortex-A53 and four Cortex-A73), PSCI using SMC, the same GIC compatible list and four register windows, and the same architectural timer PPI list.
- The timer clock-frequency property is `0x018cba80`, i.e. 25.6 MHz.
- The live tree declares four memory banks totalling 3.892578125 GiB. The SOVR base payload declares three 2-GiB banks totalling 6 GiB.
- The live FDT is the running device's post-boot-chain tree; the SOVR file is only the base DTB. Because the live bootargs report a DTBO selection index and the corresponding SOVR overlay image is absent, the memory-map and node/status deltas are not a valid final-tree-to-final-tree comparison.

### Implementation gate

Do not create or import the A50 memory/reserved-memory nodes from the SOVR base payload. Do not conclude that SOVR 4.2 targets a 6-GiB A50 from the base payload alone. Obtain the exact matching SOVR 4.2 `dtbo.img` (and its build/selection metadata if available), identify the selected overlay corresponding to the boot chain, and compare the resulting composed tree with the live FDT. Reconcile the live RAM banks with `/proc/iomem`, `MemTotal`, and reserved/secure carveouts before writing board memory nodes.

The CPU/PSCI/GIC/timer observations are evidence for a candidate minimal DTS only; each binding and driver still needs checking against upstream Linux v5.1. No boot-critical DTS source was added in this phase. No kernel/DTB build or hardware boot is claimed.


## Phase 12 — reproducible upstream ARM64 baseline CI (2026-11-17)

Added `.github/workflows/arm64-upstream-baseline.yml` on this integration branch. It runs on branch changes to kernel build/source paths and supports manual dispatch. The job installs an ARM64 cross-toolchain, generates the clean upstream ARM64 `defconfig`, builds `Image` and the upstream ARM64 DTB set, and publishes the build outputs plus `.config` as an Actions artifact.

This is deliberately a **generic upstream Linux v5.1 baseline check**, not an Exynos9610/A50 kernel build: the current upstream tree still has no Exynos9610 DTS target or A50 defconfig. A green run will prove only that the pinned upstream baseline builds in CI; it will not prove A50 hardware support or bootability. The first workflow result remains pending verification.
