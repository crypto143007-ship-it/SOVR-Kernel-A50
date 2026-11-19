# SOVR-Kernel-A50 Development State

**Project baseline:** SOVR v4.2 / Linux 4.14.357 / Samsung Galaxy A50 (SM-A505F, Exynos 9610)  
**Branch:** `main`  
**State audited against HEAD:** `e29aabf8c86261830a0d93be6723007892230731`

## Done / Committed
- Re-read this state file, the latest commits, `build.sh`, `README.md`, `Documentation/device-db/a50.sh`, and both GitHub Actions workflows.
- Confirmed current HEAD is `e29aabf8c86261830a0d93be6723007892230731`; the prior state-file HEAD reference was stale.
- Confirmed the two workflows are `.github/workflows/development.yml` and `.github/workflows/galaxy-a50.yml`.
- Confirmed `build.sh` implements `--ksu` and SOVR v4.2 KSU naming, but neither workflow invokes `--ksu`.
- Confirmed no open pull requests and no reported commit status checks on the audited HEAD.
- No kernel source, device-tree, defconfig, or workflow changes made during this audit.

## Failed / Do Not Repeat
- Do not restore `EXYNOS9610_LINUX_51_INTEGRATION_PLAN.md` to `main`; commit `9811fd3` explicitly reverted its accidental addition.
- Do not treat SOVR 4.0 as current; the baseline is SOVR 4.2.
- Do not modify the original `SOVR-Technologies/SOVR-Kernel-A50`; work only in this fork.
- Do not assume the caller workflow's `set -eo pipefail` protects pipelines executed inside the child `build.sh` process.

## Active Bug / Current Focus
- **Toolchain provisioning mismatch — `build.sh:45-46,79-87,118-151`:** the default compiler selector is `neutron`; its verification path requires `$HOME/toolchains/neutron-clang`. The GitLab clone fallback targets repository-local `toolchain/`, but the Neutron verification branch does not use that location. Neither workflow provisions the expected home-directory toolchain.
- **Build failure propagation — `build.sh:267-282,701-702`:** make/clean pipelines are piped through `sed` without script-local `pipefail` or explicit status checks. The workflow's shell options do not automatically govern the separately executed script.
- **CI target mismatch — `.github/workflows/development.yml` and `.github/workflows/galaxy-a50.yml`:** current jobs cover Android 11/12 legacy targets, do not include Android 14, and use `--magisk`/non-root rather than the documented KSU release path. `build.sh:552-554` exposes `--ksu`.
- **Image metadata needs audit — `Documentation/device-db/a50.sh` and `build.sh:300-340,648-660`:** device metadata declares Android `12.0.0`; verify how Android 14 package builds set boot-image OS version and patch metadata before changing it.
- Linux 5.1 migration remains unimplemented and unvalidated. Preserve the Linux 4.14.357 bootable baseline.

## Next Step
- Make a minimal, testable build-script correction for compiler provisioning and make-command failure propagation. First verify the intended Neutron/LLVM 23.1.5 source and expected directory layout; do not silently switch compiler versions. Then add a dedicated Android 14 KSU CI job and validate artifact names, boot image, DTB/DTBO, and final ZIP before expanding the matrix. Continue the DTS/TZDEV/TEEGRIS compatibility audit only after build reproducibility is established.
