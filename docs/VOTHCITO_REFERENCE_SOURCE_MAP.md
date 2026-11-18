# Vothcito Exynos9610 A50 Reference Source Map

Reference (read-only): https://github.com/Vothcito/android_kernel_samsung_exynos9610_a50
Branch: exynos9610-port
Audited commit: ace96fa34c0d8303a23c5518aae751a91274552b
Kernel Makefile: Linux 5.15.211
Migration target: Linux 5.1

## Version caveat
The root Makefile identifies Linux 5.15.211. The file arch/arm64/configs/exynos9610-a50_core_defconfig has a generated header saying Linux/arm64 4.14.194. Treat that header as stale/copied metadata until regenerated and validated against this exact tree; do not infer the repository kernel version from it.

The recursive Git tree API response was truncated (75,300 entries returned). This is a verified source map, not an exhaustive enumeration of every path.

## High-value source paths

### Board and SoC device tree
- arch/arm64/boot/dts/exynos/exynos9610.dts
- arch/arm64/boot/dts/exynos/exynos9610-universal9610.dts
- arch/arm64/boot/dts/exynos/exynos9610-pinctrl.dtsi
- arch/arm64/boot/dts/exynos/exynos9610-pm-domains.dtsi
- arch/arm64/boot/dts/exynos/exynos9610-rmem.dtsi
- arch/arm64/boot/dts/exynos/exynos9610-sysmmu.dtsi
- arch/arm64/boot/dts/exynos/exynos9610-tmu-sensor-conf.dtsi
- arch/arm64/boot/dts/samsung/exynos9610-a50_common.dtsi
- arch/arm64/boot/dts/samsung/exynos9610-a50_camera.dtsi
- arch/arm64/boot/dts/samsung/exynos9610-a50_sound.dtsi
- arch/arm64/boot/dts/samsung/display-lcd_a50_common.dtsi
- Regional A50 board DTS files under arch/arm64/boot/dts/samsung/

### Clocks and power
- drivers/clk/samsung/clk-exynos9610.c
- include/dt-bindings/clock/exynos9610.h
- drivers/soc/samsung/cal-if/
- drivers/soc/samsung/cal-if/exynos9610/
- drivers/soc/samsung/exynos9610/
- include/soc/samsung/cal-if.h
- drivers/soc/samsung/exynos-pmu.c
- drivers/soc/samsung/pm_domains.c

### Other platform areas
- drivers/pinctrl/samsung/
- drivers/thermal/samsung/exynos_tmu.c
- drivers/phy/samsung/
- drivers/ufs/ (enumerate exact Exynos9610 dependencies before porting)
- drivers/iommu/ and Samsung SysMMU-related paths (enumerate exact dependencies)
- Samsung regulator, battery, USB, display, audio, camera and sensor-hub paths; select by A50 DTS compatible strings and Kconfig dependencies, not directory name alone.

### Build configuration
- arch/arm64/configs/exynos9610-a50_core_defconfig
- drivers/clk/samsung/Makefile
- drivers/soc/samsung/Makefile
- drivers/soc/samsung/cal-if/Makefile
- drivers/thermal/samsung/Makefile
- arch/arm64/boot/dts/Makefile

## Critical safety findings
1. The universal9610 board DTS uses plugin/overlay fragments; it is not automatically a directly bootable base DTB.
2. The universal9610/A50 DTS and A50 common DTS must be reconciled with the exact SM-A505F product/board revision and live DTB/DTBO chain.
3. exynos9610-rmem.dtsi declares fixed reserved-memory regions and secure multimedia heaps. Never copy addresses/sizes blindly. Reconstruct actual 4 GB RAM, bootloader reservations, secure carveouts and overlay modifications first.
4. Vendor-specific compatible strings and Samsung Android interfaces require matching drivers. DTS compilation alone does not prove a driver binds.
5. Linux 5.15.211 implementations are reference material, not drop-in Linux 5.1 code. Port dependencies and API changes individually, preserving authorship and license notices.
6. Do not copy the 5.15 defconfig wholesale into Linux 5.1. Generate a configuration from the 5.1 target tree and enable only validated symbols.

## Porting order
1. Establish exact A50 board variant, live DTB, DTBO index and effective overlay.
2. Reconstruct RAM, reserved-memory, CMA, secure and firmware regions.
3. Port minimum Exynos9610 clock controller, DT bindings and CAL/CMUCAL/PMUCAL dependency chain.
4. Port pinctrl, PM domains, regulators, thermal and SysMMU/IOMMU dependencies.
5. Port UFS/PHY, USB, display, audio, sensors and other peripherals in dependency order.
6. Build A50 DTS/DTBO and kernel in CI; inspect DTBs and run static checks.
7. Only attempt boot testing after image, ramdisk, DTB/DTBO and recovery path are verified.

## Repository policy
Vothcito/android_kernel_samsung_exynos9610_a50 is read-only. Do not push, create branches, issues or pull requests there. All migration changes belong in crypto143007-ship-it/SOVR-Kernel-A50 on linux-5.1-exynos9610-integration, never in the original SOVR-Technologies upstream.
