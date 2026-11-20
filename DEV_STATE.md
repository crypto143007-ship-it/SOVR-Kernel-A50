# Linux 5.1 Exynos9610 A50 Integration State

**Active project:** Unified Linux 5.1 kernel for Samsung Galaxy A50 / Exynos9610 / ARM64.
**Reference baseline:** SOVR 4.2 (Linux 4.14.357), used as the known-good hardware/boot-chain reference, not as the target kernel source.
**Active branch:** `linux-5.1-exynos9610-integration`.
**Priority:** finish a complete, reproducible and bootable A50 kernel before performance tuning.
**Do not modify:** `main` or the working SOVR 4.2 / Linux 4.14.357 baseline as part of this migration.

## Authoritative handoff and design rules

The complete user-supplied `A50_HANDOFF_FOR_CHATGPT.md` was reread on 2026-11-20. The reconciled rules are recorded in `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md`, Phase 21.

- One shared kernel and one shared static base DTB for the A50 family; no per-RAM kernel or DTB forks.
- Preserve the SOVR 4.2 base DTB's three static 2-GiB memory placeholders and one-entry DT table (`custom0=0`, `custom1=0xFF`). Samsung S-Boot rewrites the final memory nodes/bootargs at boot.
- Keep the stock Samsung DTBO partition untouched. SOVR does not ship a custom matching DTBO. Samsung overlays are selected by hardware-revision ranges, not the repository's generic board_id/board_rev diagnostic overlay.
- Never copy the live FDT's S-Boot-generated /chosen bootargs/initrd or final RAM map into the common DTS.
- Preserve and account for S-Boot-injected `el2_code`, `el2_earlymem`, `kaslr` and bootargs-only carveouts; Linux 5.1 must reserve each required range exactly once.
- The live FDT proves the composed SOVR 4.2 + stock DTBO entry 5 + S-Boot result on one SM-A505F 4-GB device only. 6-GB and other regional/model variants remain unverified until corresponding live evidence is supplied.
- Never commit raw live DTB data or serial/IMEI-class identifiers.
- Donor Linux 5.15 sources are comparative references only; adapt source/API/Kconfig dependencies to Linux 5.1 individually.

## Done / committed in this continuation

- Re-read the complete `A50_HANDOFF_FOR_CHATGPT.md`, including evidence provenance, boot image, stock DT table, stock DTBO table, live memory map, S-Boot changes, correction list and next tasks.
- Rechecked the active Linux 5.1 branch's actual `exynos9610.dts`, local include files, Exynos DT Makefile, upstream pinctrl implementation and Samsung clock Kconfig/Makefile.
- Corrected the previous stale state note: the current branch DOES contain `arch/arm64/boot/dts/exynos/exynos9610.dts`, its seven immediate local DTS includes and an `exynos9610.dtb` target. It also has prior DTB smoke workflow/assertions. This is not proof of a full board integration.
- Confirmed the current DTS retains the three static SOVR memory nodes and empty chosen bootargs/initrd placeholders.
- Updated `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md` with Phase 21, reconciling old contradictory memory guidance and making the handoff the authoritative contract.
- Plan update commit: `dd1a57412eeaaf86d82ec9dbcc9322185ebefbb0`.

## Current implementation status

- Upstream ARM64 Linux 5.1 baseline: previously CI-verified green.
- Exynos9610 SoC DTS and DTB build target: present; latest CI assertion result must be checked before claiming current pass.
- Samsung stock DTBO composition: documented from supplied blobs; production stock DTBO remains external/untouched.
- Exynos9610 pinctrl: not complete. Phase 20 EINT filter offset inconsistency remains unresolved; do not enable all six controller groups until register calculations and suspend/wake paths are validated.
- Exynos9610 clock provider: not complete. Phase 18 dependency audit remains current; CAL/CMUCAL/provider helper closure needs a symbol/object manifest and isolated 5.1 port.
- ACPM IPC/DVFS: not ready; keep disabled until firmware ABI, shared memory, timeout and error paths are verified.
- UFS host + Samsung UFS PHY: absent from target 5.1 Kconfig/Kbuild as of the last audit; port together as one dependency set.
- SysMMU, thermal, regulators, Mali, SCSC, TZDEV/TEEGRIS and remaining vendor peripherals: require per-subsystem compatibility and dependency audits.
- A50-specific defconfig: exact current path/content still needs a fresh audit.
- Full integrated A50 kernel compile: not yet verified.
- Flashable package: not yet verified.
- Hardware boot: not tested; no bootability claim.

## Failed / blocked

1. No current evidence proves the S-Boot memory rewrite works for every 6-GB or non-F SKU; keep those as goals, not claims.
2. Pinctrl EINT filter offset inconsistency blocks safe runtime enablement.
3. Clock/CAL/CMUCAL dependency closure and error handling are not yet ported.
4. ACPM firmware ABI and UFS host/PHY dependencies are not yet integrated.
5. A DTB smoke build alone cannot validate driver binding or kernel boot.

## Next step — resume here

