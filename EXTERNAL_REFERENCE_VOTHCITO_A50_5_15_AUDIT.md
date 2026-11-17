# External Reference Audit — Vothcito Exynos9610 A50 Kernel

Audit date: 2026-11-17

## Reference repository identity

- Repository: https://github.com/Vothcito/android_kernel_samsung_exynos9610_a50
- Default branch: `exynos9610-port`
- Observed HEAD: `ace96fa34c0d8303a23c5518aae751a91274552b`
- HEAD date: 2026-07-24 23:14:19 UTC
- Repository description: work-in-progress Linux 5.15 kernel port for Samsung Galaxy A50 / Exynos 9610.
- Public repository; the connected GitHub integration has read-only permissions (no push/admin permission).
- Releases endpoint returned an empty list; pull-request listing returned an empty list.
- Root listing did not contain a `.github` directory; no repository Actions workflow was found in the inspected root. This is not evidence of a successful automated build.
- Recursive tree request returned 75,300 entries with `truncated: true`; therefore this is a targeted audit, not a complete source-tree audit.

## Project maturity and target-version distinction

The reference is a **Linux 5.15** project, not a Linux 5.1 project. Its top-level Makefile declares:

- `VERSION = 5`
- `PATCHLEVEL = 15`
- `SUBLEVEL = 211`

The README says it is an early-stage research/development port focused on SoC infrastructure adaptation, reduction of Samsung legacy dependencies, 4.14-to-5.15 compatibility analysis, and preparation for a first functional compilation. It describes Image/DTB plus initial AnyKernel3 packaging as goals. It explicitly says the project is not intended for daily use in its current state.

**Evidence status:** source tree and README inspected; no successful compile, boot, or hardware validation was established by this audit. Do not treat the repository name, README goals, or presence of drivers as proof of a working kernel.

## Important configuration provenance warning

The reference branch's `arch/arm64/configs/exynos9610-a50_core_defconfig` begins with the generated header:

`# Linux/arm64 4.14.194 Kernel Configuration`

This conflicts with the live top-level Makefile's Linux 5.15.211 version. The config may be inherited/stale or otherwise not regenerated for the 5.15 tree. It must not be treated as a verified 5.15 configuration. The same 4.14.194 header discrepancy is present in the SOVR baseline config and is already tracked in the migration status. This independently reinforces the need to regenerate and validate every target config with the actual target Kconfig and record the resulting `.config`.

## Exynos9610 CAL / PMUCAL comparison

The reference contains a substantial Samsung CAL implementation:

- `drivers/soc/samsung/cal-if/`
- `drivers/soc/samsung/cal-if/exynos9610/`
- `drivers/soc/samsung/exynos9610/`
- `drivers/clk/samsung/clk-exynos9610.c`

The following files have identical Git blob hashes to the corresponding SOVR source already inventoried:

| File | Blob SHA | Finding |
|---|---|---|
| `drivers/soc/samsung/cal-if/Makefile` | `00944ace1b772acd0193edf80792dd7b884e4c0a` | Exact content identity |
| `drivers/soc/samsung/cal-if/cal-if.c` | `35c62490a906259667bc347231a7e35dc8b0b514` | Exact content identity |
| `drivers/soc/samsung/cal-if/cmucal.h` | `56e71d6cdcc49b3dd5daf530d7cac147b677a3fc` | Exact content identity |
| `drivers/soc/samsung/cal-if/ra.h` | `de810e9b413991ba411bce08d0e70696f2c92e3b` | Exact content identity |
| `drivers/soc/samsung/cal-if/vclk.h` | `2d28de79a20fc5f6124b4300ef0e9967ec5a95b2` | Exact content identity |
| `drivers/soc/samsung/cal-if/pmucal_local.h` | `042f678747c861bba7f103dbac9be6d9405f5de7` | Exact content identity |
| `drivers/soc/samsung/cal-if/pmucal_system.h` | `9a4bb18aa90c326cd5e482e2ea96ec9b9c2f3f87` | Exact content identity |
| `drivers/soc/samsung/cal-if/pmucal_cpu.h` | `dd5544383ce26f0da7004fb7940556cb812ae947` | Exact content identity |
| `drivers/soc/samsung/cal-if/pmucal_rae.h` | `9f6dc75f618a1a88b667184c96265426744d8909` | Exact content identity |

This is useful corroboration of the Samsung vendor source lineage. It does **not** establish that those files have been ported to Linux 5.15 APIs or that they compile there. The matching files are identical source, not independently modernized implementations.

A notable divergence exists in `drivers/clk/samsung/clk-exynos9610.c`:

- SOVR main blob: `1ecdd4ea5b66601c2a68a1d8eefaf992505b2061`
- Vothcito blob: `dcd2d2f8c85fa1f741db0beb5d70b7dc21138579`

