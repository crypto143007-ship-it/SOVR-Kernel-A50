# Reproducible Linux 5.1 upstream baseline

## Pinned upstream source

- Repository: `https://github.com/torvalds/linux`
- Release tag: `v5.1`
- Annotated tag object: `b0854f56c54832584b1173b997fa665328b50afd`
- Dereferenced commit: `e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd`
- Tagger timestamp: 2019-05-06T00:43:10Z
- Tag message: `Linux 5.1`

The workflow checks out the immutable commit SHA, not a moving branch or tag name.

## Added GitHub Actions workflow

`.github/workflows/linux-51-upstream-baseline.yml`

- Trigger: manual `workflow_dispatch` only.
- Permissions: `contents: read`.
- Runner: Ubuntu 22.04.
- Cross toolchain: distro AArch64 GCC 10.
- Configuration: upstream `arm64 defconfig`.
- Build targets: upstream `Image` and all ARM64 `dtbs`.
- Evidence artifact: source identity, generated config, Image and DTBs where generated.
- Artifact retention: 14 days.
- No release creation, package signing, repository writes, device flashing, secrets, or deployment.

## Interpretation

This is strictly a **vanilla upstream ARM64 baseline build**. It does not build the SOVR vendor tree, does not include Exynos9610 support, and does not prove the Galaxy A50 can boot Linux 5.1. Its purpose is to verify that the pinned upstream source and selected cross-compiler can produce a baseline ARM64 kernel before any vendor code is ported.

The workflow is manual and has not been dispatched by this session. No build result is claimed. The existing A50 workflows were inspected but not run because they build the current vendor kernel/package variants, not the requested Linux 5.1 migration.

## Next step after baseline succeeds

Create a separate integration workspace or branch based on the pinned upstream commit, then apply one minimal platform patch series at a time. Keep the baseline workflow immutable and add a second, clearly named vendor-integration workflow only when the first Exynos9610 patch series exists. Do not publish or flash a boot image until DTB/DTBO, TZDEV, UFS, display, touch, connectivity, suspend/resume and recovery acceptance gates are met.


## Session update — 2026-11-18: baseline build automation

The manual-only baseline workflow now also has a narrowly scoped push trigger for updates to:
- `.github/workflows/linux-51-upstream-baseline.yml`
- `LINUX_51_BASELINE.md`

It remains restricted to branch `migration/linux-5.1-assessment`, and still builds only the immutable upstream Linux v5.1 commit `e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd` using ARM64 defconfig, then `Image dtbs`. Permissions remain `contents: read`; no release, package, signing, deployment, or device-flash steps were added.

Workflow-trigger change commit: `e88e6ab3f96ed52331ffc271dc2337ea00cef81d`.

### Execution status

The workflow definition was fetched again after the change and its trigger block was verified. The connected GitHub Actions tool surface available in this session does not expose workflow-dispatch or a general list-runs operation. The commit's combined status currently returns no status entries. Therefore a run is **not yet confirmed**, and no successful compile is claimed. Check the repository's Actions tab for the run named **Linux 5.1 Upstream ARM64 Baseline**.

### Critical scope distinction

The migration branch's kernel top-level Makefile still declares Linux 4.14.357. The upstream v5.1 build job checks out a separate Torvalds Linux tree and does not compile SOVR's modified ACPM source or any Exynos9610 vendor code. It is only a compiler/upstream-baseline check. A separate vendor integration tree based on the pinned v5.1 commit is still required before an A50 kernel build can be attempted.


## Verified CI failure diagnosis — 2026-11-18

Two push-triggered runs were inspected, not merely inferred from their red status:

- Run 1: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50/actions/runs/44232897949
- Run 2: https://github.com/crypto143007-ship-it/SOVR-Kernel-A50/actions/runs/44232918720

Both completed checkout and ARM64 defconfig successfully, then failed while building host-side DTC. Logs showed:
- `aarch64-linux-gnu-gcc: not found` because Ubuntu's installed GCC 10 cross package exposes a version-suffixed executable.
- `multiple definition of yylloc` while linking `scripts/dtc/dtc`, due to the old Linux 5.1 host DTC code and modern GCC's default `-fno-common`.

The workflow was corrected in commit `67801066b38d80b6c60a6556cea48b604dec38eb`:
- Create the expected `aarch64-linux-gnu-gcc` executable as a symlink to `aarch64-linux-gnu-gcc-10`.
- Pass `HOSTCFLAGS=-fcommon` to the Linux 5.1 build to restore the common-symbol behavior expected by its bundled DTC.

The corrected workflow is expected to trigger a new run from the migration branch push. Its result must be checked before calling the baseline successful. The previous failed artifacts contained source identity and defconfig evidence only; they did not contain a completed kernel Image or DTBs.

### Scope reminder

This remains an upstream baseline only. It is not an Exynos9610/SOVR vendor integration build and does not validate A505F hardware.


A follow-up CI efficiency correction was committed as `d09b3b7e300b5f1cae8027d9fc157d34cbf8bc7d`: the baseline workflow no longer performs a redundant full checkout of the large SOVR migration repository. The job builds only the separately pinned upstream tree, and the removed checkout was not referenced by any build or evidence step. This reduces runner time and avoids fetching the 4.14 vendor tree just to compile vanilla upstream Linux.
