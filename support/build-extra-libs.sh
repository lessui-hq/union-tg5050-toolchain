#!/bin/bash
#
# Build additional libraries into the sysroot.
#

set -euo pipefail

NPROC=$(nproc)
INSTALL_PREFIX="${SYSROOT}/usr"

echo "=== Building extra libraries ==="

# xz/lzma
echo "Building: xz"
git clone --depth=1 https://github.com/tukaani-project/xz.git /tmp/xz
cd /tmp/xz
./autogen.sh
./configure --prefix=${INSTALL_PREFIX} --disable-static --enable-shared
make -j${NPROC} && make install
cd /tmp && rm -rf /tmp/xz

# zstd
echo "Building: zstd"
git clone --depth=1 https://github.com/facebook/zstd.git /tmp/zstd
cd /tmp/zstd/build/cmake
cmake . -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_BUILD_TYPE=Release
make -j${NPROC} && make install
cd /tmp && rm -rf /tmp/zstd

# libzip
echo "Building: libzip"
git clone --depth=1 https://github.com/nih-at/libzip.git /tmp/libzip
mkdir /tmp/libzip/build && cd /tmp/libzip/build
cmake .. -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_BUILD_TYPE=Release
make -j${NPROC} && make install
cd /tmp && rm -rf /tmp/libzip

# libsamplerate
echo "Building: libsamplerate"
git clone --depth=1 --branch 0.2.2 https://github.com/libsndfile/libsamplerate.git /tmp/samplerate
mkdir /tmp/samplerate/build && cd /tmp/samplerate/build
cmake .. -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} -DCMAKE_BUILD_TYPE=Release
make -j${NPROC} && make install
cd /tmp && rm -rf /tmp/samplerate

echo "=== Done ==="
