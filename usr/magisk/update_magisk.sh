#!/bin/bash

set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ver="$(cat "$DIR/magisk_version" 2>/dev/null || echo -n 'none')"

if [ "x$1" = "xcanary" ]
then
	nver="canary"
	magisk_link="https://raw.githubusercontent.com/topjohnwu/magisk-files/${nver}/app-debug.apk"
elif [ "x$1" = "xlocal" ]
then
	nver="local"
	magisk_link="https://gitlab.com/TenSeventy7/magisk-files/raw/main/app-debug.apk"
else
	if [ "x$1" = "x" ]; then
		release_data="$(curl --fail --location --silent --show-error --retry 3 --connect-timeout 30 https://raw.githubusercontent.com/topjohnwu/magisk-files/master/stable.json)"
		nver="$(printf '%s\n' "$release_data" | jq -er '.magisk.version')"
		magisk_link="$(printf '%s\n' "$release_data" | jq -er '.magisk.link')"
	else
		nver="$1"
		release_version="${nver#v}"
		magisk_link="https://github.com/topjohnwu/Magisk/releases/download/v${release_version}/Magisk-v${release_version}.apk"
	fi
fi

if [ \( -n "$nver" \) -a \( "$nver" != "$ver" \) -o ! \( -f "$DIR/arm/magiskinit64" \) -o \( "$nver" = "canary" \) -o \( "$nver" = "local" \) ]
then
	echo "Updating Magisk from $ver to $nver"
	download_file="$DIR/magisk.zip.part"
	if ! curl --fail --location --silent --show-error --retry 3 --connect-timeout 30 --output "$download_file" "$magisk_link"; then
		rm -f "$download_file"
		echo "Failed to download Magisk from $magisk_link" >&2
		exit 1
	fi
	if ! 7z t "$download_file" >/dev/null; then
		rm -f "$download_file"
		echo "Downloaded Magisk package is not a valid archive: $magisk_link" >&2
		exit 1
	fi
	mv -f "$download_file" "$DIR/magisk.zip"

	7z e "$DIR/magisk.zip" lib/arm64-v8a/libmagiskinit.so lib/armeabi-v7a/libmagisk32.so lib/arm64-v8a/libmagisk64.so assets/stub.apk -o"$DIR" -y
	mv -f "$DIR/libmagiskinit.so" "$DIR/magiskinit"
	mv -f "$DIR/libmagisk32.so" "$DIR/magisk32"
	mv -f "$DIR/libmagisk64.so" "$DIR/magisk64"
	mv -f "$DIR/stub.apk" "$DIR/stub"
	xz --force --check=crc32 "$DIR/magisk32" "$DIR/magisk64" "$DIR/stub"

	echo -n "$nver" > "$DIR/magisk_version"
	rm "$DIR/magisk.zip"
	touch "$DIR/initramfs_list"
else
	echo "Nothing to be done: Magisk version $nver"
fi
