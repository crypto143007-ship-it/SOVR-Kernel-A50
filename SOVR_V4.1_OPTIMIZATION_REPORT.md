# SOVR v4.1 Optimization and Source Audit

## Scope and evidence

The audit inspected the fork's README files, Linux version Makefile, A50 core/default defconfigs, build script, build fragments, and the two existing GitHub Actions workflows. The source Makefile reports Linux 4.14.357. The core defconfig header still says 4.14.194, so that generated-file metadata is stale. No final merged `.config` was generated.

The following are source/configuration observations only. They do not prove runtime registration, hardware acceleration, stability, power use, or ROM compatibility.

| Area | Source/config finding | Validation status |
|---|---|---|
| ARM64 crypto | Core defconfig enables AES ARM64/CE, GHASH CE, SHA1/SHA2 CE, CRC32 CE, and ChaCha20 NEON. | Runtime `/proc/crypto`, self-tests, and benchmarks not run. |
| ZRAM | Core defconfig selected ZSTD; LZ4 and ZSTD implementations are enabled. This branch changes the default to LZ4. | Final merged config and device benchmark not run. |
| Memory | MGLRU is enabled; KSM is also enabled. | No memory-pressure or app-retention test. |
| Block I/O | Anxiety is the default scheduler; Kyber is enabled; BFQ is disabled. `CONFIG_BLK_WBT` is unset. | No UFS latency or scheduler comparison. |
| UFS/MMC | Exynos UFS host support and generic MMC/Exynos MMC support are present. The core and default defconfigs differ on FMP-related settings. | Final effective config, inline encryption, UFS, microSD, and recovery access not tested. |
| Networking | BBR, CAKE, and FQ_CODEL are configured. The checked-in `net/sched/Kconfig` and `Makefile` have no FQ-PIE entry. | Runtime qdisc/congestion availability and network measurements not tested. |
| Samsung connectivity | Core config enables SCSC Wi-Fi NAPI/GRO and low-latency mode; the default defconfig differs on NAPI. | Firmware, Wi-Fi, Bluetooth, mobile data, and tethering not tested. |
| USB Ethernet | RTL8152, AX88179, and CDC Ethernet are configured in the A50 config. | Devices not tested. |
| Filesystems | F2FS, EROFS with ARMv8 accelerated LZ4, and OverlayFS are configured. AOSP package ZRAM writeback now checks the vendor filesystem and skips EROFS or unknown results. | Mount, encryption, recovery, and installer behavior not tested on a device. |
| Compiler | Clang 17/LLD, ThinLTO, and Polly are configured/documented. Full LTO remains experimental/unverified. The top-level and ARM64 Makefiles contain both A53 and A73 CPU-tuning options. | Effective compiler flags, Polly invocation, and reproducible comparison builds not verified. |
| GPU | Build fragments select R32P1 for Android 12 and R38P1 for Android 14. | Driver build, display, camera, video, gaming, and suspend/resume not tested. |
| SELinux | One UI fragment selects `CONFIG_ALWAYS_ENFORCE`; AOSP selects `CONFIG_ALWAYS_PERMIT`. The boot argument was hard-coded to permissive for every profile and is corrected here to match the selected profile. | Runtime enforcement and policy compatibility not tested. |

## Important configuration-layer differences

`build.sh` starts with `exynos9610-a50_core_defconfig`, appends Android-version and ROM-variant fragments, and exports `KCONFIG_BUILTINCONFIG` for the separate A50 default defconfig. Several hardware settings differ between those two defconfigs. Until a Linux build produces the final `.config`, the effective values for UFS FMP, SCSC NAPI, Mali, and related options remain unverified.

## Safe changes made

The LZ4 default change preserves ZSTD support and does not remove compressor code. The EROFS-aware package guard preserves the existing non-EROFS AOSP writeback path while skipping it when EROFS is detected or filesystem identification fails. The build-script change aligns artifacts with the selected SELinux profile and fails early on unsuccessful build commands. The existing development workflow now runs on pushes to this branch with read-only repository permissions. No clock, voltage, thermal, storage-integrity, or hardware-driver behavior was altered.

## Outstanding acceptance work

FQ-PIE needs a source-compatible 4.14 backport and build validation before it can be enabled. Mint patch diffs, full device-tree/driver interactions, One UI 6.1.1/7/8, and all runtime/performance criteria remain unverified. No performance numbers are claimed.
