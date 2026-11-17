# Exynos9610 / Universal9610 A50 Device-Tree Binding Audit

**Audit date:** 2026-11-17  
**Source:** SOVR `main`  
**SoC DTS blob:** `88c6b7b54cf493b44de0812f54255a56562c59b4` (`arch/arm64/boot/dts/exynos/exynos9610.dts`)  
**Board DTS blob:** `eadc27822e505fc989274984097cbf4b7e32ffbd` (`arch/arm64/boot/dts/exynos/exynos9610-universal9610.dts`)  
**Target:** upstream Linux `v5.1`.

## Method and limits

Parsed the `compatible` properties from both full DTS files and deduplicated the strings. This is a DT contract inventory. It does **not** claim that every node is enabled in the final boot DT, that a matching driver is compiled, or that a driver successfully binds. Code search did not return reliable per-compatible `of_match_table` results, so unresolved driver paths are explicitly left as unresolved rather than guessed.

## High-priority vendor-specific compatible inventory

| Compatible | Hardware/function inferred from node name and DTS placement | Driver/binding status |
|---|---|---|
| `samsung,exynos9610-clock` | SoC clock controller | Vendor clock driver confirmed at `drivers/clk/samsung/clk-exynos9610.c`; exact match-table and v5.1 API diff pending |
| `samsung,exynos9610-pinctrl` | SoC pin controller | Vendor pinctrl data/driver needs exact match-table trace |
| `samsung,exynos7-wakeup-eint` | Wakeup external interrupts | Exact Exynos9610 EINT driver and wake retention trace pending |
| `samsung,exynos-acpm` | Samsung ACPM platform interface | Vendor ACPM subsystem present; exact platform-driver binding pending |
| `samsung,exynos-acpm-ipc` | ACPM IPC transport | Vendor IPC driver present; firmware ABI and probe dependencies pending |
| `samsung,exynos-acpm-dvfs` | ACPM DVFS control | Vendor DVFS client present; exact binding and OPP integration pending |
| `samsung,exynos9610-tmu` | Exynos9610 thermal sensor | Vendor Exynos TMU and ACPM plugin sources present; match-table/thermal-zone validation pending |
| `samsung,exynos-fmp` | Samsung inline storage crypto/FMP | Vendor FMP implementation and UFS integration require source trace |
| `samsung,exynos-ufs` | Exynos UFS host | Vendor `ufs-exynos.c` and `ufs-cal-9610.c` exist; v5.1 UFS API and PHY/power sequencing pending |
| `samsung,exynos9610-pmu` | Exynos9610 PMU/syscon | Exact PMU driver match and power-domain relationship pending |
| `samsung,exynos9-dpp` | Display post-processing | Vendor display driver subtree and match-table trace pending |
| `samsung,exynos9-disp_ss` | Display subsystem | Vendor display driver and component binding trace pending |
| `samsung,exynos9-dsim` | MIPI DSI host | Vendor DSIM driver and panel chain pending |
| `samsung,exynos9-decon` | Display controller | Vendor DECON driver and DRM/framebuffer integration pending |
| `samsung,exynos-dwusb` | Exynos USB DRD glue | Exact glue/PHY driver and v5.1 DWC3 API delta pending |
| `samsung,exynos-usbdrd-phy` | USB DRD PHY | Vendor PHY driver and calibration/power sequencing pending |
| `samsung,exynos-iommu-bus` | Exynos IOMMU bus topology | Vendor SysMMU driver and IOMMU API delta pending |
| `samsung,exynos9610-g2d` | Exynos G2D engine | Vendor multimedia driver trace pending |
| `samsung,exynos5-scaler` | Exynos scaler | Vendor multimedia driver trace pending |
| `samsung,exynos8890-jpeg` | JPEG accelerator | Legacy compatible reuse must be checked against actual register/driver data |
| `samsung,teegris` / `samsung,exynos-tee` | Samsung secure-world / TEE | TZDEV/TEEGris and TZAR contract is P0; do not replace with stub |
| `samsung,scsc_wifibt` | Samsung SCSC Wi-Fi/Bluetooth | Vendor SCSC driver/firmware integration P0 for daily-driver acceptance |
| `samsung,exynos9610-fm` | FM subsystem | Vendor FM driver mapping pending |
| `samsung,exynos-vipx` / `samsung,exynos-vipx-vertex` | Vision accelerator | Vendor VIPX driver and memory/IOMMU contracts pending |
| `samsung,exynos-nanohub` | Sensor hub | Vendor firmware transport and sensor driver mapping pending |
| `samsung,exynos-seclog` | Secure log interface | Vendor secure-log driver/TEE dependency pending |
| `samsung,exynos-bcm_dbg` | Bus/BCM debug interface | Vendor debug/firmware dependency pending |
| `samsung,exynos-tsmux` | Transport stream mux | Vendor multimedia mapping pending |
| `samsung,exynos-repeater` | Repeater hardware | Vendor multimedia mapping pending |
| `baaw_p_wlbt`, `dbus_baaw`, `pbus_baaw`, `wlbt_remap` | WLBT address windows/remapping | Syscon/register ownership and SCSC dependency need trace |

