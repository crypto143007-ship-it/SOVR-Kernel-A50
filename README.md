<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/sovr_kernel_dark.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/sovr_kernel_light.png">
    <img alt="SOVR Kernel" src="assets/sovr_kernel_light.png" width="100%">
  </picture>
</p>

<p align="center">
  <a href="https://github.com/openela/kernel-lts"><img src="https://img.shields.io/badge/Linux-4.14.357--openela_+_ELTS-1f2328.svg?logo=linux" alt="Linux Kernel"></a>
  <a href="https://github.com/SOVR-Technologies/SOVR-Kernel-A50/releases/tag/v4.1"><img src="https://img.shields.io/badge/Release-SOVR_v4.1_Final-0969da.svg?logo=github" alt="Release"></a>
  <a href="https://semiconductor.samsung.com"><img src="https://img.shields.io/badge/SoC-Exynos_9610-1f2328.svg" alt="Target SoC"></a>
  <a href="https://github.com/Neutron-Toolchains/clang-build-catalogue"><img src="https://img.shields.io/badge/Compiler-Neutron_Clang_24.0.0git_(LLVM_24)-1f2328.svg" alt="Compiler"></a>
  <a href="https://github.com/KernelSU-Next/KernelSU-Next"><img src="https://img.shields.io/badge/Root-KernelSU--Next_v3.4.2-1f2328.svg" alt="Root"></a>
  <a href="https://gitlab.com/simonpunk/susfs4ksu"><img src="https://img.shields.io/badge/Security-SuSFS_v1.5.5-1f2328.svg" alt="SuSFS"></a>
  <a href="https://docs.kernel.org/admin-guide/mm/multigen_lru.html"><img src="https://img.shields.io/badge/MM-Multi--Gen_LRU-1f2328.svg" alt="MGLRU"></a>
  <img src="https://img.shields.io/badge/ZRAM-LZ4_default%2C_ZSTD_available-1f2328.svg" alt="ZRAM">
  <img src="https://img.shields.io/badge/TCP-Google_BBR-1f2328.svg" alt="TCP BBR">
  <img src="https://img.shields.io/badge/VINTF-FCM_Compliant_(0_errors)-0969da.svg" alt="VINTF">
</p>

---

## Overview

**SOVR Kernel** is a high-performance, security-hardened Linux kernel engineered for the **Samsung Galaxy A50** (`SM-A505F/FN/G/N`, Exynos 9610).

Built upon **OpenELA Enterprise Linux LTS (4.14.357)** augmented with rolling **Enterprise LTS (ELTS)** backports synchronized through upstream Linux 4.19.324, SOVR v4.1 unlocks the full silicon potential of the SoC. Compiled with the cutting-edge **Neutron Clang 24.0.0git (LLVM 24)** toolchain with ThinLTO, LLD safe ICF, and custom `-O3` pipeline vectorization, it integrates kernel-level stealth via **SuSFS v1.5.5**, in-tree **KernelSU-Next v3.4.2**, backported **EROFS**, **Multi-Gen LRU (MGLRU)**, and low-latency networking.

Starting with **v4.1 Final**, SOVR introduces **Dynamic Universal AnyKernel3 Installers** providing seamless, automated platform detection across **Samsung One UI 3.1 (Android 11)**, **One UI 4/5 (Android 12/13)**, **One UI 6+ (Android 14 / Fresh 6)**, and **Generic System Images (AOSP Android 12+)**.

Feature descriptions below reflect the v4.0 project baseline unless explicitly marked as v4.1 development findings. Configuration alone does not establish runtime availability, performance, or ROM compatibility.

---

## Architectural Highlights

