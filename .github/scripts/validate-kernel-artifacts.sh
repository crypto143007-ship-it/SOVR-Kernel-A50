#!/usr/bin/env bash
set -euo pipefail

config_file="${1:?Usage: validate-kernel-artifacts.sh <config-file>}"
expected_package="${2:-}"
expected_root_type="${3:-}"
job_id="${GITHUB_JOB:?GITHUB_JOB must be set by GitHub Actions}"
release_dir=release
boot_image=tools/make/boot.img
named_boot_image="${release_dir}/boot-${job_id}.img"

if [[ ! -s "$config_file" ]]; then
	echo "::error::Final kernel configuration is missing or empty: $config_file"
	exit 1
fi

if [[ ! -s "$boot_image" ]]; then
	echo "::error::Built Android boot image is missing or empty: $boot_image"
	exit 1
fi

shopt -s nullglob
if [[ -n "$expected_package" ]]; then
	packages=("$release_dir/$expected_package")
else
	packages=("$release_dir"/*.zip)
fi
if (( ${#packages[@]} == 0 )); then
	echo "::error::No flashable kernel ZIP was produced in $release_dir."
	exit 1
fi

cp "$boot_image" "$named_boot_image"
for package in "${packages[@]}"; do
	if [[ ! -s "$package" ]] || ! unzip -t "$package" >/dev/null; then
		echo "::error::Flashable kernel ZIP is missing, empty, or invalid: $package"
		exit 1
	fi

	if ! unzip -Z1 "$package" | grep -Eq '(^|/)Image$'; then
		echo "::error::Kernel image is missing from package: $package"
		exit 1
	fi
	if ! unzip -Z1 "$package" | grep -Eq '(^|/)dtb\.img$'; then
		echo "::error::Expected device-tree image is missing from package: $package"
		exit 1
	fi

	if [[ -n "$expected_package" || -n "$expected_root_type" ]]; then
		manifest="$(unzip -p "$package" mint.prop 2>/dev/null)" || {
			echo "::error::Package manifest is missing: $package"
			exit 1
		}
		if [[ -n "$expected_package" ]] &&
			! printf '%s\n' "$manifest" | grep -Fqx "ro.mint.build.package=${expected_package%.zip}"; then
			echo "::error::Package manifest name does not match $expected_package."
			exit 1
		fi
		if [[ -n "$expected_root_type" ]] &&
			! printf '%s\n' "$manifest" | grep -Fqx "ro.mint.build.root=$expected_root_type"; then
			echo "::error::Package root integration does not match $expected_root_type."
			exit 1
		fi
	fi
done

sha256sum "$named_boot_image" "${packages[@]}" \
	> "${release_dir}/SHA256SUMS-${job_id}.txt"

echo "Validated ${#packages[@]} flashable package(s), final configuration, boot image, and DTB."
