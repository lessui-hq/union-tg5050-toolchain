# Multi-stage build: Use crosstool-NG to build GCC 10.3 + glibc 2.33
# Based on crosstool-NG official Docker template

FROM ubuntu:22.04 AS toolchain-builder

# Create ctng user (crosstool-NG won't run as root)
ARG CTNG_UID=1000
ARG CTNG_GID=1000
RUN groupadd -g $CTNG_GID ctng && \
    useradd -d /home/ctng -m -g $CTNG_GID -u $CTNG_UID -s /bin/bash ctng

# Non-interactive configuration
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
RUN echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections && \
    echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections

# Install crosstool-NG dependencies (from official template)
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    bison \
    bzip2 \
    ca-certificates \
    file \
    flex \
    g++ \
    gawk \
    gcc \
    gettext \
    git \
    gperf \
    help2man \
    libncurses5-dev \
    libstdc++6 \
    libtool \
    libtool-bin \
    make \
    meson \
    ninja-build \
    patch \
    python3-dev \
    rsync \
    texinfo \
    unzip \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download and install crosstool-NG
ENV CT_NG_VERSION=1.26.0
WORKDIR /build
RUN wget -q https://github.com/crosstool-ng/crosstool-ng/archive/crosstool-ng-${CT_NG_VERSION}.tar.gz && \
    tar xf crosstool-ng-${CT_NG_VERSION}.tar.gz && \
    cd crosstool-ng-crosstool-ng-${CT_NG_VERSION} && \
    ./bootstrap && \
    ./configure --prefix=/opt/ctng && \
    make && \
    make install && \
    cd .. && rm -rf crosstool-ng-*

# Add ctng to PATH
RUN echo 'export PATH=/opt/ctng/bin:$PATH' >> /etc/profile
ENV PATH="/opt/ctng/bin:${PATH}"

# Switch to ctng user and create working directory
USER ctng
WORKDIR /home/ctng
RUN mkdir -p /home/ctng/{src,work}

# Create toolchain configuration
WORKDIR /home/ctng/work
RUN ct-ng aarch64-unknown-linux-gnu

# Configure for GCC 10.3 + glibc 2.33
RUN sed -i \
    -e 's/CT_GCC_V_.*=y/# CT_GCC_V_XXX=y/' \
    -e '/# CT_GCC_V_10 is not set/a CT_GCC_V_10=y' \
    -e 's/CT_GCC_VERSION=.*/CT_GCC_VERSION="10.3.0"/' \
    -e 's/CT_GLIBC_V_.*=y/# CT_GLIBC_V_XXX=y/' \
    -e '/# CT_GLIBC_V_2_33 is not set/a CT_GLIBC_V_2_33=y' \
    -e 's/CT_GLIBC_VERSION=.*/CT_GLIBC_VERSION="2.33"/' \
    -e 's/CT_DEBUG_GDB=y/# CT_DEBUG_GDB is not set/' \
    -e 's/CT_STRIP_HOST_TOOLCHAIN_EXECUTABLES=y/# CT_STRIP_HOST_TOOLCHAIN_EXECUTABLES is not set/' \
    .config

# Build toolchain as ctng user
RUN ct-ng build CT_JOBS=$(nproc)

# Switch back to root and move toolchain to /opt
USER root
RUN mv /home/ctng/x-tools/aarch64-unknown-linux-gnu /opt/aarch64-linux-gnu

# ============================================================
# Final stage - production environment
# ============================================================

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    autopoint \
    autotools-dev \
    ca-certificates \
    cmake \
    gettext \
    git \
    libtool \
    m4 \
    make \
    pkg-config \
    po4a \
    python3 \
    unzip \
    vim \
    wget \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy toolchain from builder
COPY --from=toolchain-builder /opt/aarch64-linux-gnu /opt/aarch64-linux-gnu

# Add toolchain to PATH
ENV PATH="/opt/aarch64-linux-gnu/bin:${PATH}"

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

# Cross-compiler prefix
ENV CROSS_COMPILE=/opt/aarch64-linux-gnu/bin/aarch64-unknown-linux-gnu-
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

# Build additional libraries
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
