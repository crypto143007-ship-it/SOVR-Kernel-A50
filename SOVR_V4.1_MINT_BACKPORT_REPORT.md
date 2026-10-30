# SOVR v4.1 Mint Backport Report

Mint A50 release notes for beta-1402 through beta-1413 were inspected. Release-note review is not equivalent to reviewing each tagged commit's patch; no Mint patch has been copied in this development snapshot.

| Mint release | Release-note item | SOVR source observation | Decision |
|---|---|---|---|
| beta-1413 | Latest ACK OverlayFS changes | OverlayFS is configured; exact ACK patch delta not compared. | No patch ported pending commit-level review. |
| beta-1412 | Per-CPU EROFS threads; Mali R38P1 on Android 12 | EROFS accelerated LZ4 is configured. Mali fragments select R32P1 for Android 12 and R38P1 for Android 14. Per-CPU EROFS implementation and Android 12 R38P1 dependencies remain to compare. | No driver/DDK change without build and ROM validation. |
| beta-1411 | OverlayFS support | OverlayFS is already configured in SOVR. | Existing feature retained; source patch delta not compared. |
| beta-1410 | F2FS `/data`; newer bootloaders | F2FS is configured. Bootloader compatibility change not inspected at commit level. | No installer or bootloader change. |
| beta-1409 | Bootloader/warranty property spoofer; Android-version installer checks | Corresponding installer/device scripts were not audited in this pass. | No patch ported. |
| beta-1408 | KernelSU update | SOVR documents KernelSU-Next; exact version/patch compatibility not compared. | No KernelSU update. |
| beta-1406 | Framework compatibility | Exact patch and target framework requirements not compared. | No patch ported. |
| beta-1404 | Disable ZRAM patches on EROFS | SOVR config enables both ZRAM and EROFS; code-level interaction was not audited. | No ZRAM/EROFS patch changed beyond the compressor default. |
| beta-1403 | Recovery install, Magisk ramdisk, legacy KernelSU, EROFS partitions, charging bypass | SOVR has EROFS, KernelSU-Next, and packaging code; equivalent commit-level behavior and charging-bypass hardware requirements were not verified. | No recovery, root, or charging patch ported. |
| beta-1402 | Initial EROFS support | EROFS is configured with ARMv8 accelerated LZ4. | Existing support retained; source history not compared. |

Before any backport, compare the tagged commit's full diff and dependencies against SOVR's actual implementation, then build each affected profile. Release-note text alone is insufficient evidence.
