# SOVR v4.1 Configuration Diff

The checked configuration is `arch/arm64/configs/exynos9610-a50_core_defconfig`, which `build.sh` copies before appending ROM and Android fragments.

| Symbol | Previous value | New value | Reason / dependency | Build and runtime verification |
|---|---|---|---|---|
| `CONFIG_ZRAM_DEF_COMP_ZSTD` | `y` | unset | Select LZ4 as the default compressor. ZSTD implementation remains enabled through `CONFIG_CRYPTO_ZSTD=y`. | Not built; not runtime-tested. |
| `CONFIG_ZRAM_DEF_COMP_LZ4` | unset | `y` | LZ4 is already enabled by `CONFIG_CRYPTO_LZ4=y`; it is a supported choice in this tree's ZRAM Kconfig. | Not built; not runtime-tested. |
| `CONFIG_ZRAM_DEF_COMP` | `"zstd"` | `"lz4"` | Make the generated compressor default explicit. | Final merged `.config` not generated. |

No other feature symbols were changed. The default defconfig does not specify a ZRAM compressor choice; the exact merged result still needs confirmation with the supported Linux build environment.

The original v4.0 defconfig is recoverable from the parent commit of this development branch.
