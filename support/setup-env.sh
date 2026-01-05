export CROSS_COMPILE=/opt/aarch64-linux-gnu/bin/aarch64-unknown-linux-gnu-
export PREFIX=/opt/tg5050-sysroot/usr
export SYSROOT=/opt/tg5050-sysroot
export CFLAGS="-I${SYSROOT}/usr/include"
export CPPFLAGS="-I${SYSROOT}/usr/include"
export LDFLAGS="-L${SYSROOT}/usr/lib -Wl,-rpath-link=${SYSROOT}/usr/lib"
export UNION_PLATFORM=tg5050
