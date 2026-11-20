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


## Historical safety correction — superseded by Phase 15

The following earlier conclusion was based on comparing the live FDT directly with the SOVR base DTB before the selected stock overlay and S-Boot transformations were reconstructed. It is retained as audit history only and is **superseded by the verified binary composition in Phase 15**. Do not use its recommendation to discard the static three-bank base declaration or to seek a non-existent SOVR DTBO.

The verified result is: stock and SOVR 4.2 static base DTBs both declare three 2-GiB banks; stock Samsung DTBO entry 5 is applied on the tested revision-6 SM-A505F; S-Boot then edits the memory nodes before Linux receives the live FDT. The live post-S-Boot FDT, not the static base table, is the memory map Linux must validate at runtime. Phase 15 is authoritative for this one-device evidence and its limitations.

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

The stale run-status snapshot above is superseded by Phase 17: run 44460482796 completed successfully for commit d85c6a71b401e8a32d177acf6edb45e5ebc357e5, including ARM64 Image/DTB build, diagnostic overlay compile/apply, reference source inventory, readiness audit and artifact publication. Its artifact is a smoke-build bundle, not a bootable A50 kernel.


## Phase 17 — uploaded handoff reconciliation and latest CI result (2026-11-19)

The user supplied a verified handoff containing the stock boot.img, dt.img, dtbo.img, separately supplied A50_live.dtb, and SOVR 4.2 dtb.img provenance. This phase records the conclusions that supersede earlier ambiguous notes.

### Authoritative handoff corrections

1. The stock ZIP contains boot.img, dt.img, and dtbo.img; the stock base DTB table is dt.img, not a separate stock dtb.img.
2. The stock boot image is Android boot header v1, has no ramdisk, no appended DTB and empty command lines. S-Boot supplies the effective live bootargs and applies the stock DTBO.
3. SOVR 4.2 packages one base dtb.img and its AnyKernel installer writes that image to the dtb partition. It does not package or flash a DTBO. The existing Samsung stock dtbo partition remains in use.
4. The SOVR 4.2 base FDT and stock dt.img FDT are different payloads (134,884 B versus 134,776 B). The live tree matches the SOVR oneui14 flavor.
5. The stock DTBO selection is by inclusive hardware-revision ranges, mirrored in table custom0/custom1 and overlay root dtbo-hw_rev/dtbo-hw_rev_end, with id=0, rev=0: entry 0 [0,0], 1 [1,1], 2 [2,2], 3 [3,3], 4 [4,5], 5 [6,0xFF]. The tested revision-6 handset selects entry 5. There is no variant/RAM selector in the supplied SWA OPEN overlays.
6. Exact libfdt overlay composition proves SOVR 4.2 base + stock overlay entry 5 leaves only S-Boot's edits when compared with the supplied live FDT. This is verified from blobs for one SM-A505F 4 GB EUX/SWA OPEN revision-6 device only.
7. Both static base DTBs declare three 2-GiB banks at 0x80000000, 0x880000000, and 0x900000000. On the tested 4 GB device S-Boot shrinks the first bank to 0x3AB00000, adds 0xC0000000 size 0x20000000 and 0xE1900000 size 0x1E700000, retains the 0x880000000 bank, and deletes 0x900000000. Do not replace the shared static declaration with the live fragmented map. Do not infer 6 GB support from the static sum.
8. S-Boot adds reserved-memory nodes el2_code, el2_earlymem, and kaslr, and supplies bootargs-only secure/debug/framebuffer carveout arguments. The Linux 5.1 port must audit ownership and reserve applicable firmware ranges exactly once before enabling affected allocators/drivers; do not blindly duplicate firmware or kernel reservations.
9. The repository's generic board_id/board_rev DTBO scheme is not Samsung's stock hardware-revision scheme. Do not ship a replacement DTBO in this migration milestone. Preserve the one-entry base DTB table convention custom0=0, custom1=0xFF, and leave the stock DTBO partition untouched.
10. The handoff's §8 correction is applied here: earlier contradictory three-bank statements are reconciled by the static-base/S-Boot-final distinction; the request for a matching SOVR 4.2 DTBO is removed because none is shipped; Samsung's revision ranges are recorded; stock and SOVR base payloads are distinguished; S-Boot memory/reservation behaviour is an explicit Linux 5.1 contract. The 6 GB and non-F model/region claims remain unverified.

### Current target-tree state

