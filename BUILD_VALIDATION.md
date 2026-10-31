# Build and artifact validation

The matrix validates each output independently before upload:

1. The named ZIP and final `.config` must exist and be non-empty.
2. The Android boot image must exist and be non-empty.
3. `unzip -t` must accept the ZIP, and its archive must contain `Image`, `dtb.img`, and `mint.prop`.
4. `mint.prop` must report the expected package basename and root integration.
5. CI saves a uniquely named boot-image copy and SHA-256 sums for the ZIP and boot image.

These checks establish build-output presence and archive structure only. They do not execute the installer, validate partition writes, test ROM detection, or boot the device. CI artifacts and checksums should be retained with the corresponding Actions run.
