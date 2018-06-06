#!/bin/bash
#
# This build script is licensed under CC0 1.0 Universal:
# https://creativecommons.org/publicdomain/zero/1.0/

set -euo pipefail

export DIR
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../_common.sh"

# Download and extract Mono builds for Windows from GitLab artifacts
curl "https://gitlab.com/Calinou/godot-builds-ci/-/jobs/artifacts/master/raw/mono-windows-x86_64.tar.xz?job=dependency:mono_windows" | tar xfJ -
curl "https://gitlab.com/Calinou/godot-builds-ci/-/jobs/artifacts/master/raw/mono-windows-x86.tar.xz?job=dependency:mono_windows" | tar xfJ -
export MONO64_PREFIX; MONO64_PREFIX="$(pwd)/mono-windows-x86_64"
export MONO32_PREFIX; MONO32_PREFIX="$(pwd)/mono-windows-x86"

# Build Windows editor
for bits in "64" "32"; do
  for mono in "yes" "no"; do
    scons platform=windows \
          bits=$bits \
          tools=yes \
          target=release_debug \
          module_mono_enabled=$mono \
          use_lto=yes \
          $SCONS_FLAGS
  done
done

# Strip binaries of any debug symbols to decrease file size
strip bin/godot.*.exe

# Install InnoSetup
curl -o "$CI_PROJECT_DIR/innosetup.zip" "https://archive.hugo.pro/.public/godot-builds/innosetup-5.5.9-unicode.zip"
unzip -q "$CI_PROJECT_DIR/innosetup.zip" -d "$CI_PROJECT_DIR/"
rm "$CI_PROJECT_DIR/innosetup.zip"
export ISCC="$CI_PROJECT_DIR/innosetup/ISCC.exe"

# Create Windows editor installers and ZIP archives
cd "$GODOT_DIR/bin/"
cp "$CI_PROJECT_DIR/resources/godot.iss" "godot.iss"

mv "godot.windows.opt.tools.64.exe" "godot.exe"
zip -r9 "godot-windows-nightly-x86_64.zip" "godot.exe"
wine "$ISCC" "godot.iss"
rm "godot.exe"

mv "godot.windows.opt.tools.32.exe" "godot.exe"
zip -r9 "godot-windows-nightly-x86.zip" "godot.exe"
wine "$ISCC" "godot.iss" /DApp32Bit
rm "godot.exe"

mv "godot.windows.opt.tools.64.mono.exe" "godot.exe"
zip -r9 "godot-windows-nightly-mono-x86_64.zip" "godot.exe"
wine "$ISCC" "godot.iss" /DAppWithMono
rm "godot.exe"

mv "godot.windows.opt.tools.32.mono.exe" "godot.exe"
zip -r9 "godot-windows-nightly-mono-x86.zip" "godot.exe"
wine "$ISCC" "godot.iss" /DAppWithMono /DApp32Bit
rm "godot.exe"

# Move build products to the artifacts directory
mv \
    godot-windows-nightly-*.zip \
    Output/godot-setup-nightly-*.exe \
    "$ARTIFACTS_DIR/editor/"
