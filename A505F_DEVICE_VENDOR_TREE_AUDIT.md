# A505F Device and Vendor Tree Audit

Audit date: 2026-11-17

Repositories reviewed:

- Device tree: https://github.com/GiovanYCringe-Experiments/android_device_samsung_a505f
- Vendor tree: https://github.com/GiovanYCringe-Experiments/android_vendor_samsung_a505f
- Referenced kernel tree: https://github.com/GiovanYCringe-Experiments/kernel_a50

This is a source inspection, not a successful Android build, kernel build, or hardware boot test.

## Executive assessment

The device and vendor trees are useful historical Galaxy A50 integration references. They contain device-specific boot-image parameters, DTBO selection, partition paths, init scripts, firmware manifests, proprietary HAL declarations, TEEGris configuration, and thermal/power policy.

They are **not** a Linux 5.1 port and must not be treated as a ready-made kernel migration patch. The device tree's own build helper clones a separate kernel repository whose default branch is `Lineage-20`; that kernel's top-level Makefile identifies it as Linux **4.14.161**. This is older than the SOVR v4.0 Linux 4.14.357 baseline and is not a replacement for the SOVR source.

The two Android repositories' reviewed branches are `thirteen`. Their latest commits are from July 2023:
- Device tree head: `19780996ee0bc32e764c529b146d38d562a64993` (2023-07-21).
- Vendor tree head: `1c890dff48bd1f571842fc569ac4d2625359d965` (2023-07-18).

Repository metadata may have been updated later, but the reviewed source branch heads are old. Do not interpret a metadata update as active source maintenance.

## 1. Device tree findings

### Board and boot image

Reviewed `BoardConfig.mk` (blob `65e59e645dee30f437ba73e962fc24485fda062f`):
- ARM64 primary architecture, ARM 32-bit secondary ABI, Cortex-A53 target CPU variant.
- Platform identifiers: `universal9610`, `exynos9610`.
- Boot image header version 1, 2048-byte pages, kernel base `0x10000000`, kernel offset `0x8000`, ramdisk offset `0x01000000`, tags offset `0x100`.
- Boot partition size is 57,671,680 bytes (55 MiB); recovery is 67,633,152 bytes.
- Separate DTBO image is enabled; DTBO configuration is selected from `configs/kernel/$(TARGET_DEVICE).cfg`.
- The tree's filesystem image defaults are ext4; this does not describe the current SOVR Android 14 EROFS installation.
- `TARGET_KERNEL_SOURCE := kernel/samsung/a50` and `TARGET_KERNEL_CONFIG := a50-lemonade_defconfig`.

The boot parameters and partition sizes are useful cross-checks, but should be compared against the actual device's boot image, PIT/partition map, and current ROM packaging before reuse.

### Kernel toolchain inconsistency

The same `BoardConfig.mk` declares:
- `TARGET_KERNEL_CLANG_COMPILE := true`
- `TARGET_KERNEL_CLANG_VERSION := r383902`

But `vendorsetup.sh` clones the standalone Clang branch/path named `clang-r399163b1` (branch 11). This is an apparent toolchain-version/path mismatch. A clean Android build environment would need to resolve which compiler is actually selected; do not copy this setup as a reproducible recipe without fixing and verifying it.

The helper also clones the kernel repository without an explicit branch. The repository default branch at audit time is `Lineage-20`.

### DTBO selection

`configs/kernel/a505f.cfg` enumerates the A50 DTBO variants:
- `exynos9610-a50_swa_open_00.dtbo`
- `..._01.dtbo`
- `..._02.dtbo`
- `..._03.dtbo`
- `..._04.dtbo`
- `..._06.dtbo`

The custom0/custom1 values differ by variant. This is useful evidence for A50 board/DTBO selection, but the DTBO binaries and matching source DTS must be checked against the exact kernel/ROM being built. Do not infer that the list is exhaustive for every A505F/A505FN hardware revision.

### Partition and filesystem assumptions

Reviewed `configs/init/fstab.exynos9610` (blob `72b0162d33062c9f2d7c687449b9b195fc032613`):
- UFS paths use `/dev/block/platform/13520000.ufs/by-name/`.
- `system` and `vendor` are ext4 first-stage mounts.
- `userdata` has both F2FS and ext4 entries.
- `boot`, `recovery`, `cache`, `efs`, `cpefs`, and `misc` entries are declared.
- The fstab does not declare a separate product partition.
- ZRAM is configured as `/dev/block/zram0` with `zramsize=2684354560` (2.5 GiB) and `max_comp_streams=8`.

Important for this project:
- This fstab is not the user's current Android 14 One UI/EROFS layout. It mounts system/vendor as ext4 and must not be copied over the current ROM fstab.
- Its 2.5 GiB zram size is a historical ROM choice, not evidence of an optimal setting for the user's 4 GiB A50 or the SOVR kernel.
- The duplicate userdata filesystem entries need to be understood in the context of the ROM/recovery init implementation before reuse.
- The no-separate-product-partition detail is consistent with an A-only legacy layout, but the actual target partition map remains authoritative.

