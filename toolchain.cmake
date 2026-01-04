# CMake toolchain file for TG5050 native ARM64 builds
#
# Links against TG5050 SDK libraries while using native compiler.

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Use native compilers
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)

# SDK sysroot for device-specific libraries
set(sysroot $ENV{SYSROOT})

# Add SDK paths to search
list(APPEND CMAKE_PREFIX_PATH ${sysroot}/usr)
list(APPEND CMAKE_LIBRARY_PATH ${sysroot}/usr/lib)
list(APPEND CMAKE_INCLUDE_PATH ${sysroot}/usr/include)

# Prefer SDK libraries over system libraries
set(CMAKE_FIND_ROOT_PATH ${sysroot})
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# pkg-config
set(ENV{PKG_CONFIG_PATH} "${sysroot}/usr/lib/pkgconfig:${sysroot}/usr/share/pkgconfig")
