# Galaxy A50 memory and DTB porting contract — follow SOVR 4.2

Date: 2026-11-19
Target branch: `linux-5.1-exynos9610-integration`

## Binding project decision

The Linux 5.1 A50 port must use the same memory/DTB porting method as the working SOVR 4.2 A50 kernel. Do not redesign memory handling, invent RAM-size detection, or create separate 4 GB and 6 GB kernel/DTB variants.

The user confirms that the SOVR 4.2 method is successfully used on both 4 GB and 6 GB Galaxy A50 devices. Preserve that behavior as a hard compatibility requirement.

## What the inspected SOVR 4.2 artifacts show

- SOVR 4.2 ships one base `dtb.img` table entry for Exynos9610, with hardware revision range `custom0=0x00000000`, `custom1=0x000000ff`.
- The flashable package stages the kernel Image and `dtb.img`; it does not package a custom `dtbo.img`.
- The AnyKernel installer writes the base DTB to the `dtb` partition and patches the boot image. It does not write the stock `dtbo` partition.
- Samsung's stock `dtbo` partition remains responsible for board-revision overlays.
- The inspected SOVR 4.2 DTS flavors use the same three-bank 2 GiB placeholder memory layout:
  - `memory@80000000`
  - `memory@880000000`
  - `memory@900000000`
- On the inspected SM-A505F 4 GB live boot, S-Boot rewrites the static placeholder memory nodes according to the detected DRAM layout: it trims/splits the low bank, preserves the high bank, and removes the third bank. Thus the static three-bank placeholder is not the final live memory map.
- The live bootargs on that one inspected 4 GB device report a 4G DRAM signal. The stock DTBO overlay does not perform RAM-size selection or modify memory nodes.

## Required Linux 5.1 port behavior

1. Reproduce SOVR 4.2's base-DTB table and hardware-revision range semantics.
2. Keep the SOVR 4.2 three-bank placeholder memory layout and compatible node names/structure; do not replace it with a hand-authored 4 GB map or a fabricated 6 GB map.
3. Let Samsung S-Boot provide the runtime memory layout, exactly as the SOVR 4.2 boot chain does. Do not add kernel-side RAM-size heuristics or fixed-size memory overrides.
4. Preserve the existing stock `dtbo` partition. Do not package, flash, or require a replacement DTBO as part of this port.
5. Preserve SOVR 4.2's installer behavior for the `dtb` partition and boot image; do not touch `dtbo`.
6. Preserve SOVR 4.2's required S-Boot-added reserved-memory and bootargs contract. Do not copy the one-device live 4 GB memory map, initrd values, bootargs, or device identifiers into the static DTS.
7. Keep one shared Image and base DTB for 4 GB and 6 GB A50 variants. No RAM-specific branches, kernel forks, or separate DTB payloads.
8. Do not claim independent validation for every SKU/board revision without corresponding live evidence. The compatibility target remains both RAM capacities; retain SOVR 4.2's proven method rather than narrowing it to the one available 4 GB dump.

## Verification gates

- Binary-compare the Linux 5.1 DTB table header, entry count, entry metadata, custom hardware-revision range, and payload selection behavior against the SOVR 4.2 artifact.
- Compare the static memory node names, addresses, sizes, and cell widths against the SOVR 4.2 DTS/payload.
- Confirm the AnyKernel package writes only the `dtb` partition and never `dtbo`.
- Verify the composed live FDT after S-Boot on 4 GB and 6 GB devices before claiming runtime validation. Compare `/proc/iomem`, memblock logs, `MemTotal`, and bootargs without storing device identifiers.
- Do not flash intermediate DTB/boot artifacts. A generic ARM64 build or DTB compile is not a device boot test.

## Evidence boundary

The exact SOVR 4.2 base-DTB + stock DTBO entry 5 + S-Boot composition was compared against one SM-A505F 4 GB live FDT. The 6 GB compatibility requirement is user-confirmed from SOVR 4.2 usage, but no 6 GB live dump was present in the inspected evidence set. The port must preserve the SOVR 4.2 mechanism and keep 6 GB compatibility as a mandatory acceptance target.
