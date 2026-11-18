#!/bin/sh -e

set -e

# shellcheck disable=SC1091

. tools/common.sh

ROOTDIR="$PWD"

copy_build_artifacts() {
	_group "Copying build artifacts"

	make install -C "$DIRECTORY"
	rm -rf out/share out/lib/pkgconfig

	# Merge libdav1d into avcodec.lib so the package's CMakeLists.txt needs no extra library.
	if msvc; then
		avcodec="$(cygpath -w out/lib/avcodec.lib)"
		dav1d="$(cygpath -w "$ROOTDIR/dav1d-install/lib/dav1d.lib")"
		MSYS_NO_PATHCONV=1 lib.exe -nologo "-out:$avcodec" "$avcodec" "$dav1d"

		mkdir -p out/licenses
		cp "$ROOTDIR"/dav1d-[0-9]*/COPYING out/licenses/dav1d-COPYING
		cp "$DIRECTORY"/COPYING.LGPLv2.1 out/licenses/FFmpeg-COPYING.LGPLv2.1
	fi

	_end
}

copy_build_artifacts
copy_cmake
package

echo "-- Done! Artifacts are in $ROOTDIR/artifacts, raw lib/include data is in out"