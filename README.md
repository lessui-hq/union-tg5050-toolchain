# TG5050 Toolchain Docker Image

ARM64 build environment for TG5050 handheld devices.

## Usage

The image is automatically built and published by GitHub Actions to `ghcr.io/lessui-hq/union-tg5050-toolchain:latest`.

From the LessUI repository:
```bash
make build PLATFORM=tg5050
```

## Local Development

```bash
make shell  # Enters the toolchain container
```

The container's `/root/workspace` is bound to `./workspace` by default.

## Toolchain Details

- **GCC:** 10.3.0 (built with crosstool-NG)
- **glibc:** 2.33 (in toolchain sysroot)
- **Sysroot:** `/opt/tg5050-sysroot`
- **SDK libraries:** SDL2, OpenGL ES 2, DRM, Mali, ALSA, TinyALSA, FreeType, HarfBuzz, GLib

See [setup-env.sh](./support/setup-env.sh) for environment variables exported automatically.

## Acknowledgments

SDK derived from [LoveRetro/tg5050-toolchain](https://github.com/LoveRetro/tg5050-toolchain).
