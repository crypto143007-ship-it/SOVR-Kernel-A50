# SOVR v4.1 Mint Backport Report

Mint A50 release notes and the referenced tag commits for beta-1402 through beta-1413 were inspected. Only the EROFS-aware installer guard was adapted; the remaining changes below were either already present or deferred pending source, licensing, or hardware validation.

| Mint release / commit | Commit-level change | SOVR comparison | Decision |
|---|---|---|---|
| beta-1413 / `7f72a8b` | Adds `ATTR_CTIME` when OverlayFS restores copied-up timestamps. | SOVR's `fs/overlayfs/copy_up.c` already has the same flag. | No change needed. |
| beta-1412 / `7858178` | Changes Android 12 Mali from R32P1 to R38P1 and merges Android 12/13 config fragments. The commit itself does not contain a per-CPU EROFS implementation change. | SOVR selects R32P1 for Android 12 and R38P1 for Android 14; the checked EROFS source/config search found no per-CPU decompression option. | Do not change DDK or claim per-CPU EROFS support without compile and device evidence. |
| beta-1411 / `9e2feca` | Enables OverlayFS in the A50 core defconfig. | SOVR already configures OverlayFS. | No change needed. |
| beta-1410 / `d319518` | Adds fallback to an older TZAR firmware blob when the new one fails to load. | SOVR includes the current TZAR blobs but not `startup_old.tzar`; the proprietary firmware dependency and secure-world compatibility are unverified. | Deferred; do not copy the binary blindly. |
| beta-1409 / `6b7afd0` | Checks Android version against `mint.prop` and adds vendor build-property lookup. | SOVR's installer already checks `mint.prop` and includes system/vendor property fallbacks. | No change needed from this commit. |
| beta-1408 / `7e6b69c` | Updates the KernelSU submodule to a legacy KernelSU commit. | SOVR documents and integrates KernelSU-Next instead. | Not a compatible direct backport. |
| beta-1406 / `53e8739` | Disables `CONFIG_PM_AUTOSLEEP` and enables `CONFIG_XFRM_INTERFACE`. | Both settings already match in SOVR's A50 core and default defconfigs. | No change needed. |
| beta-1404 / `311ef88` | Skips the AOSP native ZRAM writeback setup when the vendor partition is EROFS. | SOVR previously enabled this package integration for every AOSP install. | Added a filesystem check; skip on EROFS or when the filesystem cannot be identified. |
| beta-1403 / beta-1402 / `77b7859` | Enables EROFS in the A50 core defconfig; both release tags resolve to this commit. | SOVR already configures EROFS with ARMv8 accelerated LZ4. | No change needed. |

Release notes for beta-1410 mention F2FS and newer bootloaders, while the tag's referenced commit changes TZAR fallback. Those release-level features may be present in other commits in the tag's history and still need separate history/diff review. The installer change here has not been recovery-tested.
