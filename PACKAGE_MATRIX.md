# Package matrix

The development workflow generates three distinct packages for each of seven build profiles. ZIP names are exact and use the form `<profile>-<root-mode>.zip`.

| Profile | Android API | Kernel variant | Configuration basis |
| --- | ---: | --- | --- |
| OneUI4 | 12 | `oneui` | Android 12 fragments |
| OneUI5 | 13 | `oneui` | Android 13 fragments |
| OneUI6 | 14 | `oneui` | Android 14 fragments and One UI DTB |
| OneUI7 | 15 | `oneui` | Android 14 fragments and DTB fallback; experimental |
| OneUI8 | 16 | `oneui` | Android 14 fragments and DTB fallback; experimental |
| OneUI8.5 | 16 | `oneui` | Android 14 fragments and DTB fallback; experimental |
| AOSP | 14 | `aosp` | Android 14 AOSP DTB; experimental |

Every profile produces `-Simple.zip`, `-Magisk.zip`, and `-KernelSU.zip`, for 21 artifacts total. `Simple` enables neither root integration; `Magisk` uses the `--magisk` pre-root flow; `KernelSU` uses `--ksu` and the in-tree KernelSU/SuSFS configuration. The root-mode name and package basename are embedded in `mint.prop` and checked by CI.

Android 15 and 16 builds currently reuse the Android 14 Mali and partial-deknox fragments because newer fragments are absent. They are experimental build targets, not claims of One UI 7/8/8.5 support on the A50. A workflow-dispatch run can select one profile and/or one root mode; the default is all 21.
