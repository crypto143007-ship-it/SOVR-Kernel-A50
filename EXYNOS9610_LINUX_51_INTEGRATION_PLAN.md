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


## Phase 13 — upstream ARM64 build artifact verified (2026-11-18)

A successful GitHub Actions run was inspected, and its uploaded artifact was downloaded and examined locally.

- Workflow run: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50/actions/runs/44234009108
- Run conclusion: `success`; all nine job steps completed successfully.
- Build source: immutable upstream Linux v5.1 commit `e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd`.
- Configuration: upstream `defconfig`, with `CONFIG_ARCH_EXYNOS=y`.
- Build targets: ARM64 `Image` and generic upstream `dtbs`.
- Artifact: `linux-v5.1-upstream-arm64-baseline` (10,317,555 bytes; 14-day retention at upload).
- Image: 20,492,800 bytes; SHA-256 `d0a9ed65f62228b40245728fe8e16ff7c4c00463b35ea3f3dcdc140a589542a6`.
- Artifact contains 231 DTBs. Its Exynos outputs are only `exynos5433-tm2.dtb`, `exynos5433-tm2e.dtb`, and `exynos7-espresso.dtb`.

### What this proves

The pinned upstream Linux v5.1 tree can be configured and cross-compiled for generic ARM64 in the CI environment. The previous compiler-path and legacy host-DTC failures are resolved for this baseline job.

### What this does not prove

This artifact contains no Exynos9610 DTB and no A50 board DTB/DTBO. `CONFIG_ARCH_EXYNOS=y` is generic Exynos ARM64 support only. No Samsung Exynos9610 vendor CAL/CMUCAL/PMUCAL, clock-controller, ACPM, A50 board DTS, or device-specific defconfig was compiled. The generated Image is **not** an A50 boot image and must not be flashed.

### Branch-state clarification

The branch `linux-5.1-exynos9610-integration` remains a clean upstream Linux v5.1 integration workspace with audit/plan documents; it is not yet a vendor-integrated kernel. A direct compare against the pinned upstream base reports 14 commits ahead, 0 behind, and the listed changes are documentation/workflow additions. No executable Exynos9610 driver, DTS, Kconfig or Kbuild port has been committed yet.

### Next implementation gate

The next code patch must be deliberately small and reviewable:
1. Add only the Exynos9610 SoC DTS source and its includes needed for parsing, based on the reference source but without copying unverified RAM/reserved-memory, firmware, or peripheral enablement.
2. Add an isolated Exynos9610 DTB Makefile target only after the source's exact includes and compatible bindings are reconciled against the uploaded live A50 FDT and selected overlay.
3. Compile the new DTB with upstream v5.1 DTC; inspect all warnings and decompile it for structural comparison.
4. Keep the clock provider, CAL/PMUCAL and ACPM disabled until their source/API/Kconfig dependency closures are separately ported and built.

The existing live-vs-SOVR DTB audit shows that memory/reserved-memory and overlay composition are not yet safe to reconstruct from the SOVR base DTB alone. Do not fabricate a minimal bootable A50 DTS from incomplete evidence.


### Integration-branch CI confirmation

The integration branch's own workflow also completed successfully:

- Run: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50/actions/runs/44138869824
- Job: `arm64-baseline`; every step succeeded.
- Artifact: `linux-v5.1-arm64-upstream-baseline` (10,243,680 bytes; artifact ID `14354471777`).
- Downloaded artifact inspection: 231 DTBs and one ARM64 Image (20,492,800 bytes; SHA-256 `5361b85304b5f8be83de720fc43f8e5aad951172e8a4240901ce1c0812e3d753`).
- Exynos DTBs are again only Exynos5433 TM2/TM2E and Exynos7 Espresso. No Exynos9610/A50 DTB is present.

This is a successful build of the clean upstream integration branch itself, not merely the separate assessment branch. The artifact still contains no A50-specific `.config`; the workflow builds generic upstream `defconfig`.