## 2. Init scripts: kernel ABI dependencies to preserve or deliberately replace

Reviewed `configs/init/init.exynos9610.rc` (blob `d6c485c76eb4b7b4a68e2d3e62280a3ef92ba398`).

The script depends on numerous vendor-kernel interfaces. These are especially important for a 5.1 port because compiling a kernel is insufficient if userspace init scripts, power HALs, or Samsung daemons expect sysfs/procfs/cgroup nodes that the port no longer exposes.

Observed dependencies include:
- Scheduler tuning: `/dev/stune`, `schedtune.boost`, `schedtune.prefer_idle`, `schedtune.prefer_perf`, `schedtune.util_est_en`, and `schedtune.ontime_en`.
- CPU frequency controls: `/dev/cluster0_freq_min`, `cluster0_freq_max`, `cluster1_freq_min`, `cluster1_freq_max`, and `/dev/cpu_dma_latency`.
- Freezer cgroup: mounts the legacy `freezer` controller at `/dev/freezer` and creates Samsung-specific groups such as `frozen`, `thaw`, `olaf`, and `abnormal`.
- Debug and graphics: mounts debugfs and writes `/sys/module/g2d_task/parameters/block_on_contension`.
- Sensor hub: expects `/dev/nanohub` and `/dev/nanohub_comms`.
- SCSC Wi-Fi/Bluetooth: expects `scsc_bt` module parameters and network queue/RPS controls.
- ZRAM activation: calls `swapon_all /vendor/etc/fstab.exynos9610`.

These interfaces are not guaranteed to exist in upstream Linux 5.1. For every item, the migration needs a provider audit:
1. Find the original driver/Kconfig/sysfs or cgroup implementation in the vendor kernel.
2. Determine whether Linux 5.1 has an equivalent upstream interface.
3. If it does not, port the smallest necessary implementation or update the userspace consumer deliberately.
4. Validate permissions, init ordering, SELinux policy, and runtime behavior.
5. Never silently ignore missing nodes for critical power, storage, modem, TEE, or thermal paths.

Do not copy this init script wholesale into the current ROM. It is tied to the historical Android 13 device tree and its kernel ABI.

## 3. Power and thermal policy

The device tree includes a Samsung power hint configuration and a thermal info configuration.

The power hints reference vendor paths such as `/sys/power/cpufreq_max_limit`, `/sys/power/cpufreq_min_limit`, cluster frequency limits, scheduler/cpuset controls, low-power proximity/FOD controls, and power HAL state nodes. The interactive and camera hints can request high CPU frequencies (including 2,314,000 kHz and 1,976,000 kHz in the inspected config).

Implications:
- These are userspace policy requests, not proof that the kernel supports each node or that the requested limits are sustainable.
- For the SOVR project's battery/temperature priorities, do not import aggressive min-frequency boosts without measuring residency, thermals, frame-time, and battery drain.
- The thermal config describes BIG/LITTLE/G3D/ISP and battery/USB sensors plus CPU/GPU/ISP cooling devices. Sensor names, units, and thresholds must match the target kernel's thermal driver output. A JSON config alone does not validate sensor calibration.

## 4. Vendor tree and proprietary integration

The vendor tree's default branch is `thirteen`. Its generated build files include:
- `a505f-vendor.mk`: proprietary file copy rules.
- `Android.bp`: Soong declarations for prebuilt Mali, Exynos HWC/gralloc/display/scaler/V4L2, GNSS, keymaster, radio, and related components.
- `BoardConfigVendor.mk`: empty generated stub in the reviewed revision.
- `Android.mk`: generated stub with no meaningful device-specific build rules.

The device tree's `proprietary-files.txt` identifies a Samsung firmware base of `A505FDDU9CVC2` unless individual entries are pinned otherwise. The manifest covers audio, camera, fingerprint, GNSS, graphics, OMX, RIL, Wi-Fi/BT, TEE/Mobicore, and firmware files. The vendor tree includes proprietary TEEGris-related files and init configuration.

This is useful as a dependency inventory for understanding what the A50 Android userspace expects. It is not a license to redistribute Samsung proprietary binaries, and these blobs should not be copied into the kernel source repository. Keep device/vendor blobs separate from GPL kernel source and use legally obtained device-extracted firmware when required.

The device VINTF manifest advertises HIDL services including audio 7.1, audio effects 7.0, Bluetooth 1.0, camera provider 2.4, GNSS 2.1, graphics allocator 2.0/composer 2.2, keymaster 3.0, radio 1.4, and Samsung radio/GNSS interfaces. These versions are Android userspace compatibility information, not kernel ABI guarantees.

## 5. Product identity and Android release scope

The product makefile is named `lineage_a505f.mk` and identifies the product as `lineage_a505f`, model `SM-A505F`, shipping API level 28. It also sets `PRODUCT_SYSTEM_NAME := OnePlus9` and a OnePlus 9 Android 13 build fingerprint as build-property overrides. This is a build identity/fingerprint customization, not evidence that the device is a OnePlus or that the vendor HALs are OnePlus-compatible.

