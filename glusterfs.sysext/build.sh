#!/bin/ash
#
# Build script helper for glusterfs sysext.
# This script runs inside an ephemeral alpine container.
# It builds a static glusterfs and exports the binary to a bind-mounted volume.
#
set -euo pipefail

version="$1"
export_user_group="$2"

# TODO: Figure out deps: https://github.com/gluster/glusterfs/blob/devel/INSTALL
apk --no-cache add \
        binutils \
        git \
        pkgconf \
        libtool \
        flex \
        flex-dev \
        bison \
        gcc \
        glib \
        glib-dev \
        make \
        musl-dev \
        rpcgen \
        openssl \
        openssl-dev \
        openssl-libs-static \
        acl \
        acl-dev \
        acl-libs \
        acl-static \
        libxml2 \
        libxml2-dev \
        libxml2-static \
        argp-standalone \
        libtirpc \
        libtirpc-dev \
        libtirpc-static \
        liburing \
        liburing-dev \
        liburing-ffi \
        libucontext \
        libucontext-dev \
        userspace-rcu \
        userspace-rcu-dev \
        autoconf \
        automake #zlib-static  alpine-sdk linux-headers libmnl-static
        # file \
        # file-dev \
        # ipset \
        # ipset-dev \
        # iptables \
        # iptables-dev \
        # libmagic-static \
        # libmnl-dev \
        # libnftnl-dev \
        # libnl3-static \
        # libnl3-dev \
        # net-snmp-dev \
        # pcre2 \
        # pcre2-dev \

cd /opt

git clone https://github.com/gluster/glusterfs.git
cd /opt/glusterfs

git checkout $version
./autogen.sh

# TODO: Figure out build args
# @REF [prior art](https://github.com/gluster/glusterfs/compare/devel...kohlschuetter:glusterfs:ck/dev#diff-49473dca262eeab3b4a43002adb08b4db31020d190caaad1594b47f1d5daa810R1451)
# CFLAGS='-static -s -Doff64_t=int64_t -D__off64_t=int64_t' LDFLAGS=-static \
# CFLAGS='-static -s -I/usr/include/arch/common -DREDEFINE_QUAD_T -Doff64_t=int64_t -D__off64_t=int64_t -DF_SETLK64=F_SETLK -DF_SETLKW64=F_SETLKW -DF_GETLK64=F_GETLK -DUSE_LIBUCONTEXT=1' LDFLAGS="-static -lbsd -lucontext" \
CFLAGS='-static -s -I/usr/include/arch/common -D__WORDSIZE=32 -DSIZEOF_TIME_T=8 -DREDEFINE_QUAD_T -Doff64_t=int64_t -D__off64_t=int64_t -DF_SETLK64=F_SETLK -DF_SETLKW64=F_SETLKW -DF_GETLK64=F_GETLK -DUSE_LIBUCONTEXT=1' LDFLAGS="-static -lucontext" \
     ./configure  --disable-dynamic-linking \
    --prefix=/usr \
    --exec-prefix=/usr \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --sysconfdir=/usr/etc \
    --datadir=/usr/share \
    --localstatedir=/var \
    --without-tcmalloc \
    --mandir=/usr/share/man 
    # --enable-bfd \
    # --enable-nftables \
    # --enable-regex \
    # --enable-json  --with-init=systemd --enable-vrrp --enable-libnl-dynamic

make
make DESTDIR=/install_root install

rm -rf /install_root/usr/share \
       /install_root/usr/etc/glusterfs/samples
chown -R "$export_user_group" /install_root
