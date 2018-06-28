#!/bin/bash
#
# This build script is licensed under CC0 1.0 Universal:
# https://creativecommons.org/publicdomain/zero/1.0/

set -euo pipefail

export DIR
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../_common.sh"

# Setup Flatpak for building
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.freedesktop.Platform//1.6 org.freedesktop.Sdk//1.6
git clone --depth=1 "https://github.com/flathub/shared-modules.git"
wget -O "org.godotengine.Godot.png" "https://github.com/godotengine/godot/raw/master/icon.png"

# Build Linux editor Flatpak
flatpak-builder -y --repo="$ARTIFACTS_DIR/flatpak/" "build" "org.godotengine.Godot.json"