- Branch: linux-5.1-exynos9610-integration.
- Current tip at this update: d85c6a71b401e8a32d177acf6edb45e5ebc357e5.
- The SOVR-derived Exynos9610 SoC DTS, supporting .dtsi files and binding headers are present; the SoC DTS retains the three static memory banks and empty chosen bootargs/initrd placeholders.
- The Exynos9610 DTB is included in the upstream v5.1 dtbs build via arch/arm64/boot/dts/exynos/Makefile.
- The CI diagnostic exynos9610-universal9610.dts overlay uses a generic board-id/revision scheme. It is not Samsung's stock DTBO table and is not part of the SOVR flash package. Treat it strictly as a syntax/link smoke test.
- The Linux 5.1 clock provider implementation and its CAL/CMUCAL/ACPM dependencies remain unported. Pinctrl runtime data also remains incomplete as documented in Phase 16. A successful DTB compile does not prove these devices bind or operate.

### Latest CI result

- Run: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50/actions/runs/44460482796
- Commit: d85c6a71b401e8a32d177acf6edb45e5ebc357e5.
- Conclusion: success; all job steps completed.
- Artifact: linux-v5.1-exynos9610-kconfig-smoke, artifact ID 14500356553, size 10,391,298 bytes.
- The run compiled upstream ARM64 Image and DTBs, compiled/applied the diagnostic UNIVERSAL9610 overlay, inventoried Vothcito Linux 5.15 reference files, ran the vendor readiness audit and published artifacts.
- It did not compile the vendor CAL/CMUCAL/ACPM or clock provider, did not build a Samsung stock-compatible DTBO, and did not produce a bootable A50 package. No hardware boot is claimed.

### Next safe implementation order

1. Keep the stock/SOVR static memory declaration and stock DTBO contract unchanged. Do not copy the live FDT's S-Boot modifications into the common DTS.
2. Classify the existing 71 overlay compiler warnings and 273 merged-DTB decompile warnings by node/property; only fix evidence-supported issues.
3. Finish the Linux 5.1 pinctrl API/data adaptation, including EINT filter offsets and wake/suspend paths, before enabling its six controller nodes.
4. Map the minimum CAL/CMUCAL dependency closure against the exact Vothcito reference commit and upstream v5.1 APIs; port isolated objects first.
5. Port the Exynos9610 clock provider behind a disabled-by-default Kconfig symbol only after its CAL/CMUCAL dependencies compile. Keep ACPM/firmware IPC disabled until ABI and initialization ordering are verified.
6. Audit S-Boot secure/debug/framebuffer reservations against v5.1 memblock and existing reserved-memory handling; reserve each range once.
7. Only then expand to SysMMU, UFS and remaining board peripherals. The 6 GB and non-F variant support remains a release target, not a verified result.



## Phase 18 — clock-provider API/dependency audit against Linux 5.1 (2026-11-19)

Compared the exact Vothcito reference branch source with the target Linux 5.1 Samsung clock Kconfig/Makefile. This is a source-level audit; no vendor clock code has been copied or enabled in this phase.

### Reference driver facts

Reference: Vothcito/android_kernel_samsung_exynos9610_a50, branch exynos9610-port, file drivers/clk/samsung/clk-exynos9610.c, blob dcd2d2f8c85fa1f741db0beb5d70b7dc21138579 (389 lines).

The driver includes:
- Linux Common Clock Framework interfaces (clk, clkdev, clk-provider, OF and OF address mapping).
- soc/samsung/cal-if.h.
- Exynos9610 CMUCAL VCLK, node and QCH generated headers.
- Exynos9610 clockout header.
- Samsung composite clock-provider extension header.

Its initialization path maps the controller registers, calls cal_if_init(np), creates a Samsung clock provider, registers fixed external oscillator and extensive HWACG/special VCLK tables, adds the OF clock provider, and schedules late VCLK rate programming. The late routine calls cal_clk_setrate() for the audio FM divider and CMGP I2C/USI muxes.

**Critical failure behaviour:** the reference clock init panics if register mapping, CAL initialization or provider allocation fails. Do not carry this panic-on-failure behaviour into an experimental v5.1 integration without proving the firmware/clock initialization contract and safe failure policy. A missing CAL provider must not be papered over with successful no-op clock operations.

### Kconfig/Kbuild mismatch

