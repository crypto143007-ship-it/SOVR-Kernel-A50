# Compatibility matrix

This matrix describes build inputs and source evidence only. No entry should be treated as physically tested unless a separate device-test result is attached.

| Package family | Android target | Source evidence | Compatibility status |
| --- | ---: | --- | --- |
| OneUI4 | 12 | Android 12 Mali and partial-deknox fragments; installer recognizes the Android 12/13 profile path | Experimental package build; no boot confirmation recorded |
| OneUI5 | 13 | Android 13 Mali and partial-deknox fragments; installer recognizes the Android 12/13 profile path | Experimental package build; no boot confirmation recorded |
| OneUI6 | 14 | Android 14 Mali fragment and One UI 14 DTB | Experimental package build; no boot confirmation recorded |
| OneUI7 | 15 | Android 14 Mali/partial-deknox fragments and DTB reused | Unsupported as a compatibility claim; experimental artifact only |
| OneUI8 / OneUI8.5 | 16 | Android 14 Mali/partial-deknox fragments and DTB reused; installer recognizes API 36 for its Android 14+ profile | Unsupported as a compatibility claim; experimental artifact only |
| AOSP | 14 | Dedicated Android 14 AOSP DTB and AOSP variant fragment | Experimental package build; no boot confirmation recorded |

Installer detection and successful ZIP assembly do not prove kernel/userspace ABI compatibility, boot success, Wi-Fi, camera, storage, SELinux, root-manager behavior, or TZDEV operation. Back up the boot image and recovery access before any device testing.