1. Inspect latest GitHub Actions run on this branch and its exact job logs/artifacts; verify the Exynos9610 DTB assertions.
2. Continue the pinctrl EINT register-offset investigation against matching Exynos9610 hardware/vendor sources; only then implement the consistent 5.1 adaptation.
3. Build a source/symbol/object manifest for the exact Exynos9610 clock + CAL/CMUCAL donor revision, then port the smallest compile-only closure under dedicated disabled-by-default Kconfig symbols.
4. Keep ACPM disabled until its ABI and failure handling are proven.
5. Port UFS host and PHY as a coherent set; compile after each isolated subsystem.
6. Only after driver dependencies and a target defconfig are complete, run a full Linux 5.1 A50 Image + DTB build and inspect artifacts. Do not create a flashable ZIP until packaging matches the stock A50 boot/DTB partition contract.

**No claim of a full kernel build, flashable package, or device boot is made by this state update.**


## Follow-up pinctrl source trace — 2026-11-20

- Deepened Phase 20 against exact donor data/runtime code and recorded Phase 22 in the integration plan.
- Confirmed the donor Exynos9610 EINTG macros provide distinct `fltcon_offset` values (e.g. DISPAUD gpb1: eint 0x04/filter 0x08; FSYS gpf2: 0x08/0x0C; TOP entries include non-linear filter offsets).
- Confirmed donor `samsung_pin_bank_data` contains `fltcon_offset`, but runtime `samsung_pin_bank` does not; `samsung_pinctrl.c` copies `eint_offset` only; `exynos_pinctrl.c` suspend/resume computes EFLTCON using `2 * eint_offset`. Thus the donor table's distinct filter offsets are not used by the runtime code and cannot be treated as validated hardware truth.
- No safe register-map source has yet resolved the correct EFLTCON addresses. Pinctrl implementation remains blocked; no code was copied or enabled.
- Updated integration plan Phase 22; commit: `3ce073923f62d565b51e9e5b59f4e329f5158bf1`.

## Next
- Continue the Exynos9610 CAL/CMUCAL/clock source-symbol manifest in parallel with the unresolved pinctrl register-map work.
- Do not create a guessed pinctrl fix or enable the controller nodes until register addresses are independently verified.
- Check latest Actions results separately; no new compile, DTB build, full kernel build, ZIP package, or hardware boot was run during this source audit.


## Follow-up CAL/CMUCAL dependency trace — 2026-11-20

- Started Phase 23 in the integration plan using exact donor blobs from `Vothcito/android_kernel_samsung_exynos9610_a50:exynos9610-port`.
- Clock driver direct dependency set includes CAL init/rate calls, Samsung composite clock extensions, and Exynos9610 CMUCAL VCLK/node/QCH/clockout headers.
- Found a concrete donor API/configuration inconsistency: normal `cal-if.h` declares `cal_if_init(void *)`, while the `CONFIG_PWRCAL` inline stub declares `cal_if_init(void)`; the Exynos9610 clock driver calls `cal_if_init(np)`. The no-op stub is not a valid substitute for initialized CAL. Resolve before compile/enablement.
- Donor CAL implementation pulls in CMUCAL, PMUCAL, ACPM_DVFS, FVMAP, ASV and ECT interfaces; porting only `clk-exynos9610.c` would be incomplete. No source copied or compiled.
- Integration plan Phase 23 commit: `eae2b78280056574cd45af5462568544212f6a3d`.

## Next
- Continue exact symbol-to-object mapping for CMUCAL, VCLK/QCH tables and CAL data; identify the minimum Linux 5.1 compile closure without accidentally enabling ACPM or unsupported power paths.
- Keep pinctrl blocked on the verified EFLTCON register map. Keep clock provider disabled until CAL interface/API and failure handling are corrected.


## Follow-up clock-port boundary audit — 2026-11-20

- Recorded Phase 24 in `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md`; commit `372aa9cd22141589d5db252d83892ddbce28f798`.
- Rechecked current target Linux 5.1 Samsung clock and SoC Kconfig/Makefiles: there is no Exynos9610 provider or Samsung CAL framework; the generic `EXYNOS_ARM64_COMMON_CLK` symbol is too broad for importing the vendor provider.
- Donor `composite.c` supplies live VCLK CCF callbacks that call CAL APIs, so it is runtime-coupled, not a compile-only harmless extension.
- Donor Exynos9610 `cal_data.c` textually includes CMUCAL node/QCH/SFR/VCLK/LUT and clockout implementation C files and also references broad PMUCAL/ACPM/ASV headers. Do not blindly compile this monolithic unit or enable the donor's generic ARM64 clock symbol.
- Donor CAL init invokes ECT parsing, VCLK init, PMUCAL RAE/system/local/CPU init, and ACPM setup. The subsystem requires an explicit dependency boundary and real failure propagation.
- No kernel source/Kconfig/Makefile change or compile was made; this remains a source-level design audit.

## Next
- Define the minimal mandatory CAL/CMUCAL/VCLK symbol closure and split out any safe static ID/data-only parts from PMUCAL/ACPM runtime code.
- Implement a dedicated disabled-by-default Exynos9610 Samsung clock option only after the source closure is verified; do not select via generic ARM64 clock support.
- Keep pinctrl blocked on EFLTCON register proof. Keep full board clock consumers disabled until provider init and error paths are valid.