**Current status remains: upstream ARM64 baseline green; Exynos9610 vendor integration not yet implemented.** No Image from either baseline artifact is suitable for A505F flashing.


## Multi-SKU memory support policy — Galaxy A50 4 GB and 6 GB

**Project target is the Galaxy A50 family, not only the 4 GB SM-A505F unit used for initial bring-up.** The port must retain support for both 4 GB and 6 GB RAM retail variants wherever the same Exynos9610 board/platform and boot chain are compatible.

### Required design

1. Keep one shared Exynos9610 SoC description and a shared A50 board base wherever hardware is common.
2. Do not hardcode the 4 GB memory map into the common SoC DTS.
3. Prefer the bootloader-provided, validated /memory node when the A50 boot chain supplies correct RAM banks. Verify this on representative 4 GB and 6 GB devices before relying on it.
4. If a board DTB must declare RAM explicitly, provide clearly named SKU-specific board DT variants (4 GB and 6 GB) that differ only in verified memory-bank reg values and any genuinely SKU-specific reserved-memory carveouts. Do not create two unrelated kernels or duplicate the whole SoC DTS.
5. Treat reserved-memory as independent of advertised RAM capacity: derive each carveout from the actual firmware/bootloader contract, ensure it lies wholly inside installed physical RAM where required, and check for overlap. Never scale or copy carveouts merely by adding 2 GB.
6. At boot, validate the final memory map using /proc/iomem, kernel boot log (Memory: and reserved lines), memblock debug output when available, and Android userspace MemTotal. Confirm the 4 GB and 6 GB variants separately.
7. Do not infer installed RAM solely from a product name, model suffix, or a userspace property. A wrong DT memory node can hide RAM or expose nonexistent memory and can cause memory corruption.
8. Keep common kernel configuration and drivers identical across memory SKUs unless hardware evidence demonstrates a real board difference. RAM capacity alone must not require a separate kernel binary.

### Validation matrix

| Device class | Required validation |
|---|---|
| A50 4 GB | Correct bank sizes/base addresses; no out-of-range RAM; no carveout overlap |
| A50 6 GB | Correct larger bank(s) as actually reported by bootloader; no truncation to 4 GB |
| Both | UFS, CMA, secure/TEE, firmware and multimedia carveouts remain valid; stable cold boot and memory stress |

### Current evidence and limitation

The current bring-up handset is the 4 GB SM-A505F. Its memory map cannot be used to manufacture a 6 GB map. No 6 GB live FDT/DTB or /proc/iomem capture has yet been verified in this workspace. Therefore 6 GB support is an explicit release requirement, but the exact 6 GB bank layout remains unverified until evidence from a real 6 GB A50 variant is available.

### Release gate

Do not mark the A50 family port complete, publish it as supporting 6 GB, or ship a fixed-memory DTB until both 4 GB and 6 GB boot paths have passed memory-map and stress validation. If bootloader-supplied memory discovery is confirmed on both, prefer that shared path over hardcoded SKU-specific memory sizes.


### Authoritative SOVR / Samsung memory-map baseline (project decision)

The three-bank memory declaration below is **not merely a Vothcito reference**. It is present in the original SOVR Exynos9610 DTS and in the Samsung stock DTB extracted from the user's original stock firmware archive. The user confirms that their physical 4 GB A50 boots and runs the existing SOVR kernel using this arrangement. Therefore this exact three-entry layout is the compatibility baseline for the migration and must not be removed, collapsed into one contiguous range, resized to 4 GiB, or otherwise "corrected" solely because the handset is sold as a 4 GB model.

The Vothcito Linux 5.15 reference `arch/arm64/boot/dts/exynos/exynos9610.dts` and original SOVR DTS both declare:

- `0x00000000_80000000`, size `0x80000000` (2 GiB)
- `0x00000008_80000000`, size `0x80000000` (2 GiB)
- `0x00000009_00000000`, size `0x80000000` (2 GiB)