- The reference Makefile places clk-exynos9610.o and composite.o under the broad EXYNOS_ARM64_COMMON_CLK object selection.
- The target v5.1 Makefile currently places the Exynos5433/Exynos7 drivers under EXYNOS_ARM64_COMMON_CLK but does not contain the Exynos9610 driver or Samsung composite extension object.
- The target v5.1 Kconfig has COMMON_CLK_SAMSUNG selecting EXYNOS_ARM64_COMMON_CLK for ARM64 + ARCH_EXYNOS. Reusing that broad symbol would build the new Exynos9610 object on unrelated Exynos ARM64 configurations and is not an acceptable isolated integration gate.
- Add a dedicated SOC_EXYNOS9610 clock-provider symbol only after its dependencies are ready; it must depend on the Exynos9610 SoC selector, COMMON_CLK_SAMSUNG and the exact CAL/CMUCAL configuration. Do not enable it by default in the generic smoke config.

### Dependency closure to resolve before code import

1. Samsung clock provider framework extensions: samsung_clk_provider, samsung_register_vclk, samsung_register_of_fixed_ext, samsung_clk_of_add_provider, Samsung fixed-rate helpers and the composite clock implementation. Compare every helper/type with the target v5.1 clk.h / clk-provider.h and existing Samsung provider implementation.
2. CAL public interface: cal_if_init, cal_clk_setrate and all structures/macros exposed by soc/samsung/cal-if.h. Audit register mapping, error propagation, locking, and whether any calls require ACPM IPC.
3. CMUCAL shared core: CMUCAL IDs/types, VCLK descriptors, VCLK registration, node/QCH lookup, SFR access, LUT and PLL metadata. Determine exact source/object dependencies from symbol references rather than importing the full reference directory.
4. Exynos9610 generated data: cmucal-vclk.h, cmucal-node.h, cmucal-qch.h, clkout_exynos9610.h and the corresponding C tables (node, QCH, SFR, VCLK, VCLK LUT and CAL data). Keep generated IDs and tables from one matching reference revision.
5. External oscillator and clockout support: validate the 26-MHz oscillator input and clockout muxes against A50 hardware/DTS; do not assume optional clockout outputs are needed for basic boot.
6. ACPM: keep ACPM DVFS and firmware IPC out of the first clock compile unless a referenced symbol is proven to require them. If needed, port the transport ABI, shared-memory layout, timeouts and error paths as a separate prerequisite.
7. Suspend/resume and runtime ordering: audit clock register save/restore, provider initialization order, parent clocks, early console clock dependencies and late VCLK programming. A compile-only provider is not runtime-safe by itself.

### DTS consequence

The existing SoC DTS contains a node compatible with samsung,exynos9610-clock and a broad set of consumer clock references. The DTB compiler accepts phandles and clock IDs because the binding header is present; it does not verify that Linux 5.1 has a matching provider. Until the provider and all referenced IDs are implemented, consumers must remain disabled or the port must be explicitly labelled DTB-only. Do not remove or renumber the SOVR binding IDs just to satisfy the generic upstream build.

### Next implementation gate

- Build a source/symbol manifest for the clock driver and Samsung composite helper against the exact pinned reference commit.
- Port the smallest compile-only Samsung clock-provider API layer into a private/dedicated symbol, with no provider registration in the generic ARM64 config.
- Port CAL interface and CMUCAL core/data in isolated object groups; run compile-only checks before linking the full clock driver.
- Only after the provider links, test DT clock ID coverage against every active A50 consumer and decide which devices can safely be enabled.
- Keep the SoC clock node from causing an unconditional panic if a dependency is unavailable; runtime init policy must be reviewed before enabling the provider.

No clock source was changed and no CAL/CMUCAL object build is claimed in this phase.


## Phase 19 — explicit Exynos9610 DTB build assertions in CI (2026-11-19)

The baseline workflow was strengthened so a green generic ARM64 build cannot silently pass without producing and checking the actual Exynos9610 SoC DTB.

After the existing Image + dtbs build, CI now:
- asserts the ARM64 Image exists;
- asserts arch/arm64/boot/dts/exynos/exynos9610.dtb exists and is non-empty;
- decompiles that exact DTB with the in-tree dtc;
- asserts the three static SOVR/stock base memory nodes are present: memory@80000000, memory@880000000 and memory@900000000;
- asserts the samsung,exynos9610-clock provider node compatible is present;
- publishes the decompiled DTB source and its DTC warning log with the smoke-build artifact.

This is a build-artifact integrity check only. It does not prove the clock provider exists in Linux 5.1, that pinctrl/clock consumers bind, that S-Boot produces the expected final FDT on another SKU, or that the kernel boots.

