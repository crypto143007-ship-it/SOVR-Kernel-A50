# Root integration modes

The package matrix uses separate build invocations for each root mode:

| ZIP suffix | Build option | Build-script behavior |
| --- | --- | --- |
| `Simple` | None | Disables KernelSU and uses the non-root configuration. |
| `Magisk` | `--magisk` | Applies the pre-root configuration, updates the bundled Magisk assets, and writes the per-build Magisk configuration. |
| `KernelSU` | `--ksu` | Enables the in-tree KernelSU hooks and SuSFS configuration; does not enable Magisk. |

The installer remains an AnyKernel-based recovery ZIP. The root suffix identifies what was configured in the kernel/package; it is not evidence that root access or a manager app works on a given ROM. The generated `mint.prop` records the selected root mode and is validated against the matrix entry.