The Samsung stock archive supplied for the 4 GB handset contains `boot.img`, `dt.img` and `dtbo.img`; the base DTB extracted from `dt.img` carries the same three-bank declaration. This is direct stock/SOVR agreement, and the user's report establishes that the existing SOVR boot chain operates on the 4 GB handset with it. The DTB declaration must be preserved as part of the known-good boot contract.

Important interpretation: the three DTB entries describe the declared physical address ranges, not a statement that the 4 GB handset has 6 GiB of installed or usable RAM. Do not infer usable capacity from the sum of DTB `reg` entries alone. Preserve the bank layout and let the same known-good SOVR/bootloader memory-discovery and reservation behaviour determine what Linux actually manages. During migration, compare the final flattened/live FDT, memblock logs, `/proc/iomem`, reserved-memory nodes and DMA limits against the working SOVR behaviour. Do not introduce a new memory filtering policy without evidence that it is required.

### Multi-SKU rule

For the 4 GB target, preserve the exact Samsung/SOVR three-bank declaration and boot flow. For 6 GB A50-family targets, use the same SOVR baseline unless verified stock firmware or live-device evidence demonstrates a genuine SKU-specific difference. Do not invent a different 6 GB map, and do not make RAM capacity alone a reason to fork the kernel or alter the shared SoC DTS. Both capacities remain release targets, but only the 4 GB handset has been confirmed by the user as running this exact SOVR arrangement.

### Validation gate

Before changing any memory-related property or memory initialization code, compare the Linux 5.1 result with the known-good SOVR kernel on the 4 GB handset: final FDT, memblock bank list, reserved-memory carveouts, CMA, secure/TEE and multimedia regions, DMA masks, and stress-test results. A mismatch must be explained before device testing. The 6 GB release target still requires a real 6 GB device or stock firmware evidence before claiming verified support.


## First Exynos9610 SoC DTS integration — 2026-11-18

A first real device-tree source integration has now been committed to the Linux 5.1 branch (commit `93e50791b18f81a71209e592db411783a5773666`). This is beyond the earlier Kconfig-only smoke test.

### Source selection

- The base `arch/arm64/boot/dts/exynos/exynos9610.dts` was taken from the original SOVR main repository, because the user's explicit priority is to preserve the existing SOVR hardware/boot behaviour.
- The supporting Exynos9610 SoC `.dtsi` files and missing DT binding headers were taken from Vothcito's `exynos9610-port` reference.
- The SOVR and Vothcito top-level `exynos9610.dts` files are not byte-identical. The SOVR copy is therefore deliberately the target base; Vothcito remains the supplementary source for missing includes/bindings, not an override of SOVR's base DTS.

### Files added

- SoC DTS: `exynos9610.dts`.
- Includes: pinctrl, reserved-memory, debug, SysMMU, PM domains, MFC, camera, and TMU sensor configuration.
- Binding headers: Exynos9610 clocks, DM, devfreq, BCM debug, debug snapshot, secure log, SysMMU, FIMC-IS, power domains, and UFS.
- `arch/arm64/boot/dts/exynos/Makefile` now lists `exynos9610.dtb` under `CONFIG_ARCH_EXYNOS`.

The imported DTS is a SoC-level reference DTB, not yet the complete A50 product DTBO set. A50 board/revision overlays remain a separate next stage and must continue to match Samsung stock `dt.img`/`dtbo.img` selection.

### Memory compatibility rule

The SOVR base DTS retains the original three-bank `reg` entries at `0x80000000`, `0x880000000`, and `0x900000000`, each with a 2 GiB declared size. No memory entry was resized, collapsed, removed, or rewritten in this integration commit. Continue to treat this as the known-good SOVR DT declaration; do not equate the sum of declared address ranges with Linux-usable RAM on the user's 4 GB handset.

### Build validation

Commit `93e50791b18f81a71209e592db411783a5773666` triggered Actions run `44252241410`. The run was in progress when this entry was written. Its required gate is successful compilation of the new `exynos9610.dtb` together with the existing ARM64 Image/DTBs. A green generic build alone does not establish bootability or correct runtime driver support.

