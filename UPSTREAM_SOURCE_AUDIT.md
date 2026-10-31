# Upstream source audit

## Snapshot

The fork's merged `main` (`09d2b9ef0b91f5e30e0ea45da7b4bfb1d8dd137c`) was merged with upstream `main` at `195b69f9b4e71f7e9ce409feb47aca253021a68e`. The resulting local merge is `f13e8e0`. The upstream-only comparison contains 247 commits and changes 248 files (+6,175/-1,222 lines).

## Findings and integration decisions

| Area | Upstream change | Decision / caveat |
| --- | --- | --- |
| Exynos 9610 | Fixes for cpufreq suspend retries and QoS leakage, cpuidle state-name truncation, and devfreq CPU affinity | Retained; these are targeted platform correctness fixes. Device testing is still required. |
| Device trees | Adds Android 14 AOSP and One UI EROFS-oriented Exynos9610 DTS variants | Retained for Android 14+ builds. This is not evidence that newer Android releases boot on an A50. |
| Scheduler / responsiveness | Changes scheduler migration cost, energy-adaptive governor limits, iowait boosting, and the EMS utilization margin | Retained as upstream tuning; no frame-time, power, or thermal measurements are available. |
| Storage and networking | Enables WBT and RTL8152; changes BBR-related settings and package-side MAC handling | Retained. UFS, microSD host support, F2FS, EROFS, CAKE, and FQ_CODEL remain configured. |
| Optional features | Disables KSM and removes CFQ/FIOPS/SIO/ZEN and several USB-network defaults from the A50 defconfigs | Re-enabled in the core/default defconfigs where the corresponding Kconfig entries remain in this source tree. Anxiety remains the default scheduler; optional drivers do not imply device validation. |
| Android / Treble integration | Adds installer/VFS bootstrap changes, AOSP policy cleanup, and asynchronous TZDEV startup archive deployment | Retained. TZDEV timing, secure-storage behavior, installer behavior, and ROM compatibility require on-device checks. |
| Build tooling | Changes the script default from pinned AOSP Clang 17 to Neutron Clang; changes the base defconfig used by the build script | CI now explicitly passes `--toolchain aosp_17` so the pinned Google compiler is the compiler actually selected. The source's default remains upstream's Neutron setting for non-matrix callers. |
| Claims and scope | Introduces performance and compatibility claims in comments/docs | README and package metadata distinguish configuration/build evidence from measured performance or physical-device support. FQ-PIE is not present and is not claimed. |

The review focused on the 247-commit range's A50 defconfigs, build script, Exynos DTS/platform changes, scheduler tuning, AnyKernel installer, root integration, and CI surfaces. It is an integration audit, not a line-by-line security review of every unrelated driver change.

## Preserved baseline

The A50 core defconfig still selects LZ4 as ZRAM's default while compiling ZSTD support, MGLRU, BBR, CAKE/FQ_CODEL, UFS, F2FS, EROFS, and ARM64 crypto implementations. The restored optional scheduler and USB-network selections are recorded in [FEATURE_PRESERVATION_MATRIX.md](FEATURE_PRESERVATION_MATRIX.md).

## Verification boundary

The merge parent relationship is verified locally. Full kernel compilation, final `.config` generation, installer execution, and physical-device boot tests must be reported separately; source inspection alone cannot establish them.
