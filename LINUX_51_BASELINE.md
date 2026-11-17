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