### Remaining work after DTB compile

1. Fix only concrete DTS compile errors exposed by CI; do not strip nodes or bindings merely to make the build green.
2. Compare the resulting DTB's three memory banks and reserved-memory nodes against the Samsung stock DTB and working SOVR output.
3. Add the A50 board/revision DTBO source set with stock revision mapping.
4. Port the required Linux 5.1 drivers for pinctrl, SysMMU, PM domains, clocks/CAL, ACPM and board devices in dependency order.


## Phase 14 — A50 DTB/DTBO CI and vendor-gap audit (2026-11-18)

The latest integration-branch workflow completed successfully:

- Run: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50/actions/runs/44351760573
- Run number: 25; commit: `0f3683000da19b252a0029b106de59645e143af8`.
- All nine substantive job steps passed, including ARM64 Image/DTB compilation, Exynos9610 A50 overlay compilation, overlay application to the Exynos9610 base DTB, Vothcito source inventory, vendor readiness audit and artifact upload.
- Artifact: `linux-v5.1-exynos9610-kconfig-smoke`, artifact ID `14449880694`, 10,388,201 bytes.

### What the new CI actually validates

- The in-tree Exynos9610 SoC DTB is included in the Linux v5.1 `dtbs` build.
- The SOVR-derived `exynos9610-universal9610.dts` overlay preprocesses, compiles with symbols/fixups, and applies to the compiled Exynos9610 base DTB using `fdtoverlay`.
- The merged FDT can be decompiled and contains a model property.
- The build is reproducible in the current Ubuntu 22.04 ARM64 cross-build environment.

### Warning debt — not resolved by the green exit status

The overlay compile emitted 71 DTC warning lines; decompiling the merged DTB emitted 273 warning lines. CI currently records these logs but does not classify or fail on them. The successful overlay application proves syntactic/link compatibility with this base DTB, not correctness of every peripheral resource, interrupt, DMA reference or runtime driver.

Next DT task: preserve both warning logs as review inputs, classify each warning by node/property, and fix only warnings whose correction is justified by the SOVR 4.2 / Samsung stock DT contract. Do not mass-delete nodes or suppress warnings to force a clean count.

### Vendor source inventory and upstream gaps

The pinned Vothcito reference branch `exynos9610-port` was cloned at commit `ace96fa34c0d8303a23c5518aae751a91274552b`. All seven specifically inventoried reference files exist there:

- CAL core: `cal-if.c`, `cmucal.c`.
- Exynos9610 CAL data and nodes: `cal_data.c`, `cmucal-node.c`.
- PMUCAL CPU header and common implementation.
- Samsung Exynos UFS host: `ufs-exynos.c`.

The upstream v5.1 integration tree still lacks all seven corresponding vendor files. The vendor readiness audit also confirms that the Samsung Exynos UFS host, Exynos9610 UFS CAL, UFS FMP, TZDEV, CAL/CMUCAL, Exynos9610 CAL data, PMUCAL, ACPM core/IPC and Mali platform source are absent. Generic UFS host/platform glue and legacy EROFS staging source are present; the latter is not the same layout as the later mainline `fs/erofs` implementation.

This is an inventory only. No Linux 5.15 vendor source was copied or compiled into v5.1 in this phase. Do not cherry-pick or copy these files wholesale: next inspect the CAL/CMUCAL dependency closure and compare its API, headers, Kconfig, Makefile and init ordering against v5.1 before importing a minimal buildable unit.

### Scope and safety

This remains an integration/build-validation artifact, not a bootable A505F release. No A50 Image/boot.img is produced or approved for flashing. Preserve the SOVR 4.2 three-bank memory declaration and the user's 4 GB + 6 GB family target; do not alter memory nodes based only on the arithmetic sum of DTB address ranges. The original upstream SOVR repository remains untouched.


## Safety correction — A50 live RAM map supersedes the three-bank carry-forward note (2026-11-19)

