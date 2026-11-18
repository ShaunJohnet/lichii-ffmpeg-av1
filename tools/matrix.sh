#!/bin/sh -e

# Generate build matrix

target() {
    printf '{"runs-on": "%s", "arch": "%s", "platform": "%s", "container": "%s"}' "$1" "$2" "$3" "$4"
}

first=1
add() {
    [ "$first" -eq 1 ] && first=0 || printf ','
    target "$1" "$2" "$3" "$4"
}

printf '['

# Only the platform Lichii has no AV1 FFmpeg for: Windows on ARM64 (MSVC). x64 Windows and Linux
# use Takoroka/ffmpeg-av1, and other platforms crueter-ci/FFmpeg.
add windows-11-arm aarch64 windows

echo ']'