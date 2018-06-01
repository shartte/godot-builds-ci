#!/bin/bash
#
# This build script is licensed under CC0 1.0 Universal:
# https://creativecommons.org/publicdomain/zero/1.0/

set -euo pipefail

export DIR
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../_common.sh"

# Use recent GCC provided by the Ubuntu Toolchain PPA
export CC="gcc-8"
export CXX="g++-8"

# Build Linux editor
for mono in "yes" "no"; do
  scons platform=x11 \
        tools=yes \
        target=release_debug \
        module_mono_enabled=$mono \
        use_static_cpp=yes \
        LINKFLAGS="-fuse-ld=gold" \
        $SCONS_FLAGS
done

# Strip binaries of any debug symbols to decrease file size
strip bin/godot.*

# Create Linux editor AppImage
mkdir -p "appdir/usr/bin/" "appdir/usr/share/icons"
cp "bin/godot.x11.opt.tools.64" "appdir/usr/bin/godot"
cp "misc/dist/appimage/godot.desktop" "appdir/godot.desktop"
cp "icon.svg" "appdir/usr/share/icons/godot.svg"
wget -q "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
chmod +x "linuxdeployqt-continuous-x86_64.AppImage"
./linuxdeployqt-continuous-x86_64.AppImage --appimage-extract
./squashfs-root/AppRun "appdir/godot.desktop" -appimage
mv "Godot_Engine-x86_64.AppImage" "$ARTIFACTS_DIR/editor/godot-linux-nightly-x86_64.AppImage"

# Create Linux editor AppImage (with Mono)
cp "bin/godot.x11.opt.tools.64.mono" "appdir/usr/bin/godot"
cp "bin/GodotSharpTools.dll" "bin/libmonosgen-2.0.so" "bin/mscorlib.dll" "appdir/usr/bin/"
./squashfs-root/AppRun "appdir/godot.desktop" -appimage
mv "Godot_Engine-x86_64.AppImage" "$ARTIFACTS_DIR/editor/godot-linux-nightly-mono-x86_64.AppImage"