The Vothcito version includes SoC clock data from `../../soc/samsung/exynos9610/`, while SOVR main uses `../../soc/samsung/cal-if/exynos9610/`. It still includes Samsung CAL headers and custom `composite.h` and uses `struct init_vclk` / `HWACG_VCLK` descriptors. This is not evidence of a conversion to a purely upstream Common Clock Framework implementation. The include-path change and the two SoC-data directory layouts require a line-by-line dependency and Kbuild audit before reuse.

The Vothcito CAL Makefile builds `cal-if.o`, PMUCAL components, CMUCAL/RA/VCLK/PLL specification objects, ACPM DVFS/FVMAP and Exynos9610 `cal_data.o`. This is a useful inventory of the subsystem's compilation units.

## Device Tree observations

The reference includes `arch/arm64/boot/dts/exynos/exynos9610-universal9610.dts`, which is an overlay/plugin and identifies a Samsung UNIVERSAL9610 A50 Rev 0.1 board. It includes battery, camera, display and modem platform data, and has vendor-specific PMIC/regulator and peripheral descriptions.

Caution:
- This file's presence does not prove it is the exact production SM-A505F DTB/DTBO used by the user's installed ROM.
- Its bootargs include `androidboot.selinux=permissive`; do not copy this into SOVR or recommend it as a security setting.
- Its fstab fragment references a vendor partition path and ext4 vendor mount; do not assume it matches the current EROFS system/vendor arrangement.
- The inspected Exynos DTS directory contains a generic `exynos9610.dtb` build target and the `exynos9610-universal9610.dts` board overlay; exact bootloader DTB/DTBO packaging still needs to be verified against A50 firmware and current SOVR packaging.

## ZRAM comparison

The reference's `drivers/block/zram/Kconfig` exposes standard ZRAM compressor choices (including LZO-RLE, ZSTD, LZ4, LZO, LZ4HC and 842), standard `CONFIG_ZRAM_WRITEBACK`, and `CONFIG_ZRAM_MEMORY_TRACKING`.

The inspected Kconfig does not expose SOVR's custom LRU writeback / SQZR options. Thus the reference may help compare upstream 5.15 ZRAM interfaces and writeback semantics, but it is not a drop-in preservation source for SOVR's extended writeback implementation. The selected compressor and actual `.config` values were not fully validated here; Kconfig choices alone do not establish runtime behavior or compatibility with the user's loop-backed `/data/per_boot/zram_swap` device.

## TrustZone and Samsung vendor feature gap

The expected path `drivers/misc/tzdev/` was not present in the reference repository at the inspected path. This is a meaningful warning because SOVR contains Samsung TZDEV/TEE deployment code and the user's earlier boot investigations included TZAR deployment. Do not infer that all secure-world support is absent elsewhere in the reference tree; perform a full symbol/path search before concluding that. No TEE or secure-boot equivalence has been established.

## Preservation and reuse decisions

| Subsystem | Reference value | SOVR decision |
|---|---|---|
| CAL / CMUCAL / PMUCAL | Same vendor source blobs for several core files; full Exynos9610 data directories present | Use as cross-check/source-lineage evidence; do not copy blindly or claim 5.15 API compatibility |
| Exynos9610 clock driver | Divergent file and include-path layout; retains vendor CAL abstractions | Diff against SOVR and map Kbuild/header dependencies before any adaptation |
| Device Tree | Exynos9610 universal A50 Rev 0.1 overlay and related DTSI data | Compare node-by-node with SOVR A50 tree and device DTB; no wholesale replacement |
| ZRAM | Linux 5.15-era standard writeback and compressor Kconfig | Compare APIs; preserve SOVR SQZR/LRU features independently |
| TZDEV / TEE | Expected `drivers/misc/tzdev` path absent | Keep SOVR implementation as required baseline; investigate reference tree for alternate secure-world code |
| KernelSU / SuSFS | Not established by this targeted inspection | No compatibility credit until exact sources, hooks and build integration are inspected |
| Build / CI / ZIP | README describes goals; no root `.github` directory, release assets or PRs observed | No evidence of reproducible build, installable ZIP, automated validation, or hardware test |

## Engineering conclusion

This reference is valuable because it exposes a Linux 5.15 A50/Exynos9610 research tree and preserves substantial Samsung CAL/PMUCAL and device-tree material. Its most useful immediate contribution is cross-checking the Exynos9610 SoC infrastructure and revealing an alternative clock-driver layout.

It does **not** reduce the core Linux 5.1 migration risk to a solved problem. It targets 5.15, is explicitly early-stage, carries a stale 4.14.194 config header, and has no demonstrated compile/boot/hardware validation in the inspected evidence. It also does not establish preservation of SOVR's TZDEV, ZRAM extensions, KernelSU/SuSFS, EROFS/ROM packaging or daily-driver feature set.

**Action:** retain as a read-only comparative reference. The next concrete technical task is to diff its Exynos9610 clock-driver and CAL include/Kbuild graph against SOVR and the existing CAL port plan, then compare the universal9610 overlay against the exact SOVR A50 DT sources. Do not merge or import source until the dependency graph and target-version API compatibility are documented.
