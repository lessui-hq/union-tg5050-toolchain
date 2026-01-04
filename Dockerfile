FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install native build tools
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autopoint \
    autotools-dev \
    build-essential \
    ca-certificates \
    cmake \
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
ENV SDK_URL=https://github.com/LoveRetro/tg5050-toolchain/releases/download/${SDK_VERSION}/${SDK_FILE}

COPY support/extract-sdk.sh /tmp/extract-sdk.sh
RUN chmod +x /tmp/extract-sdk.sh && \
    mkdir -p /sdk ${SYSROOT}/usr/lib/pkgconfig ${SYSROOT}/usr/include ${SYSROOT}/usr/bin ${SYSROOT}/lib && \
    wget -q ${SDK_URL} -O /tmp/${SDK_FILE} && \
    tar -xzf /tmp/${SDK_FILE} -C /sdk --strip-components=2 && \
    /tmp/extract-sdk.sh && \
    rm -rf /sdk /tmp/${SDK_FILE} /tmp/extract-sdk.sh

# Native compiler - use system GCC
ENV CC=gcc \
    CXX=g++ \
    AR=ar \
    LD=ld

# Point builds at the SDK libraries
ENV PREFIX=${SYSROOT}/usr

# CMake configuration
COPY toolchain.cmake /opt/toolchain.cmake
ENV CMAKE_TOOLCHAIN_FILE=/opt/toolchain.cmake

# pkg-config for SDK libraries
ENV PKG_CONFIG_SYSROOT_DIR=${SYSROOT}
ENV PKG_CONFIG_PATH=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig

# Build additional libraries
COPY support/build-extra-libs.sh /tmp/build-extra-libs.sh
RUN chmod +x /tmp/build-extra-libs.sh && \
    /tmp/build-extra-libs.sh && \
    rm /tmp/build-extra-libs.sh

# Platform identification
ENV UNION_PLATFORM=tg5050

# Workspace
RUN mkdir -p /root/workspace
VOLUME /root/workspace
WORKDIR /root/workspace

CMD ["/bin/bash"]
