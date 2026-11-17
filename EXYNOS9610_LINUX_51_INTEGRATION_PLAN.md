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