### ⚡ Silicon Unlock & Hardware Offloading
* **ARMv8 Hardware Cryptography:** The A50 core defconfig enables ARM64 AES/CE, GHASH/PMULL, SHA1/SHA2 CE, CRC32 CE, and ChaCha20 NEON implementations. Runtime driver selection and throughput still require on-device validation.
* **SCSC Wi-Fi Acceleration:** Enables NAPI ring-buffer polling, Generic Receive Offload (GRO), and Low Latency mode on the SCSC Wi-Fi subsystem, minimizing CPU interrupt overhead during high-speed transfers.
* **LPDDR4x & System Bus QoS Boost:** Enforces 1.35 GHz on the LPDDR4x Memory Interface (MIF) and 667 MHz on the Internal Bus (INT) during boot and intensive workload phases.
* **ARM64 Compiler Targeting:** Architecture flags are defined in both the ARM64 and top-level Makefiles, including A73 and A53 tuning. The final compiler command line and instruction compatibility across both clusters must be verified from a build before making performance claims.

### 📁 File Systems & Storage Architecture
* **Native EROFS Backport:** In-kernel Enhanced Read-Only File System with ARMv8 NEON assembly decompression (`lz4armv8.S`), SELinux xattrs, and POSIX ACL support for modern Android 13/14 system images.
* **F2FS Modernization:** Rapid Garbage Collection, enhanced checkpointing, and reduced write amplification for flash endurance.
* **Dynamic Fsync 2.0:** Suspends synchronous storage flushes while the screen is active, flushing deferred writes when the display sleeps.
* **Anxiety & Kyber I/O Elevators:** Low-latency storage schedulers tuned for UFS 2.1 flash memory.
* **Native OverlayFS:** In-tree support for systemless overlays and module mounts.

### 🛡️ Kernel-Level Stealth & Enterprise Security
* **SuSFS v1.5.5 Subsystem:** Kernel VFS stealth layer resolving modern detection vectors (including Native Detector Mount Gap 43 and Momo).
* **Knox RKP Compatibility:** Adapted mount traversal for Samsung Real-time Kernel Protection (`CONFIG_RKP_NS_PROT`), preventing kernel panics.
* **Per-UID SAR Partition Protection:** Preserves physical mount points (`/vendor`, `/system`, `/product`) during per-UID unmount routines, ensuring graphics HAL stability.
* **SELinux Enforcing Mode & Auto-Permissive for GSIs:** Fully compliant with Android Enforcing policies on One UI while offering automated permissive fallback (`CONFIG_ALWAYS_PERMIT=y`) on AOSP GSI builds.
* **KernelSU-Next v3.4.2:** In-tree manual hooks (`CONFIG_KSU_MANUAL_HOOK=y`) supporting UAPI v5, native module blacklists, and ADB-only shell root.

### 🧠 Memory Management & Interactive Responsiveness
* **Multi-Gen LRU (MGLRU):** Backported 12-patch series replacing the legacy 2-list LRU algorithm. Employs multi-generational page tracking to cut memory thrashing and background app redraws.
* **ZRAM:** LZ4 is the default compressor; Zstandard (ZSTD) remains enabled as an alternative. Compression ratios, latency, CPU overhead, and battery impact have not yet been benchmarked on an A50.
* **Touch Event Frequency Boosting:** In-kernel touch floor setting 1.53 GHz (A73) and 1.14 GHz (A53) for 130 ms upon touch interactions for instant UI response.
* **Accelerated Energy Adaptive Governor:** 100 µs (BIG) and 250 µs (LITTLE) ramp-up limits with 2000 µs down-scaling for smooth 60 FPS delivery.
* **In-Kernel Boot Booster:** Locks clusters and raises block readahead to 2048 KB during early boot until `sys.boot_completed=1`.

### 🌐 Connectivity & Networking
* **Google BBR:** Default TCP congestion control algorithm prioritizing bottleneck bandwidth and minimal latency.
* **Bufferbloat Mitigation:** CAKE and FQ_CODEL are configured. FQ-PIE is not present in the current branch's scheduler Kconfig/Makefile and is not advertised as available.
* **Multi-Ecosystem Adaptation:** Dual-interface SCSC networking for One UI and upstream `wlan1` routing for pure AOSP.

