#!/usr/bin/env bash
set -u
report="${1:-exynos9610-vendor-audit.txt}"
: > "$report"
check_path() {
  local label="$1" path="$2"
  if [ -e "$path" ]; then
    printf 'PRESENT  %-28s %s\n' "$label" "$path" | tee -a "$report"
  else
    printf 'MISSING  %-28s %s\n' "$label" "$path" | tee -a "$report"
  fi
}
{
  echo "Exynos9610 vendor integration audit"
  echo "Kernel: $(make -s kernelversion 2>/dev/null || echo unknown)"
  echo "Source presence is not proof of buildability or hardware functionality."
  echo "UFS CAL/FMP integration must be traced from actual reference source paths; no guessed ufs-cal-9610.c path is assumed."
} | tee -a "$report"
check_path "generic UFS host" drivers/scsi/ufs/ufshcd.c
check_path "platform UFS glue" drivers/scsi/ufs/ufshcd-pltfrm.c
check_path "Samsung Exynos UFS host" drivers/scsi/ufs/ufs-exynos.c
check_path "Samsung Exynos UFS PHY" drivers/phy/samsung/phy-exynos7-ufs.c
check_path "Samsung UFS PHY common" drivers/phy/samsung/phy-samsung-ufs.c
check_path "EROFS staging source" drivers/staging/erofs
check_path "EROFS mainline location" fs/erofs
check_path "TZDEV" drivers/misc/tzdev
check_path "Exynos CAL core" drivers/soc/samsung/cal-if/cal-if.c
check_path "Exynos CMUCAL core" drivers/soc/samsung/cal-if/cmucal.c
check_path "Exynos9610 CAL data" drivers/soc/samsung/cal-if/exynos9610/cal_data.c
check_path "Exynos9610 CMUCAL nodes" drivers/soc/samsung/cal-if/exynos9610/cmucal-node.c
check_path "Exynos9610 PMUCAL CPU" drivers/soc/samsung/cal-if/exynos9610/pmucal_cpu_exynos9610.h
check_path "ACPM core" drivers/soc/samsung/acpm/acpm.c
check_path "ACPM IPC" drivers/soc/samsung/acpm/acpm_ipc.c
check_path "Samsung Mali platform" drivers/gpu/arm
{
  echo
  echo "EROFS interpretation:"
  if [ -d drivers/staging/erofs ]; then
    echo "Legacy EROFS staging implementation exists; it is not the fs/erofs mainline layout."
    echo "Check Kconfig selection, API compatibility, and Android EROFS image features before enabling."
  else
    echo "No EROFS source tree detected in the audited locations."
  fi
  echo
  echo "Relevant configuration:"
  grep -E '^(CONFIG_(SCSI_UFSHCD|SCSI_UFSHCD_PLATFORM|EROFS_FS|EROFS_FS_ZIP|EXYNOS_THERMAL|EXYNOS_PMU|EXYNOS_PM_DOMAINS))=' .config || true
} | tee -a "$report"
