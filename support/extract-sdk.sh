#!/bin/bash
#
# Extract required libraries from TG5050 buildroot SDK into sysroot.
#

set -euo pipefail

SDK_PATH="/sdk/aarch64-buildroot-linux-gnu/sysroot"
DEST="${SYSROOT}"

copy_lib() {
    local name="$1"
    local include_path="${2:-}"
    local lib_pattern="${3:-lib${name}}"
    local pc_files="${4:-${name}.pc}"

    echo "Extracting: ${name}"

    # Headers
    if [ -n "${include_path}" ]; then
        for item in ${include_path}; do
            if [ -d "${SDK_PATH}/usr/include/${item}" ]; then
                mkdir -p "${DEST}/usr/include/${item}"
                cp -r "${SDK_PATH}/usr/include/${item}/." "${DEST}/usr/include/${item}/"
            elif [ -f "${SDK_PATH}/usr/include/${item}" ]; then
                cp "${SDK_PATH}/usr/include/${item}" "${DEST}/usr/include/"
            fi
        done
    fi

    # Libraries
    for dir in "${SDK_PATH}/usr/lib" "${SDK_PATH}/lib"; do
        if ls ${dir}/${lib_pattern}* >/dev/null 2>&1; then
            cp -r ${dir}/${lib_pattern}* "${DEST}/usr/lib/"
        fi
    done

    # pkg-config
    for pc in ${pc_files}; do
        if [ -f "${SDK_PATH}/usr/lib/pkgconfig/${pc}" ]; then
            cp "${SDK_PATH}/usr/lib/pkgconfig/${pc}" "${DEST}/usr/lib/pkgconfig/"
        fi
    done
}

echo "=== Extracting SDK to ${DEST} ==="

# Graphics
copy_lib "SDL2" "SDL2" "libSDL" "sdl2.pc SDL2_image.pc SDL2_ttf.pc"
cp -r ${SDK_PATH}/usr/bin/sdl* "${DEST}/usr/bin/" 2>/dev/null || true
copy_lib "GLES2" "GLES2" "libGLES" "glesv2.pc"
copy_lib "mali" "" "libmali" ""
copy_lib "drm" "drm xf86drm.h xf86drmMode.h" "libdrm" "libdrm.pc"

# Audio
copy_lib "alsa" "alsa" "libasound" "alsa.pc"
copy_lib "tinyalsa" "tinyalsa" "libtinyalsa" "tinyalsa.pc"

# Compression
copy_lib "zlib" "zlib.h zconf.h" "libz" "zlib.pc"
copy_lib "bz2" "bzlib.h" "libbz2" ""
copy_lib "lz4" "lz4.h lz4frame.h lz4hc.h" "liblz4" "liblz4.pc"

# Text/Fonts
copy_lib "freetype" "freetype2" "libfreetype" "freetype2.pc"
copy_lib "harfbuzz" "harfbuzz" "libharfbuzz" "harfbuzz.pc"

# Images
copy_lib "png" "png.h pngconf.h pnglibconf.h" "libpng" "libpng.pc libpng16.pc"

# GLib
copy_lib "glib" "glib-2.0" "libglib-2.0" "glib-2.0.pc"
mkdir -p "${DEST}/usr/lib/glib-2.0/include"
cp -r ${SDK_PATH}/usr/lib/glib-2.0/include/. "${DEST}/usr/lib/glib-2.0/include/"
copy_lib "gobject" "" "libgobject-2.0" "gobject-2.0.pc"
copy_lib "gmodule" "" "libgmodule-2.0" "gmodule-2.0.pc gmodule-export-2.0.pc gmodule-no-export-2.0.pc"
copy_lib "gio" "gio-unix-2.0" "libgio-2.0" "gio-2.0.pc"
copy_lib "ffi" "ffi.h ffitarget.h" "libffi" "libffi.pc"
copy_lib "pcre" "pcre.h" "libpcre" "libpcre.pc"

# System
copy_lib "mount" "" "libmount" "mount.pc"
copy_lib "blkid" "blkid" "libblkid" "blkid.pc"
copy_lib "dbus" "dbus-1.0" "libdbus-1" "dbus-1.pc"
mkdir -p "${DEST}/usr/lib/dbus-1.0/include"
cp -r ${SDK_PATH}/usr/lib/dbus-1.0/include/. "${DEST}/usr/lib/dbus-1.0/include/" 2>/dev/null || true
copy_lib "udev" "libudev.h" "libudev" "libudev.pc"
copy_lib "sqlite3" "sqlite3.h sqlite3ext.h" "libsqlite3" "sqlite3.pc"

echo "=== Done ==="