### 🔧 Exynos 9610 Platform Fixes & VINTF Compliance
* **Exynos 9610 stability fixes:** Upstream fixes bound suspend-time CPU-frequency retries, remove CPU0 affinity from the simpleinteractive devfreq worker, and prevent cpuidle state-name truncation.
* **TrustZone initialization:** TZDEV startup archive deployment is asynchronous; this change requires device validation for boot and secure-storage behavior.
* **VINTF-related settings:** Upstream enables the audit, scheduler-debug, and RTL8152 configuration symbols. A clean `checkvintf` result has not been independently reproduced on device.
* **BPF compatibility:** Upstream changes the fake BPF-reported uname to 5.4.186 for newer Android userspace; compatibility remains ROM-dependent.

---

## Technical Specifications

| Parameter | Specification |
| :--- | :--- |
| **Linux Baseline** | 4.14.357-openela (LTS) + ELTS Rolling Backports (sync v4.19.324) |
| **Target Device** | Samsung Galaxy A50 (`SM-A505F`, `SM-A505FN`, `SM-A505G`, `SM-A505N`) |
| **SoC Architecture** | Samsung Exynos 9610 (10nm FinFET) |
| **CPU Configuration** | 4x Cortex-A73 @ 2.3 GHz + 4x Cortex-A53 @ 1.7 GHz (ARMv8.0-A) |
| **GPU** | ARM Mali-G72 MP3; build fragments select Bifrost R32P1 (Android 12) or R38P1 (Android 14), not yet device-validated |
| **Toolchain** | Google AOSP Clang 17.0.2 (`clang-r487747c`) + LLD 17.0.2, pinned to prebuilts commit `fd582b924a400906979f54121c05555b453d5c35` |
| **Optimization Target** | ARM64 crypto/CRC/SHA2 flags and heterogeneous A73/A53 tuning; effective build flags require log verification |
| **Kernel Preemption** | `CONFIG_PREEMPT=y` |
| **Root Subsystem** | KernelSU-Next v3.4.2 (UAPI v5, Code 33355) |
| **VFS Hiding** | SuSFS v1.5.5 non-GKI |
| **SELinux Mode** | One UI configuration selects always-enforce; AOSP configuration selects always-permit. Runtime mode has not been verified on-device. |

---

## Ecosystem Variants & Downloads

