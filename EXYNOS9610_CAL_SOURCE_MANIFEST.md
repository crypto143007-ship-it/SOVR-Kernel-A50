# Exynos9610 CAL Source Dependency Manifest

Audit date: 2026-11-17  
Vendor source ref: `main`  
Target baseline: upstream Linux `v5.1`, commit `e93c9c99a629c61837d5a7fc2120cd2b6c70dbdd`

## Scope

This is a source-presence and dependency-boundary manifest for the vendor CAL implementation. It does not claim that these files compile against Linux 5.1, that all objects are selected by the A50 configuration, or that hardware initialization works.

## Confirmed direct CAL translation-unit includes

Source: `drivers/soc/samsung/cal-if/cal-if.c`, blob `35c62490a906259667bc347231a7e35dc8b0b514`.

| Include | Vendor path checked | Blob SHA | Result |
|---|---|---|---|
| `<soc/samsung/ect_parser.h>` | `include/soc/samsung/ect_parser.h` | `f99eca4b9c60cfba568b426fa75c0fde1977a021` | Present |
| `<soc/samsung/cal-if.h>` | `include/soc/samsung/cal-if.h` | `65fe05a30e4251b0ca9d735ddbb29d7713374ac5` | Present; previously audited |
| `pwrcal-env.h` | `drivers/soc/samsung/cal-if/pwrcal-env.h` | `9a968d3592e91eff0d4ac7b51a6bd353f07072ab` | Present |
| `cmucal.h` | `drivers/soc/samsung/cal-if/cmucal.h` | `56e71d6cdcc49b3dd5daf530d7cac147b677a3fc` | Present |
| `ra.h` | `drivers/soc/samsung/cal-if/ra.h` | `de810e9b413991ba411bce08d0e70696f2c92e3b` | Present |
| `acpm_dvfs.h` | `drivers/soc/samsung/cal-if/acpm_dvfs.h` | `6e4fa6dd747ad8f066ee2900a57f4db5af595550` | Present |
| `fvmap.h` | `drivers/soc/samsung/cal-if/fvmap.h` | `34b613b3ba56b9eae25a53449b76c41f98d3c81c` | Present |
| `asv.h` | `drivers/soc/samsung/cal-if/asv.h` | `50a114069e8834c511d56d90fc49cd7e519f1af8` | Present |
| `pmucal_system.h` | `drivers/soc/samsung/cal-if/pmucal_system.h` | `9a4bb18aa90c326cd5e482e2ea96ec9b9c2f3f87` | Present |
| `pmucal_local.h` | `drivers/soc/samsung/cal-if/pmucal_local.h` | `042f678747c861bba7f103dbac9be6d9405f5de7` | Present |
| `pmucal_cpu.h` | `drivers/soc/samsung/cal-if/pmucal_cpu.h` | `dd5544383ce26f0da7004fb7940556cb812ae947` | Present |
| `pmucal_cp.h` | `drivers/soc/samsung/cal-if/pmucal_cp.h` | `828b3e44b07bc5e9310905b803d334a3427b8006` | Present |
| `pmucal_gnss.h` | `drivers/soc/samsung/cal-if/pmucal_gnss.h` | `af1c5cacde3e4d2e2455f7fde97710e894bb32cb` | Present |
| `pmucal_shub.h` | `drivers/soc/samsung/cal-if/pmucal_shub.h` | `ec3e2770ffbd9758f2f4df28d1693debfcc9f4b6` | Present |
| `pmucal_rae.h` | `drivers/soc/samsung/cal-if/pmucal_rae.h` | `9f6dc75f618a1a88b667184c96265426744d8909` | Present |

The above records source-path presence only. Header transitive includes, external symbol definitions, Kconfig guards and link dependencies still need to be walked recursively.

## Additional CAL interface headers checked

| Path | Blob SHA | Bytes |
|---|---|---:|
| `drivers/soc/samsung/cal-if/vclk.h` | `2d28de79a20fc5f6124b4300ef0e9967ec5a95b2` | 3,504 |
| `drivers/soc/samsung/cal-if/ra.h` | `de810e9b413991ba411bce08d0e70696f2c92e3b` | 3,434 |

## Build composition

The vendor CAL Makefile is `drivers/soc/samsung/cal-if/Makefile`, blob `00944ace1b772acd0193edf80792dd7b884e4c0a`. It conditionally selects core CAL/CMUCAL, PMUCAL, ACPM DVFS/FVMAP and Exynos9610 SoC data objects under distinct configuration symbols. The precise object-to-symbol mapping must be preserved when constructing the Linux 5.1 Kconfig/Makefile integration; do not flatten all objects into an unconditional composite.

## Next concrete source-analysis tasks

1. Recursively walk includes from `cal-if.c`, `cmucal.h`, `vclk.h`, `ra.h` and the Exynos9610 CAL data headers.
2. Enumerate every externally referenced function and global from the CAL translation unit and map it to a definition and object file.
3. Resolve all preprocessor paths under the actual A50 core and default defconfigs, including optional CP/GNSS/SHUB/FLEXPMU/BCM debug paths.
4. Compare the required Linux core APIs with v5.1, recording changed signatures and semantics.
5. Only then create the first compilable compatibility patch series.

## Safety

No source implementation was copied or modified by this manifest. No kernel compilation, DTB generation, flashing or device boot validation is claimed. The known-working vendor kernel remains the recovery baseline.