This section supersedes the earlier Phase 13 wording that described the SOVR 4.2 three-bank declaration as a known-good declaration to preserve.

The later uploaded live-device DTB versus SOVR 4.2 base-DTB audit found a material mismatch:

- Live A50 DTB: four fragmented banks at 0x80000000 (size 0x3ab00000), 0xc0000000 (0x20000000), 0xe1900000 (0x1e700000), and 0x880000000 (0x80000000).
- SOVR 4.2 base DTB: three banks at 0x80000000, 0x880000000, and 0x900000000, each declared as 2 GiB.
- The SOVR base DTB therefore declares a 6 GiB address range and is not a safe memory-map source for the user's 4 GiB SM-A505F.
- The live DTB's declared total is below nominal 4 GiB; reserved/secure carveouts and the final bootloader-selected DTBO must be reconciled before deriving usable RAM.

Required decision for this Linux 5.1 port:

1. Do not copy the SOVR 4.2 three-bank memory node into the A505F board DTS.
2. Treat the uploaded live DTB as the current device evidence, but verify its memory and reserved-memory ranges against the bootloader-selected final FDT, `/proc/iomem`, and `MemTotal`.
3. Obtain the matching SOVR 4.2 `dtbo.img` and determine which overlay is selected before drawing conclusions about SOVR's final board memory layout.
4. Keep the 4 GB and 6 GB A50 variants as separate, explicitly validated board configurations if their physical memory maps differ. Never infer installed DRAM from a DTB's declared sum.
5. No memory node is approved for a bootable Linux 5.1 image until all ranges are shown to be physically present, non-overlapping, and consistent with reserved/secure memory.

This is a documentation correction only. It does not modify DTS, DTB, boot images, or memory configuration. No A50 Linux 5.1 bootability is claimed.


## Phase 15 — verified A50 boot-chain, memory and Samsung DTBO contract (2026-11-19)

This section supersedes the conflicting memory/DTBO interpretations in earlier entries. Evidence provenance is limited to one live SM-A505F 4 GB handset (EUX, SWA/OPEN, bootloader revision 6) plus the supplied stock and SOVR 4.2 binary images. It does not verify 6 GB or other regional/model variants.

### Verified artifacts and boot-chain composition

- The supplied stock ZIP contains `boot.img`, `dt.img`, and `dtbo.img`; it does not contain a separate `dtb.img`. The stock base-DTB table is `dt.img`.
- The separately supplied live FDT is 219,477 bytes. The SOVR 4.2 `dtb.img` payload is 134,884 bytes; the stock `dt.img` FDT payload is 134,776 bytes. They are distinct trees.
- The SOVR 4.2 flash package writes its base `dtb.img` to the `dtb` partition and does not package or flash a DTBO. S-Boot applies the existing Samsung stock `dtbo` partition.
- The exact composition check used the SOVR 4.2 base payload plus each stock overlay entry via libfdt. Only stock overlay entry 5 (hardware revision range 0x6..0xFF) leaves the five S-Boot-added nodes, one S-Boot-deleted node, and four S-Boot-modified properties needed to match the live FDT. This is a verified binary comparison, not a DTS recompile.
- The live tree matches the SOVR `oneui14` flavor. Its EROFS fstab and EMS nodes originate in the SOVR base tree, not in S-Boot.
- Stock boot image is Android boot header v1 with no appended DTB, empty command lines, and no ramdisk. S-Boot supplies the effective live bootargs and applies the stock DTBO.

### Correct interpretation of RAM

The static stock and SOVR base DTBs both declare three 2-GiB banks at 0x80000000, 0x880000000 and 0x900000000. On the tested 4 GB handset, S-Boot rewrites this before Linux receives the live FDT:

- It shrinks `memory@80000000` to 0x3AB00000 bytes.
- It adds `memory@C0000000` (0x20000000 bytes) and `memory@E1900000` (0x1E700000 bytes).
- It leaves `memory@880000000` unchanged at 2 GiB.
- It deletes `memory@900000000`.
- The resulting declared RAM total is 0xF9200000 bytes (3,986 MiB), with two holes in the low address window: 85 MiB at 0xBAB00000..0xC0000000 and 25 MiB at 0xE0000000..0xE1900000.