Workflow commits:
- f244e9ea2c052fe0e88ca46acda1b5248e6ada66 — add explicit Exynos9610 DTB and boot-contract assertions.
- 01b549f4a51e8f03dc7c11725037c076259be429 — publish the decompiled DTB and warning log.

The validation run triggered for the updated workflow is pending at the time of this note. Check the branch's latest Actions run before reporting it as passed. No vendor clock source or runtime Kconfig enablement was added.


## Phase 20 — pinctrl reference re-audit: EINT filter offset inconsistency (2026-11-19)

A second, more targeted comparison was made after the prior Phase 16 summary. The exact Vothcito source blobs are:
- `pinctrl-exynos-arm64.c`: `7fb319df272fd9155d00f8854dc1bf736d271ae1` (677 lines).
- `pinctrl-exynos.h`: `c7c2d27415a2348f9c114c3e9894a0e2c0c83275` (229 lines).
- `pinctrl-samsung.h`: `6922f8a69c70590ebbd0bc41e89cb40f8ee1fa1a` is the samsung.c blob? Verify file-specific SHA before relying on it; the actual fetched header content has `fltcon_offset` at the pin-bank-data structure.

The Vothcito Exynos9610 tables use six controller groups and the EXYNOS9_PIN_BANK_EINTG/EINTW macros. Those macros populate both `eint_offset` and `fltcon_offset`. However, a search of the fetched reference `pinctrl-samsung.c` and `pinctrl-exynos.c` found no runtime read of `bank->fltcon_offset`; Exynos EINT filter save/restore still computes EFLTCON addresses using `2 * bank->eint_offset`. This is a source-level inconsistency that must be resolved against the actual Exynos9610 register map or a matching vendor implementation, not dismissed as a simple missing structure member.

The Linux 5.1 target lacks the Exynos9610 bank tables, match entry and `fltcon_offset` members. The correct port is therefore not a mechanical cherry-pick. Before code import:
1. Trace all EINT filter read/write paths and determine whether Exynos9610 filter offsets are linear in `eint_offset` or require the explicit table value.
2. Compare the ALIVE wakeup controller and GPIO EINT controller register layouts and suspend/resume restore paths.
3. Confirm resource indices for all six controller nodes against the DT reg/reg-names and the Samsung implementation.
4. Only then extend the runtime structures and adapt all readers/writers consistently; otherwise omit the unused field and use proven offset calculations.
5. Add compile-time and runtime-oriented tests that verify calculated register addresses for representative banks in each of ALIVE, CMGP, DISPAUD, FSYS, TOP and SHUB.

No pinctrl implementation was copied or enabled in this phase. This finding blocks claiming the Exynos9610 pinctrl port is ready; CI's current green status only validates the upstream Image/DTB and diagnostic overlay build.


## Phase 21 — original A50 handoff reconciled and active continuation (2026-11-20)

The complete user-supplied `A50_HANDOFF_FOR_CHATGPT.md` was reread. It is the authoritative evidence record for the A50 boot-chain and SOVR 4.2 DTB contract. This phase supersedes contradictory statements in earlier phases where noted; historical findings remain historical and must not be treated as current implementation instructions.

### Accepted DTB/S-Boot contract (verified from supplied blobs; SM-A505F 4 GB only)

- SOVR 4.2's base `dtb.img` is a one-entry Android DT table with `custom0=0`, `custom1=0xFF`; its FDT payload declares the three static 2-GiB banks at `memory@80000000`, `memory@880000000`, and `memory@900000000`.
- Keep this shared static three-bank placeholder. Do not create a 4-GB DTB, 6-GB DTB, per-RAM kernel fork, or hardcoded live memory map.
- The supplied live FDT is the post-S-Boot result on one SM-A505F 4-GB unit (revision 6, stock DTBO entry 5). Exact libfdt overlay-and-compare proves the live tree is SOVR 4.2 base payload + stock DTBO entry 5 + S-Boot edits.
- S-Boot trims/replaces memory nodes and generates bootargs. The live 4-GB layout is evidence for that one unit only; no 6-GB live dump is available. The 6-GB and other model/region claims remain target requirements, not verified claims.
- Keep the stock DTBO partition untouched. SOVR does not ship a matching DTBO image. Samsung selection is by hardware-revision ranges [0], [1], [2], [3], [4..5], [6..0xFF], mirrored in DT table custom fields; the repository's generic board_id/board_rev diagnostic overlay is not a production Samsung DTBO.
- Do not copy S-Boot's live /chosen bootargs/initrd or final memory edits into DTS. Preserve the S-Boot-added reserved-memory nodes (el2_code, el2_earlymem, kaslr) and bootargs-only carveout contract; Linux 5.1 must reserve each range exactly once through appropriate early/memblock handling after auditing existing reservations.
- Preserve the distinction between stock `dt.img` and SOVR 4.2 `dtb.img`; they are different payloads. The proven live tree corresponds to SOVR's One UI 14 DTS flavor.
- Do not commit raw `A50_live.dtb` or identifiers from live bootargs.