Releases are available under [GitHub Releases](https://github.com/SOVR-Technologies/SOVR-Kernel-A50/releases):

### Universal Installers (v4.1 Final)
* **`SOVR-Kernel-v4.1.OneUI_Universal_A50_KSU.zip`**
  * Automatically detects and injects the verified kernel and DTB for:
    * **One UI 6.x** (Android 14 / Fresh 6)
    * **One UI 4.x & 5.x** (Android 12/13 / Fresh 4/5)
    * **One UI 3.1** (Android 11 / Stock Samsung)
* **`SOVR-Kernel-v4.1.AOSP_Universal_A50_KSU.zip`**
  * Tailored for **Generic System Images (GSIs)** and AOSP Android 12+ (LineageOS, Pixel Experience, CrDroid) with legacy DTB, dual MAC fallback, and BPF 5.4.186 compatibility.

### Development package matrix

The **SOVR Galaxy A50 Package Matrix** workflow produces separate `Simple`, `Magisk`, and `KernelSU` ZIPs for each profile. Workflow artifacts are build outputs, not GitHub Releases. A manual run can select one ROM profile, one root integration, or the full matrix.

| ZIP profile prefix | Android platform | Build profile | Status |
| --- | ---: | --- | --- |
| `OneUI4` | 12 | One UI / Android 12 fragments | Experimental; build/package validation only |
| `OneUI5` | 13 | One UI / Android 13 fragments | Experimental; build/package validation only |
| `OneUI6` | 14 | One UI / Android 14 DTB and fragments | Experimental; build/package validation only |
| `OneUI7` | 15 | Android 14 Mali and partial-deknox fragments/DTB fallback | Experimental; no Android 15-specific kernel fragments |
| `OneUI8` | 16 | Android 14 Mali and partial-deknox fragments/DTB fallback | Experimental; no Android 16-specific kernel fragments |
| `OneUI8.5` | 16 | Android 14 Mali and partial-deknox fragments/DTB fallback | Experimental; no Android 16-specific kernel fragments |
| `AOSP` | 14 | Android 14 AOSP DTB and fragments | Experimental; build/package validation only |

Each prefix has `-Simple.zip`, `-Magisk.zip`, and `-KernelSU.zip` variants. `Simple` disables both root integrations, `Magisk` uses the in-tree Magisk pre-root path, and `KernelSU` enables the in-tree KernelSU/SuSFS configuration. Android 15/16 builds reuse Android 14 configuration fragments and must not be interpreted as ROM compatibility claims. No matrix artifact is considered device-boot tested unless separately reported.

---

## Installation

### Prerequisites
* Unlocked bootloader on Samsung Galaxy A50 (`SM-A505F/FN/G/N`).
* Custom recovery installed (**TWRP** or **OrangeFox**).

### Flashing Procedure
1. Download the Universal AnyKernel3 ZIP matching your ecosystem (`OneUI_Universal` or `AOSP_Universal`) from [GitHub Releases](https://github.com/SOVR-Technologies/SOVR-Kernel-A50/releases).
2. Transfer the ZIP to device storage, MicroSD card, or USB OTG drive.
3. Reboot into **Recovery mode**.
4. In recovery, select **Install**, choose the SOVR Kernel ZIP, and swipe to flash. AnyKernel3 will automatically identify your installed OS and flash the correct kernel and device tree.
5. (Recommended) Wipe Dalvik / ART Cache.
6. Reboot to **System**.
7. Install the latest **KernelSU-Next Manager APK** to configure root permissions and SuSFS modules.

---

## Building from Source

### Build Environment
* Host OS: Ubuntu 22.04 LTS (Native or WSL2)
* Compiler: Google AOSP Clang 17.0.2 (`clang-r487747c`)
* Linker: LLVM LLD 17.0.2
* CI obtains the compiler from the official Android prebuilts repository at commit `fd582b924a400906979f54121c05555b453d5c35`.

### Compilation Commands

```bash
# Clone the repository
git clone https://github.com/SOVR-Technologies/SOVR-Kernel-A50.git
cd SOVR-Kernel-A50

# Compile for Samsung One UI 6+ (Android 14) with KernelSU-Next
./build.sh -d a50 -a 14 -v oneui -k --toolchain aosp_17

# Compile for Samsung One UI 4 (Android 12) with KernelSU-Next
./build.sh -d a50 -a 12 -v oneui -k --toolchain aosp_17

# Compile for Samsung One UI 3 (Android 11) with KernelSU-Next
./build.sh -d a50 -a 11 -v oneui -k --toolchain aosp_17

# Compile for Generic System Images (AOSP)
./build.sh -d a50 -a 12 -v aosp -k
```

---

## Credits & Upstream Attribution

* **Linux Kernel Community & OpenELA:** For extended enterprise maintenance of the Linux 4.14 kernel branch.
* **Neutron Toolchains Team (Dakkshesh):** For the cutting-edge Neutron Clang LLVM compiler suite.
* **Samsung Open Source Release Center (OSRC):** For base hardware source code and platform definitions.
* **The Fresh Project (TenSeventy7 & PeterKnecht93):** For Exynos 9610 platform research and ROM ecosystem support.
* **KernelSU Team (tiann) & KernelSU-Next (rifsxd):** For kernel-assisted superuser infrastructure.
* **SuSFS Project (simonpunk):** For advanced kernel VFS stealth implementation.
* **EROFS Community (Gao Xiang):** For the Enhanced Read-Only File System.
* **cat658011 & Tim Zimmermann:** For valuable Exynos 9610 platform fixes and BPF compatibility backports.

---

## License

This project is licensed under the **GNU General Public License v2.0 (GPL-2.0)**. See [COPYING](COPYING) for full details.
