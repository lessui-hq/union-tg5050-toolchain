FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install build tools and aarch64 cross-compiler
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autopoint \
    autotools-dev \
    build-essential \
    ca-certificates \
    cmake \
    g++-aarch64-linux-gnu \
    gcc-aarch64-linux-gnu \
    gettext \
    git \
    libtool \
    m4 \
    make \
    ninja-build \
    pkg-config \
    po4a \
    python3 \
    unzip \
    vim \
    wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Sysroot for TG5050-specific libraries
ENV SYSROOT=/opt/tg5050-sysroot

# Download and extract SDK libraries
ENV SDK_VERSION=20251208
ENV SDK_FILE=sdk_tg5050_linux_v1.0.0.tgz
ENV SDK_URL=https://github.com/lessui-hq/union-tg5050-toolchain/releases/download/${SDK_VERSION}/${SDK_FILE}

COPY support/extract-sdk.sh /tmp/extract-sdk.sh
RUN chmod +x /tmp/extract-sdk.sh && \
    mkdir -p /sdk ${SYSROOT}/usr/lib/pkgconfig ${SYSROOT}/usr/include ${SYSROOT}/usr/bin ${SYSROOT}/lib && \
    wget -q ${SDK_URL} -O /tmp/${SDK_FILE} && \
    tar -xzf /tmp/${SDK_FILE} -C /sdk --strip-components=2 && \
    /tmp/extract-sdk.sh && \
    rm -rf /sdk /tmp/${SDK_FILE} /tmp/extract-sdk.sh

# Cross-compiler prefix (uses aarch64-linux-gnu toolchain)
ENV CROSS_COMPILE=/usr/bin/aarch64-linux-gnu-
ENV CC=${CROSS_COMPILE}gcc \
    CXX=${CROSS_COMPILE}g++ \
    AR=${CROSS_COMPILE}ar \
    LD=${CROSS_COMPILE}ld

# Point builds at the SDK libraries
ENV PREFIX=${SYSROOT}/usr

# CMake configuration
COPY toolchain.cmake /opt/toolchain.cmake
ENV CMAKE_TOOLCHAIN_FILE=/opt/toolchain.cmake

# pkg-config for SDK libraries
ENV PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
ENV PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig

# Build additional libraries (before setting sysroot flags)
COPY support/build-extra-libs.sh /tmp/build-extra-libs.sh
RUN chmod +x /tmp/build-extra-libs.sh && \
    /tmp/build-extra-libs.sh && \
    rm /tmp/build-extra-libs.sh

# Compiler/linker flags to find SDK headers and libraries
ENV CFLAGS="-I${SYSROOT}/usr/include"
ENV CPPFLAGS="-I${SYSROOT}/usr/include"
ENV LDFLAGS="-L${SYSROOT}/usr/lib -Wl,-rpath-link=${SYSROOT}/usr/lib"

# Platform identification
ENV UNION_PLATFORM=tg5050

# Shell environment setup
COPY support/setup-env.sh /root/setup-env.sh
RUN cat /root/setup-env.sh >> /root/.bashrc

# Workspace
RUN mkdir -p /root/workspace
VOLUME /root/workspace
WORKDIR /root/workspace

CMD ["/bin/bash"]