The tree is therefore best classified as a historical Lineage-based Android 13 device integration. It is not a drop-in device tree for the user's Android 14 One UI custom ROM, and it does not establish Android 16 compatibility.

## 6. Referenced kernel repository assessment

The device helper clones `GiovanYCringe-Experiments/kernel_a50`. The reviewed default branch is `Lineage-20`; its `Makefile` reports:

```make
VERSION = 4
PATCHLEVEL = 14
SUBLEVEL = 161
```

Its `arch/arm64/configs/a50-lemonade_defconfig` contains A50-relevant vendor integrations and features including:
- `CONFIG_SOC_EXYNOS9610`, `CONFIG_ARCH_EXYNOS9`, eight CPUs.
- Samsung TZDEV/TZLOG/TEE deployment options.
- SCSC WLAN/BT and platform configuration `leman_s620_univ`.
- Exynos UFS and FMP.
- ION/Exynos heaps, thermal, CPUFreq/schedutil, SCHED_EMS/SCHED_TUNE, BFQ, ZRAM, F2FS, and ext4.

These are useful clues for dependency discovery. They are not a safe config transplant:
- The kernel is 4.14.161, not the SOVR 4.14.357 source baseline.
- The config contains vendor-specific symbols and drivers that need source-level mapping.
- Scheduler, memory, I/O, and power options have version-specific semantics.
- A symbol being enabled in this defconfig does not prove that its implementation is compatible with Linux 5.1.

The historical config also includes `CONFIG_OLAF_SUPPORT` and other Samsung/vendor facilities. Their userspace contracts should be investigated before any attempt to replace them.

## 7. Relevance to the SOVR Linux 5.1 project

### Safe material to reuse as reference

1. A50 boot image offsets, header version, and partition sizes (after cross-checking the exact device).
2. A505F DTBO variant names and custom values.
3. UFS by-name partition naming and A-only/no-product layout clues.
4. Firmware/proprietary HAL dependency names and TEEGris integration inventory.
5. Thermal sensor/cooling-device names for comparison with the vendor thermal driver.
6. Init-script references as a checklist of kernel ABI expected by Android userspace.
7. Exynos9610 config features as a search index for vendor driver dependencies.

### Do not transplant directly

1. The 4.14.161 kernel tree or its defconfig.
2. The Android 13 fstab into the current Android 14 One UI EROFS ROM.
3. The 2.5 GiB zram sizing as an optimization recommendation.
4. The old powerhint values or frequency boosts.
5. The full init script, SELinux policy, VINTF manifest, or vendor blobs without matching Android platform/vendor versions.
6. The Clang setup until the r383902 vs r399163b1 mismatch is resolved.

### Next engineering actions

- Diff the 4.14.161 kernel's Exynos9610 DTS, clock/CAL, TZDEV, SCSC, UFS/FMP, thermal, cpufreq, scheduler, and memory drivers against the SOVR 4.14.357 source. This may reveal lineage and implementation variants, but do not use it as the port base.
- Build a userspace-to-kernel ABI inventory from `init.exynos9610.rc`, powerhint, thermal config, VINTF, and proprietary init rc files.
- Map each required interface to its SOVR 4.14.357 provider, then to the Linux 5.1 port plan.
- Prioritize early boot dependencies: UFS, FMP/crypto, DTB/DTBO, clocks/CAL/PMUCAL/ACPM, TZDEV/TEEGris, memory/ION, thermal, SCSC Wi-Fi/BT, audio ABOX, display/HWC, and modem.
- Preserve the known-good 4.14.357 path and keep all 5.1 work isolated until compile, image packaging, recovery install, and real-device boot validation are independently demonstrated.

## Source references

- Device tree branch: https://github.com/GiovanYCringe-Experiments/android_device_samsung_a505f/tree/thirteen
- Device tree BoardConfig: https://github.com/GiovanYCringe-Experiments/android_device_samsung_a505f/blob/thirteen/BoardConfig.mk
- Device tree init: https://github.com/GiovanYCringe-Experiments/android_device_samsung_a505f/blob/thirteen/configs/init/init.exynos9610.rc
- Device tree fstab: https://github.com/GiovanYCringe-Experiments/android_device_samsung_a505f/blob/thirteen/configs/init/fstab.exynos9610
- Device tree product makefile: https://github.com/GiovanYCringe-Experiments/android_device_samsung_a505f/blob/thirteen/lineage_a505f.mk
- Device tree proprietary manifest: https://github.com/GiovanYCringe-Experiments/android_device_samsung_a505f/blob/thirteen/proprietary-files.txt
- Vendor tree: https://github.com/GiovanYCringe-Experiments/android_vendor_samsung_a505f/tree/thirteen
- Vendor proprietary makefile: https://github.com/GiovanYCringe-Experiments/android_vendor_samsung_a505f/blob/thirteen/a505f-vendor.mk
- Referenced kernel Makefile: https://github.com/GiovanYCringe-Experiments/kernel_a50/blob/Lineage-20/Makefile
- Referenced kernel defconfig: https://github.com/GiovanYCringe-Experiments/kernel_a50/blob/Lineage-20/arch/arm64/configs/a50-lemonade_defconfig
