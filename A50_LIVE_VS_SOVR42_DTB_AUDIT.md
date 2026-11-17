# Galaxy A50 live DTB vs SOVR 4.2 DTB audit

Date: 2026-11-17

## Inputs and identification

- `A50_live.dtb`: raw flattened device tree, 219,477 bytes; SHA-256 `df2b97bb13d5e54f572492b2b01a649aa313b4421e726f2ee57af2e2a96679fc`.
- `dtb.img`: Android DT table image, 134,948 bytes; SHA-256 `7d3daa2b86230a3bcb2e381c9e9f0a4e5d0bdb4320bdf3891fc2661c059b2753`.
- Android DT table header: one entry, page size 2048, FDT payload offset 64, payload size 134,884 bytes.
- Extracted SOVR payload SHA-256: `bac1eb26da9596ca851c795bc3c94ab3018df18613addef2a7bf6120e6afc0a6`.
- Both payloads have valid FDT magic and parse as flattened device trees.

## High-level result

The core early-boot descriptions inspected are the same in both trees: eight CPU nodes, PSCI using SMC, the GIC node and its four register windows, and the ARMv8 architectural timer interrupt list/frequency.

This does NOT make the DTBs interchangeable. Their memory maps, initrd placement, board metadata, enabled/disabled peripheral nodes, and overall tree contents differ substantially.

## Structural comparison

| Item | A50 live DTB | SOVR 4.2 DTB payload |
|---|---:|---:|
| FDT size | 219,477 bytes | 134,884 bytes |
| Parsed nodes | 1,100 | 633 |
| Nodes only in live tree | 468 | — |
| Nodes only in SOVR tree | — | 1 |
| Nodes with status `okay` | 75 | 16 |
| Nodes with status `ok` | 5 | 5 |
| Nodes with status `disabled` | 56 | 86 |

## Core early-boot fields that match

- Root compatible: `samsung,armv8`, `samsung,exynos9610`.
- Eight CPUs: four Cortex-A53 with MPIDR 0..3 and four Cortex-A73 with MPIDR 0x100..0x103; all use `enable-method = psci`.
- PSCI node: compatible `arm,psci`, method `smc`.
- GIC compatible list: `arm,cortex-a15-gic`, `arm,cortex-a9-gic`.
- GIC register windows: 0x12301000/0x1000, 0x12302000/0x1000, 0x12304000/0x2000, 0x12306000/0x2000.
- GIC interrupt property: cells 1, 9, 0xf04.
- ARMv8 timer interrupt cells: 1,13,0xff08; 1,14,0xff08; 1,11,0xff08; 1,10,0xff08.
- Timer clock-frequency: 0x018cba80 (25 MHz).

These are observations from the uploaded blobs, not independent proof that the firmware or hardware will accept a newly built upstream v5.1 DTB.

## Critical mismatch: RAM map

Live DTB memory banks:
- 0x80000000 size 0x3ab00000
- 0xc0000000 size 0x20000000
- 0xe1900000 size 0x1e700000
- 0x880000000 size 0x80000000

SOVR 4.2 DTB memory banks:
- 0x80000000 size 0x80000000
- 0x880000000 size 0x80000000
- 0x900000000 size 0x80000000

The live DTB declares 3.893 GiB across fragmented low memory plus one 2-GiB high bank. The SOVR DTB declares 6 GiB across one 2-GiB low bank and two 2-GiB high banks. The live bank total is below the handset's nominal 4-GiB capacity; the difference is not explained by the memory nodes alone and must be reconciled with reserved/secure carveouts and the running kernel's `/proc/iomem` and `MemTotal`. The SOVR declaration is a material mismatch for the user's 4-GiB SM-A505F. Do not use the SOVR memory nodes as the basis for the user's device tree. Confirm the physical memory map against the running kernel's memory report and bootloader-provided DT before any port.

## Other significant differences

- Live root model identifies a Samsung A50 SWA OPEN rev04 Exynos9610 board. The SOVR payload has no root `model` property.
- Live `/chosen/bootargs` contains the device's boot arguments; the SOVR payload has an empty bootargs property. The live bootargs include device-specific identifiers; these are deliberately not reproduced in this report.
- Live initrd start/end: 0x89000000 / 0x8916f800. SOVR payload initrd start/end: 0x84000000 / 0x841fffff. These are boot-chain-specific and must not be copied into a generic upstream DTS.
- 468 nodes exist only in the live tree, including board/peripheral and platform configuration nodes. Many corresponding nodes in the SOVR tree are absent or disabled. A broad import of either tree would silently change hardware enablement.
- One node exists only in SOVR: `/memory@900000000`, which is part of the additional 2-GiB high-memory bank.

## Decision for Linux 5.1 port

1. Treat `A50_live.dtb` as the primary description of the currently running 4-GiB device, subject to validation against `/proc/iomem`, `MemTotal`, and the bootloader's DT/DTBO selection.
2. Treat SOVR 4.2 `dtb.img` as a comparison artifact, not a drop-in DTB.
3. Reuse matching CPU/PSCI/GIC/timer facts only after checking Linux v5.1 binding/driver compatibility.
4. Do not import SOVR memory nodes, initrd addresses, empty bootargs, or disabled-node state into the new upstream DTS.
5. Build the first upstream DTS with a minimal, validated early-boot subset; add board peripherals only alongside their compatible drivers and dependencies.
6. Before a boot test, compare the compiled DTB against the live tree and verify every RAM and reserved-memory range is non-overlapping, in-range, and correct for this exact 4-GiB handset.

## Privacy note

The live DTB contains unique device identifiers in its bootargs. Keep the original upload private and do not publish it in the repository. This report intentionally omits those values.

## Test status

No kernel source, DTS, Kconfig, or Kbuild file was changed by this audit. No target kernel or DTB build was run. No boot or runtime success is claimed.