## Board-specific contracts

| Compatible | Board function | Porting requirement |
|---|---|---|
| `samsung,exynos9610` + `samsung,UNIVERSAL9610 A50 Rev 0.1` | Board identity | Preserve exact board match and revision semantics |
| `samsung,s2mpu09mfd` | PMIC MFD | Confirm MFD children, regulators, RTC/IRQ and suspend behavior |
| `siliconmitus,sm5713mfd` | USB/power companion IC | Confirm MFD child drivers and charger/USB notifications |
| `melfas,mms_ts` | Touchscreen | Confirm exact Melfas driver and GPIO/IRQ/reset sequencing |
| `realtek,rt5665` | Audio codec | Confirm codec driver, ASoC DAI links and clocks |
| `nxp,tfa98xx` | Smart amplifier | Confirm amplifier driver, firmware and audio routing |
| `samsung,exynos9610-audio` | ABOX/audio platform | Confirm vendor ABOX/ASoC graph and mailbox/IPC |
| `samsung,ufs-srpmb` | UFS RPMB | Confirm RPMB transport, secure provisioning and FMP relationship |
| `samsung,usb-notifier` | USB role/accessory notification | Confirm notifier consumer and charger integration |
| `samsung,dummy-cpu`, `snd-soc-dummy` | ASoC dummy endpoints | Preserve only if required by the board audio graph |
| `gpio-keys` | Physical keys | Generic driver; verify GPIO polarity, wake flags and debounce |

## Generic or established framework compatibles present

The DTS also uses generic/legacy bindings including:
- ARM: `arm,psci`, `arm,armv8-timer`, Cortex-A53/A73 CPU nodes, GIC, PMUv3 and PL330 DMA.
- Generic peripheral frameworks: `regulator-fixed`, `gpio-keys`, `synopsys,dwc3`, `arm,amba-bus`, `syscon`.
- Samsung legacy peripheral compatibles: Exynos MCT, UART, SPI, HSI2C, ADC, RTC, PWM and watchdog.
- Android boot metadata: `android,firmware`, `android,fstab`, `android,system`, `android,vendor`, `android,product`, `android,vbmeta`.

Even for generic compatibles, the vendor DTS properties, clocks, resets, IOMMU streams, PHYs and power domains must be checked against the v5.1 binding and driver. A generic compatible does not guarantee the surrounding Samsung integration is upstream-compatible.

## Required driver-binding matrix (next source task)

For each vendor-specific compatible above, the implementation must record:
1. DTS node path and whether `status` is enabled in the merged A50 DT.
2. Exact driver source file and `of_match_table` entry.
3. Kconfig symbol, Makefile object, module/built-in status and dependency chain.
4. All clocks, resets, regulators, interrupts, DMA/IOMMU, reserved-memory and firmware dependencies.
5. Whether upstream v5.1 has an equivalent driver; if yes, exact compatible/data support and API diff; if no, vendor port plan.
6. Compile status, probe status, functional test and suspend/resume test as separate columns.

## Porting order

**P0:** clock/CAL, pinctrl/EINT, PMU, ACPM/IPC, TZDEV/TEEGris/TZAR, UFS/FMP/RPMB, IOMMU and boot-critical firmware.

**P1:** thermal/cooling, DVFS/devfreq, display/DECON/DSIM/DPP, Mali, USB/PHY, SCSC/WLBT, touch and audio.

**P2:** camera/multimedia accelerators, sensor hub, FM, debug/diagnostic and optional peripherals.

## Safety and status

This audit adds no kernel implementation. It does not assert all listed compatible strings are active in the final device tree or that any driver binds. No Linux 5.1 build, DTB merge test, physical flash or boot test has been performed. Do not flash based on this inventory. Preserve the known-working 4.14.357 image and recovery path.
