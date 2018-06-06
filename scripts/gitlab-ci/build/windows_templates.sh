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

# Build Windows export templates
for target in "release_debug" "release"; do
  for mono in "yes" "no"; do
    scons platform=windows \
          bits=64 \
          tools=no \
          target=$target \
          module_mono_enabled=$mono \
          use_lto=yes \
          $SCONS_FLAGS
  done
done

# Strip binaries of any debug symbols to decrease file size
strip bin/godot.*.exe

# Create Windows non-Mono export templates TPZ
# We're short on build times, so pretend 64-bit binaries are 32-bit binaries
# to avoid errors in the editor's Export dialog
mkdir -p "templates/"
cp "$CI_PROJECT_DIR/resources/version.txt" "templates/version.txt"
cp "bin/godot.windows.opt.debug.64.exe" "templates/windows_64_debug.exe"
mv "bin/godot.windows.opt.debug.64.exe" "templates/windows_32_debug.exe"
cp "bin/godot.windows.opt.64.exe" "templates/windows_64_release.exe"
mv "bin/godot.windows.opt.64.exe" "templates/windows_32_release.exe"

zip -r9 "$ARTIFACTS_DIR/templates/godot-templates-windows-nightly.tpz" "templates/"

# Create Windows Mono export templates TPZ
rm -rf "templates/"
mkdir -p "templates/"
cp "$CI_PROJECT_DIR/resources/version.mono.txt" "templates/version.txt"
cp "bin/godot.windows.opt.debug.64.mono.exe" "templates/windows_64_debug.exe"
mv "bin/godot.windows.opt.debug.64.mono.exe" "templates/windows_32_debug.exe"
cp "bin/godot.windows.opt.64.mono.exe" "templates/windows_64_release.exe"
mv "bin/godot.windows.opt.64.mono.exe" "templates/windows_32_release.exe"

zip -r9 "$ARTIFACTS_DIR/templates/godot-templates-windows-nightly-mono.tpz" "templates/"
