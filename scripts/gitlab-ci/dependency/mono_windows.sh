#!/bin/bash
#
# This build script is licensed under CC0 1.0 Universal:
# https://creativecommons.org/publicdomain/zero/1.0/

set -euo pipefail

export DIR
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../_common.sh"

# Disable Boehm GC since it's not used in Godot
CONFIGURE_FLAGS="--disable-boehm"
BUILD_THREADS="$(($(nproc) * 2))"

# Compile Mono for Linux first to build other files required by Windows packages
./configure --prefix="$(pwd)/mono-linux" $CONFIGURE_FLAGS
make -j$BUILD_THREADS
make install
make distclean
cp -r "mono-linux/" "mono-windows-x86_64/"
cp -r "mono-linux/" "mono-windows-x86/"

# 64-bit Windows
./configure --prefix="$(pwd)/mono-windows-x86_64" --host=x86_64-w64-mingw32 $CONFIGURE_FLAGS
make -j$BUILD_THREADS || true
make install -i

# 32-bit Windows
./configure --prefix="$(pwd)/mono-windows-x86" --host=i686-w64-mingw32 $CONFIGURE_FLAGS
make -j$BUILD_THREADS || true
make install -i

# Create Mono Windows packages
# Those will be uploaded as artifacts on GitLab
tar cJf "$CI_PROJECT_DIR/mono-windows-x86_64.tar.xz" "mono-windows-x86_64"
tar cJf "$CI_PROJECT_DIR/mono-windows-x86.tar.xz" "mono-windows-x86"
