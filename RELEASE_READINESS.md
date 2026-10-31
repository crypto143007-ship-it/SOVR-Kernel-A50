# Release readiness

The upstream synchronization and package-matrix branch is intended for review and CI artifacts. The development workflow does not publish or overwrite a GitHub Release.

Before any stable release, confirm all 21 jobs pass, inspect the final resolved configurations and package contents, verify the checksums, and test relevant installers and boot behavior on physical A50 models and ROMs. OneUI 7/8/8.5 profiles currently reuse Android 14 kernel fragments and must remain marked experimental. Do not remove those caveats based solely on successful compilation or ZIP validation.
