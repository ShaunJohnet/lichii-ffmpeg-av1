#!/bin/sh

# Builds a static release dav1d for FFmpeg's libdav1d decoder (MSVC only) and installs it into
# $ROOTDIR/dav1d-install. Switch 2 titles ship their movies as AV1, which FFmpeg has no native
# software decoder for.

# shellcheck disable=SC1091

set -e

. tools/common.sh

DAV1D_VERSION=1.5.4
DAV1D_SRC="$ROOTDIR/dav1d-$DAV1D_VERSION"
DAV1D_PREFIX="$ROOTDIR/dav1d-install"

_group "Building dav1d $DAV1D_VERSION"

must_install curl tar python

if [ ! -d "$DAV1D_SRC" ]; then
	curl -sSfL "https://code.videolan.org/videolan/dav1d/-/archive/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.gz" |
		tar xz -C "$ROOTDIR"
fi

python -m pip install --quiet --disable-pip-version-check meson ninja

prefix="$(cygpath -m "$DAV1D_PREFIX")"

# Git for Windows' /usr/bin/link (coreutils) shadows MSVC's link.exe, which meson rejects. Put
# the directory of cl.exe, where MSVC's link.exe lives, first.
msvc_bin="$(dirname "$(command -v cl)")"
export PATH="$msvc_bin:$PATH"
echo "-- link: $(command -v link)"

# The DLL runtime (/MD) matches the rest of the package's MSVC build. dav1d's AArch64 assembly is
# assembled with armasm64 through gas-preprocessor, which install-tools puts on PATH.
python -m mesonbuild.mesonmain setup "$DAV1D_SRC/build" "$DAV1D_SRC" \
	--buildtype=release \
	--default-library=static \
	--prefix="$prefix" \
	--libdir=lib \
	-Db_vscrt=md \
	-Denable_tools=false \
	-Denable_tests=false \
	-Denable_examples=false

python -m ninja -C "$DAV1D_SRC/build" install

# Meson names a static MSVC library libdav1d.a, but FFmpeg's MSVC toolchain links -ldav1d as
# dav1d.lib.
cp "$DAV1D_PREFIX/lib/libdav1d.a" "$DAV1D_PREFIX/lib/dav1d.lib"

echo "-- dav1d: $(PKG_CONFIG_PATH="$DAV1D_PREFIX/lib/pkgconfig" pkg-config --modversion dav1d)"

_end
