/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * thermal_exynos.h - Samsung EXYNOS TMU device tree definitions
 *
 *  Copyright (C) 2014 Samsung Electronics
 *  Lukasz Majewski <l.majewski@samsung.com>
 */

#ifndef _EXYNOS_THERMAL_TMU_DT_H
#define _EXYNOS_THERMAL_TMU_DT_H

#define TYPE_ONE_POINT_TRIMMING 0
#define TYPE_ONE_POINT_TRIMMING_25 1
#define TYPE_ONE_POINT_TRIMMING_85 2
#define TYPE_TWO_POINT_TRIMMING 3
#define TYPE_NONE 4

/* Exynos9610 TMU sensor types (from the vendor binding ABI). */
#define TEM1002X			0x0
#define TEM1455X			0x2
#define TEM1456X			0x6

#endif /* _EXYNOS_THERMAL_TMU_DT_H */
