# SOVR v4.1 Android Compatibility

Compatibility status below is based on repository configuration and documentation only. No ROM/vendor images or physical Galaxy A50 were available for boot or hardware testing.

| Target | Repository evidence | Status |
|---|---|---|
| One UI 6.1.1 | Existing documentation describes One UI 6+/Android 14; the build script has Android 14-specific DTB and Mali fragments. | Source-profile support exists; exact 6.1.1 vendor/boot image and hardware behavior are unverified. |
| One UI 7 | No target-specific ROM/vendor baseline or tested profile was found in the inspected build flow. | Unsupported claim; do not advertise compatibility yet. |
| One UI 8 | No target-specific ROM/vendor baseline or tested profile was found in the inspected build flow. | Unsupported claim; do not advertise compatibility yet. |
| AOSP/GSI | Existing build flow has an AOSP variant and separate config fragment. | Source profile exists; specific GSI/vendor combinations are unverified. |

The repository's current build script supports A50 One UI, AOSP, and recovery variants and adjusts the Android version through configuration fragments. A kernel version string or successful compile alone cannot establish modern One UI compatibility. Verification requires the exact boot/vendor/DTB/DTBO baseline and device tests for boot, SELinux, Binder, display, camera, audio, Wi-Fi, Bluetooth, modem, encryption, storage, and recovery.
