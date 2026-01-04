# TG5050 Toolchain

Docker-based native ARM64 build environment for the TG5050 handheld.

## Quick Start

```bash
make shell

# Inside the container
cd ~/workspace/your-project
make
```

## Requirements

- Docker (on ARM64 host)
- make

## Environment Variables

| Variable | Value |
|----------|-------|
| `UNION_PLATFORM` | `tg5050` |
| `SYSROOT` | `/opt/tg5050-sysroot` |
| `PKG_CONFIG_PATH` | Points to SDK libraries |
| `CMAKE_TOOLCHAIN_FILE` | `/opt/toolchain.cmake` |

## Included Libraries

**Graphics**: SDL2, OpenGL ES 2, DRM, Mali
**Audio**: ALSA, TinyALSA, libsamplerate
**Compression**: zlib, bzip2, lz4, xz, zstd, libzip
**Text/Fonts**: FreeType, HarfBuzz
**Images**: libpng
**System**: GLib, D-Bus, udev, SQLite3

## Commands

```bash
make shell   # Build (if needed) and enter container
make clean   # Remove Docker image
```

## Acknowledgments

SDK derived from [LoveRetro/tg5050-toolchain](https://github.com/LoveRetro/tg5050-toolchain).