Therefore neither prior blanket statement is correct on its own: the static three-bank declaration is present in the supplied working SOVR/stock base DTBs, but it is not the final Linux memory map on the tested 4 GB device. The live post-S-Boot FDT is the memory truth for that boot. Preserve the known base declaration unless a controlled boot-chain test proves it should change; do not copy the 4 GB live fragmented map into the shared SoC DTS and do not infer a 6 GB map from the static three-bank total.

### Samsung stock DTBO selection contract

The stock DTBO has six entries. All use table `id=0`, `rev=0`; selection is by the inclusive hardware-revision range mirrored between table `custom0/custom1` and overlay-root `dtbo-hw_rev/dtbo-hw_rev_end`:

| Entry | Hardware revision range |
|---|---|
| 0 | 0x0..0x0 |
| 1 | 0x1..0x1 |
| 2 | 0x2..0x2 |
| 3 | 0x3..0x3 |
| 4 | 0x4..0x5 |
| 5 | 0x6..0xFF |

The tested handset reports revision 6 and DTBO index 5. These entries are SWA OPEN board overlays and contain no F/G/FN/GN/N or RAM-size selector. The repository's generic `id=/:board_id rev=/:board_rev` DTBO config is not equivalent to Samsung's scheme.

**Design decision:** do not ship a replacement DTBO as part of this migration milestone. Keep the Samsung stock DTBO partition in place and retain a single base DTB table entry with `custom0=0`, `custom1=0xFF`, matching the existing SOVR 4.2 base-table convention. If source overlays are later needed for development, encode the Samsung hardware-revision properties/ranges exactly; do not substitute generic board_id/board_rev matching.

### S-Boot reserved-memory and bootargs contract

On the tested live FDT, S-Boot adds these reserved-memory nodes:

- `el2_code`: 0x87000000, size 0x200000.
- `el2_earlymem`: 0x8FE600000, size 0x1A00000.
- `kaslr`: 0x80001000, size 0x1000.

It also supplies bootargs-only carveouts/regions including `sec_avc_log=0x40000@0x91202000`, `sec_tsp_log=0x40000@0x91244000`, `sec_disp_log=0x100000@0x91286000`, `sec_debug_next=0x800000@0x91388000`, `ess_setup=0xf9000000`, `s3cfb.bootloaderfb=0xca000000`, plus `reserve-fimc` and `bcm_setup` values. The live bootargs also identify 4G DRAM and the selected hardware revision/DTBO index; device identifiers are deliberately excluded from this repository plan.

The Linux 5.1 port must explicitly audit and reserve every applicable firmware-owned range before enabling affected allocators/drivers. Do not assume legacy vendor `sec_debug` early-parameter reservation code exists in upstream v5.1. Validate all ranges against the final live FDT, memblock output and `/proc/iomem`; do not duplicate reservations already made by firmware or another kernel subsystem. Keep raw live DTBs and identifying bootargs out of Git.

### Verified versus open scope

Verified from supplied blobs for one SM-A505F 4 GB handset: base/overlay composition, selected stock DTBO entry, post-S-Boot memory edits, the three added reserved-memory nodes, and the live SOVR One UI 14 tree identity. No Linux 5.1 kernel/DTB build or hardware boot is implied by these findings.

Still open: actual 6 GB live memory map; stock/live evidence for SM-A505FN/G/GN/N and other regions; S-Boot behaviour when the static memory node layout is changed; and Linux 5.1 runtime reservation/boot behaviour. Keep all-family and 6 GB support as release goals, not verified claims.

### DTS and clock integration follow-up