### Current Linux 5.1 tree facts rechecked

- The branch already contains `arch/arm64/boot/dts/exynos/exynos9610.dts`, seven local Exynos include files, an Exynos9610 DTB Makefile target, and a DTB smoke workflow. The previous DEV_STATE claim that the DTS/defconfig paths were simply absent was stale/inaccurate for the current tree; the exact A50-specific defconfig still needs a fresh path audit.
- The current SoC DTS contains the three static memory banks and empty chosen bootargs/initrd placeholders, consistent with the shared SOVR static-base contract.
- The SoC DTS includes substantial vendor peripherals and reserved-memory content. A successful DTC build only validates syntax/linkage; it does not prove those drivers are implemented, safe to enable, or bootable.
- Linux 5.1 clock/CAL/CMUCAL/ACPM integration is not complete. Phase 18 remains the latest clock dependency audit; no clock provider runtime support is claimed.
- Phase 20's EINT filter offset inconsistency remains an unresolved pinctrl blocker. Do not mechanically import/enable the six pinctrl controller groups until the address calculation and suspend/wake paths are resolved.
- The target branch's generic UFS host and Samsung UFS PHY integration is still absent per the 2026-11-20 audit; donor Linux 5.15 source is reference-only until individually adapted to 5.1.

### Build/boot status boundary

- Generic upstream ARM64 Linux 5.1 baseline CI was previously green.
- Exynos9610 DTB smoke assertions and diagnostic overlay checks have been added in earlier phases; check the latest Actions run and artifacts before reporting their current status.
- No integrated Linux 5.1 A50 kernel, complete vendor driver set, flashable ZIP, or hardware boot has been proven by this handoff. Do not call the current result a bootable kernel.

### Next work (resume here; do not repeat completed audits)

1. Refresh current branch tip and latest Actions run; inspect exact logs/artifact and determine whether the explicit Exynos9610 DTB assertions pass.
2. Keep the shared three-bank SOVR base DTB and stock DTBO selection contract unchanged.
3. Continue the pinctrl EINT offset/register-map investigation, then adapt the Linux 5.1 runtime structures and save/restore paths only when evidence resolves it.
4. In parallel, produce a symbol/object dependency manifest for the exact Exynos9610 CAL/CMUCAL clock provider donor revision; port the minimal compile-only dependency closure behind dedicated disabled-by-default Kconfig symbols.
5. Keep ACPM/firmware IPC disabled until its ABI, shared-memory layout, timeout and error-unwind paths are verified.
6. Then port UFS host + Samsung UFS PHY coherently, followed by SysMMU and essential board peripherals.
7. Compile after each isolated source group; do not package or flash until a complete A50 defconfig build and artifact/boot-chain checks pass.



## Phase 22 — pinctrl EINT filter-offset audit deepened (2026-11-20)

The exact donor implementation was traced through the full data-to-runtime path. This resolves one ambiguity from Phase 20: the donor defines per-bank filter offsets in init data but fails to transfer them into runtime bank state, while suspend/resume continues to calculate filter registers from `2 * eint_offset`.

### Exact source evidence

