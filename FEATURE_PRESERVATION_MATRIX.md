# Feature preservation matrix

The upstream merge altered the A50 defconfigs. This table records the post-merge settings and the preservation changes made in both `exynos9610-a50_core_defconfig` and `exynos9610-a50_default_defconfig` where applicable.

| Feature | Resulting selection | Evidence / limitation |
| --- | --- | --- |
| I/O schedulers | Anxiety remains the default; CFQ, CFQ group scheduling, FIOPS, SIO, ZEN, NOOP, and Kyber remain selectable/built | The legacy scheduler Kconfig entries still exist in `block/Kconfig.iosched`. |
| KSM | Enabled in the core defconfig; remains enabled in the default defconfig | Runtime use depends on userspace marking pages mergeable. |
| USB networking | USB networking core, RTL8150/RTL8152, AX8817X/AX88179, CDC Ethernet/EEM/NCM, SMSC75XX/95XX, NET1080, CDC subset, Belkin, ARM Linux, and Zaurus options are enabled | The related options remain in `drivers/net/usb/Kconfig`; adapter compatibility is not tested. |
| Block writeback throttling | WBT and WBT MQ enabled | Configuration evidence only. |
| Memory and compression | MGLRU enabled; ZRAM defaults to LZ4; `CRYPTO_ZSTD` and ZSTD compression support remain enabled | LZ4 is the selected default, not a benchmark result. Runtime compressor availability should be confirmed on-device. |
| Filesystems and storage | UFS, F2FS, EROFS, and the Exynos MMC host are enabled | Filesystem mount compatibility remains ROM/device dependent. |
| Networking | BBR is default; CAKE and FQ_CODEL are enabled | FQ-PIE is absent from the source and is not included in this matrix. |
| Hardware crypto | ARM64 AES, SHA, CRC, and ChaCha20 implementations remain selected | Effective use and performance depend on runtime crypto selection. |
| Samsung WLAN | SCSC WLAN and One UI/AOSP variant fragments remain in place | Wi-Fi operation must be checked on the actual ROM. |

The optional legacy schedulers and USB adapters are preserved as available kernel features, not selected as defaults. The default I/O scheduler remains Anxiety. Final Kconfig resolution and compilation are delegated to CI; a defconfig line by itself does not prove a symbol survives `olddefconfig`.