The current Linux 5.1 branch already contains the SOVR-derived Exynos9610 SoC DTS, the imported binding header, and an A50 overlay compile/apply CI path. Its SoC DTS retains the three static memory banks and empty chosen bootargs/initrd placeholders; do not transplant live bootargs, live memory fragmentation, or S-Boot-added reserved-memory nodes into the common SoC DTS as if they were static source properties.

The SoC DTS currently references `samsung,exynos9610-clock`, but the v5.1 clock provider implementation is not yet integrated. The reference Linux 5.15 clock driver depends on Samsung CAL interfaces and generated Exynos9610 CMUCAL VCLK/node/QCH and clockout headers, plus ACPM-mediated clock operations. It is not a self-contained file and must not be enabled by adding only one Makefile line. Next work must map and port the smallest CAL/CMUCAL API/data dependency closure to v5.1, then compile the clock provider behind a dedicated disabled-by-default Kconfig symbol. ACPM/firmware IPC must remain gated until its shared-memory ABI, error paths and initialization ordering are ported and reviewed.

The live FDT timer clock-frequency value recorded in the earlier audit is 0x018CBA80, which is 26,000,000 Hz (26.0 MHz, not 25.6 MHz). The current SOVR DTS timer property is <26000000>, so the numeric values agree. Preserve the value pending confirmation of the property’s consumer/semantics; do not change it based on the earlier arithmetic typo.

**No bootability is claimed.** The next implementation gate is a clean v5.1 DTB build with warning classification, followed by separately compiled CAL/CMUCAL and clock-provider units. Never flash the generic upstream baseline or the current DTS-only artifacts to the handset.


## Phase 16 — Linux 5.1 pinctrl runtime gap and current build state (2026-11-19)

The DTB smoke build is not sufficient to establish pinctrl functionality. Direct target/reference source comparison found:

- The Linux 5.1 target's `drivers/pinctrl/samsung/pinctrl-exynos-arm64.c` has Exynos5433/Exynos7 data only; no Exynos9610 bank tables or `exynos9610_of_data`.
- The target's `pinctrl-samsung.c` OF match table has no `samsung,exynos9610-pinctrl` match. The six Exynos9610 controller nodes in the imported DTS therefore have no matching SoC-specific pinctrl data in the current target kernel.
- Vothcito's Linux 5.15 reference adds six Exynos9610 controller datasets (ALIVE, CMGP, DISPAUD, FSYS, TOP, SHUB), an OF match entry, new `EXYNOS9_PIN_BANK_*` macros, and `fltcon_offset` support in the pin-bank structures.
- The v5.1 structures do not contain `fltcon_offset`; copying the 5.15 bank tables verbatim is both a compile failure and a potential EINT filter-register correctness issue.

Next pinctrl implementation gate: audit and adapt the v5.1 bank initialization, EINT filter, wake IRQ, suspend/resume and resource-index semantics first. Then port the minimum data-model/macro changes and Exynos9610 bank tables, add the OF match, and compile with `CONFIG_PINCTRL_EXYNOS_ARM64=y`. Verify all six controller resources and bank names before marking pinctrl operational. The current DTB compile does not test this runtime binding.

The full handoff's stock boot/DTB/DTBO contract is recorded in Phase 15: stock `boot.img` is header v1 with no ramdisk or appended DTB; stock base table is `dt.img`; SOVR 4.2 writes only its base `dtb.img` to the dtb partition and leaves the Samsung stock `dtbo` partition untouched. The stock overlay selection is by the six inclusive hardware-revision ranges mirrored in table `custom0/custom1` and overlay root `dtbo-hw_rev/dtbo-hw_rev_end`, not generic `board_id/board_rev`. The live evidence remains limited to one SM-A505F 4 GB EUX/SWA OPEN revision-6 handset.

Latest run `44459925266` at commit `12bee58939e07e0bf5736f55af7147c95ce41d5c` was still in progress at last inspection: checkout, dependency install and ARM64 defconfig passed; the upstream Image/DTB step was running; DTBO diagnostic compile, source inventory, readiness audit and artifact upload were pending. No artifact was available at that inspection. This is not a completed build result.