Donor: `Vothcito/android_kernel_samsung_exynos9610_a50`, branch `exynos9610-port`.
- `drivers/pinctrl/samsung/pinctrl-exynos-arm64.c`, blob `7fb319df272fd9155d00f8854dc1bf736d271ae1`: Exynos9610 GPIO bank macros supply both `eint_offset` and a distinct `fltcon_offset` for EINTG banks. Examples include DISPAUD gpb1 (0x04 vs 0x08), FSYS gpf2 (0x08 vs 0x0C), and TOP banks with progressively non-linear filter offsets.
- `drivers/pinctrl/samsung/pinctrl-exynos.h`, blob `c7c2d27415a2348f9c114c3e9894a0e2c0c83275`: `EXYNOS9_PIN_BANK_EINTG/W` macros populate `fltcon_offset` in `samsung_pin_bank_data`.
- `drivers/pinctrl/samsung/pinctrl-samsung.h`, blob `41981b11b0a2c5a1e0378e8ff41e71b6cfbaf388`: init-data struct has `fltcon_offset`, but runtime `struct samsung_pin_bank` has no corresponding member.
- `drivers/pinctrl/samsung/pinctrl-samsung.c`, blob `6922f8a69c70590ebbd0bc41e89cb40f8ee1fa1a`: the init loop copies `eint_offset` to runtime bank but does not copy `fltcon_offset`.
- `drivers/pinctrl/samsung/pinctrl-exynos.c`, blob `0489c899b401cf0b8ecd2b8023692d42142565df`: GPIO EINT suspend/resume reads and writes EFLTCON using `EXYNOS_GPIO_EFLTCON_OFFSET + 2 * bank->eint_offset` and the second register at +4; it never consumes the init-data `fltcon_offset`.

### Consequence

The donor's explicit per-bank filter offsets are currently dead init data. They do not establish the correct Exynos9610 register mapping, and the donor suspend/resume path appears internally inconsistent with its own table for banks where `fltcon_offset != 2 * eint_offset`. Do not copy these tables and assume filter support is correct. The Linux 5.1 port must not introduce a partially used field or silently choose either formula.

### Required resolution before implementation

1. Obtain a matching Exynos9610 register map or Samsung implementation with actual EFLTCON register addresses for ALIVE, DISPAUD, FSYS, TOP and other GPIO controllers.
2. For every EINTG bank, independently verify CON, FLTCON0, FLTCON1, MASK and PEND addresses; verify EINTW/wakeup registers separately.
3. Decide whether runtime state needs a distinct `fltcon_offset` and update both data-to-runtime copy and every save/restore/read/write callsite consistently if proven.
4. Add a table-driven address test for all six controller groups and reject duplicate/out-of-range register windows.
5. Verify suspend/resume and wake configuration paths before enabling the controller nodes.

### Result

This is a stronger source-level blocker, not a resolved implementation. No pinctrl code was changed or enabled. No compile or hardware test is claimed. Continue with the Exynos9610 clock/CAL dependency manifest in parallel rather than guessing the filter register map.


## Phase 23 — CAL/CMUCAL clock dependency manifest: first API blockers (2026-11-20)

Started the exact-revision dependency manifest for donor branch `Vothcito/android_kernel_samsung_exynos9610_a50:exynos9610-port`. This is a source audit only; no donor code was copied.

### Clock-provider entry point

- `drivers/clk/samsung/clk-exynos9610.c`, blob `dcd2d2f8c85fa1f741db0beb5d70b7dc21138579`, includes the Linux Common Clock Framework, `<soc/samsung/cal-if.h>`, Exynos9610 `cmucal-vclk.h`, `cmucal-node.h`, `cmucal-qch.h`, `clkout_exynos9610.h`, and Samsung `composite.h`.
- Direct CAL calls found in the driver include `cal_if_init(np)` and `cal_clk_setrate(...)`; provider registration uses Samsung-specific helpers including `samsung_register_of_fixed_ext`, `samsung_register_vclk`, and `samsung_clk_of_add_provider`.
- `drivers/clk/samsung/composite.c` is a substantial Samsung extension and includes `<soc/samsung/cal-if.h>`; it is not equivalent to the upstream v5.1 generic Samsung clock helpers.

### Concrete API/configuration inconsistency in donor revision

- `include/soc/samsung/cal-if.h`, blob `65fe05a30e4251b0ca9d735ddbb29d7713374ac5`, declares `cal_if_init(void *)` in the normal CAL path, but the `CONFIG_PWRCAL` inline stub declares `cal_if_init(void)` and returns success without doing initialization.
- The Exynos9610 clock driver calls `cal_if_init(np)`. Therefore a build selecting `CONFIG_PWRCAL` against this exact header has a prototype mismatch; the no-op stub must not be mistaken for a valid initialized CAL provider. Configuration selection and the intended CAL implementation must be resolved before compiling/enabling the provider.
- The same header's non-PWRCAL path includes the large `pmucal_system.h` interface and exposes broad CAL/PMUCAL APIs. The donor `cal-if/cal-if.c` includes CMUCAL, PMUCAL, ACPM DVFS, FVMAP, ASV and ECT parser interfaces. The object closure is substantially larger than a single clock driver.
- Donor `drivers/soc/samsung/cal-if/Makefile` selects `cal-if.o` unconditionally under CAL_IF, and gates CMUCAL, PMUCAL, ACPM_DVFS and Exynos9610 `cal_data.o` separately. This is a dependency map only; it is not a Linux 5.1-ready Kconfig design.

