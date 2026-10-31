# Toolchain and CI

## Pinned compiler

The matrix workflows install and use Google's AOSP Clang 17.0.2 (`clang-r487747c`) from prebuilts commit `fd582b924a400906979f54121c05555b453d5c35`. A prerequisite job warms the reusable action's cache, keyed by OS, architecture, and commit, before the matrix fans out. The action verifies compiler metadata and required LLVM tools. Every build invocation selects the compiler explicitly with `--toolchain aosp_17`; installing a pinned compiler without that argument would leave the upstream Neutron default active.

The stable `galaxy-a50.yml` builds also select `aosp_17`. Other local builds continue to use the build script's upstream default unless a toolchain is explicitly selected.

## Workflow behavior

`development.yml` runs the 21-profile matrix on pull requests to `main`, pushes to the legacy development branch, or manual dispatch. Manual dispatch can select a ROM profile and root integration. Jobs upload uniquely named artifacts; the workflow does not create or publish a GitHub Release.

Each package job runs `.github/scripts/validate-kernel-artifacts.sh`, which checks the final config, boot image, ZIP integrity, packaged `Image` and `dtb.img`, and root/package identity; it also emits a named boot image and SHA-256 sums.

## Limits

Workflow configuration and artifact checks are not a successful kernel build. Report the resulting Actions run and package artifacts before describing the matrix as built. A CI pass still does not establish that a package boots on a physical Galaxy A50.
