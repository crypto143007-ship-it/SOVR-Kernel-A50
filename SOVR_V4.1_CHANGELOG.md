# SOVR v4.1 Development Changelog

This is an incremental development record, not a v4.1 release declaration. The fork's v4.0 baseline remains available in the parent commit.

## Changes in this development snapshot

- Changed the A50 core defconfig's default ZRAM compressor from ZSTD to LZ4. ZSTD compression support remains enabled.
- Made `build.sh` stop on failed commands and pipelines instead of continuing with potentially stale build outputs.
- Made the generated boot command line match the selected SELinux profile: One UI/recovery defaults to enforcing, while an explicitly permissive build and the existing AOSP always-permit profile retain permissive mode.
- Enabled the existing development build workflow on pushes to this development branch and reduced its repository token permission to read-only.
- Corrected README claims that were not supported by the checked-in defconfigs or scheduler sources, and clarified where runtime validation is still required.

## Not yet complete

The full hardware audit, final merged `.config` generation, Mint commit-level backport review, Android ROM testing, performance benchmarks, and device validation are outstanding. No release artifact has been produced.