### Porting gate

1. Resolve the `CONFIG_PWRCAL` vs normal CAL interface contract and eliminate any success-returning no-op path for required clock initialization.
2. Map every required CAL/CMUCAL symbol to its defining object and all transitive headers/data from this exact donor revision.
3. Compare all Samsung composite helper types/functions with upstream Linux 5.1 APIs; keep the new provider behind dedicated disabled-by-default symbols.
4. Keep ACPM DVFS and firmware IPC out of the first compile closure unless a referenced symbol demonstrably requires it.
5. Compile the smallest isolated object set against Linux 5.1 before linking/registering the Exynos9610 provider. Do not carry panic-on-failure init behaviour into the experimental port.

No CAL/CMUCAL/clock source was changed, no compile was run, and no provider runtime or boot success is claimed.


## Phase 24 — donor clock object closure and safe Kconfig boundary (2026-11-20)

Continued the exact donor audit. No kernel source has been copied yet.

### Target Linux 5.1 integration points

- Target `drivers/clk/samsung/Kconfig` only has the generic `EXYNOS_ARM64_COMMON_CLK` symbol for Exynos ARM64 clock support. It selects the broad ARM64 provider group and is not a safe way to add an unported Exynos9610 Samsung CAL provider.
- Target `drivers/clk/samsung/Makefile` currently builds the upstream ARM64 clock drivers and has no dedicated Exynos9610 object or dedicated CAL extension symbol.
- Target `drivers/soc/samsung/Kconfig` and Makefile contain only upstream PMU/PM-domain drivers; there is no Samsung CAL_IF / CMUCAL integration.
- Therefore the donor's use of `CONFIG_EXYNOS_ARM64_COMMON_CLK` to compile `composite.o` and `clk-exynos9610.o` is too broad for this Linux 5.1 branch and must not be copied as-is.

### Donor object closure is larger than first estimated

- Donor `drivers/clk/samsung/composite.c` (blob `3cf4a6dd71fdb4c098db392869022bdd7593c633`) implements VCLK operations whose callbacks call CAL/VCLK APIs at runtime: enable/disable, is_enabled, recalc_rate, round_rate, set_rate, DFS rate changes, and QCH initialization. A clock-provider compile cannot be considered harmless just because the provider itself is not selected by the board DT.
- Donor `drivers/soc/samsung/cal-if/Makefile` (blob `00944ace1b772acd0193edf80792dd7b884e4c0a`) unconditionally includes `cal-if.o` in that directory; CMUCAL selects `cmucal.o ra.o vclk.o pll_spec.o`; PMUCAL selects system/local/CPU/RAE; ACPM_DVFS selects `acpm_dvfs.o fvmap.o`; Exynos9610 selects `exynos9610/cal_data.o`.
- Donor `exynos9610/cal_data.c` (blob `fb578d3120abe11723345ad2162b9056cde18e99`) textually includes `cmucal-node.c`, `cmucal-qch.c`, `cmucal-sfr.c`, `cmucal-vclk.c`, `cmucal-vclklut.c`, and `clkout_exynos9610.c`, as well as broad PMUCAL and ACPM/ASV headers. It is a monolithic data/implementation compilation unit with additional PMUCAL references, not merely static clock-ID tables.
- Donor `cmucal-vclk.h`, `cmucal-node.h`, and `cmucal-qch.h` all include the shared `../cmucal.h` and expose a large Exynos9610-specific ID namespace. The header `vclk.h` returns success from many CONFIG_CMUCAL-disabled inline stubs, which could mask a missing clock backend if selected accidentally.
- The donor `cal-if.c` initialization path calls ECT parsing, VCLK initialization, PMUCAL RAE/system/local/CPU initialization and then ACPM device setup. It is not a minimal CAL shim and cannot be enabled until every dependency and side effect is understood.

### Safe architecture for the first Linux 5.1 port

1. Add a dedicated `CONFIG_EXYNOS9610_SAMSUNG_CLK` (or similarly scoped) option, depending on `ARCH_EXYNOS && ARM64 && COMMON_CLK`, default off. Do not select it from the generic ARM64 clock symbol.
2. Keep the experimental provider object and Samsung composite extension behind that dedicated option; keep the board DTS clock consumers disabled until providers are complete.
3. Split the CAL core, CMUCAL ID/data, PMUCAL, ACPM and ASV dependencies only after symbol/object analysis; do not pull the entire donor `cal_data.c` into a first compile-only test without verifying its transitive PMUCAL/ACPM symbols and data tables.
4. Replace success-returning disabled stubs for mandatory clock operations with explicit build-time dependency or `-ENODEV`/error propagation. Never let a provider register when its CAL backend is absent.
5. Resolve `cal_if_init(void *)` signature consistently across real implementation and disabled stubs; propagate initialization failure rather than continuing with a partially initialized clock tree.
6. Compare Samsung `composite.c` API and data structures against Linux 5.1 CCF APIs before attempting compilation. The file is 46,911 bytes and is not a small header-only compatibility addition.
7. Keep ACPM/DVFS and PMUCAL power sequencing disabled in the first isolated compile unless the selected VCLK operations require them; if required, port the full dependency closure rather than stubbing them.

### Result

The target branch has no existing Samsung CAL framework. The donor clock provider is deeply coupled to CAL/CMUCAL/VCLK and PMUCAL initialization, so the safe next action is a separately gated subsystem port with a complete object closure. No Kconfig/Makefile/source edits or compilation were performed in this phase; the dependency architecture is now recorded before code changes.


## Phase 25 — CMUCAL/VCLK transitive runtime dependency audit (2026-11-20)

Continued the exact donor source trace to determine whether a small clock-only compile closure exists. Result: the donor CAL/VCLK implementation is tightly coupled to ECT, ASV, ACPM and PMU/RAE paths; these are not independent compile-only data tables.

### Exact donor files and findings

- `drivers/soc/samsung/cal-if/cmucal.c`, blob `96913db0da1310325419d174cca210c7e0d5ad7e`: CMUCAL lookup implementation depends on the shared CMUCAL node/list structures; this file alone is comparatively narrow.
- `drivers/soc/samsung/cal-if/vclk.c`, blob `5199f12efd2ab3f56d38188cd224d547f8fb4c56`: includes ECT parser, CMUCAL, RA, ACPM DVFS and ASV headers. It calls ECT block/DVFS/ASV lookups, CMUCAL address/node lookup, VCLK table/rate helpers and ASV initialization. Therefore the active VCLK engine cannot be built as a self-contained clock shim without resolving those interfaces.
- `drivers/soc/samsung/cal-if/ra.c`, blob `bd9c3ea6914aad23b5db74677f12d8f9091dd5d2`: depends on ECT PLL data, Exynos PMU APIs, CMUCAL SFR mappings and low-level register-access helpers.
- `drivers/soc/samsung/cal-if/pmucal_rae.c`, blob `0ecbd7734d55d819ac64a9c65db74261987c05ae`: PMUCAL RAE layer uses SoC-specific physical-to-virtual mapping, wait/condition/read/write sequences and SMC interfaces. This is power/firmware-sensitive and must not be stubbed as success.
- `drivers/soc/samsung/cal-if/acpm_dvfs.h`, blob `6e4fa6dd747ad8f066ee2900a57f4db5af595550`: exposes ACPM rate/init/get/device/voltage-margin/temperature operations.
- `drivers/soc/samsung/cal-if/asv.h`, blob `50a114069e8834c511d56d90fc49cd7e519f1af8`: ASV table initialization and group/table-version/ID queries are directly consumed by VCLK/clock policy.

### Porting decision

- A compile-only CMUCAL lookup object may be separable for static ID/name/address lookup, but it does not provide functional clock rate/gate operations.
- Do not enable VCLK callbacks until ECT binary format/data, ASV tables, RA register mapping, PMUCAL/SMC behavior and ACPM firmware ABI are individually ported and tested.
- A safe first stage should compile the provider's static clock-ID declarations and CCF registration scaffolding with all hardware-changing ops absent/disabled; it must not register fake clocks or return success for unsupported operations. Only after the full backend is ready should DT clock providers be activated.
- The donor's CAL init sequence cannot be transplanted as-is into Linux 5.1: it initializes PMUCAL and ACPM as part of clock bring-up. Separate initialization ordering and error unwinding are mandatory.

No source edits or compilation occurred. This phase narrows the safe implementation boundary; it does not claim working clocks.
