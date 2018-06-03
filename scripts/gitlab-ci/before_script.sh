#!/bin/bash
#
# This build script is licensed under CC0 1.0 Universal:
# https://creativecommons.org/publicdomain/zero/1.0/

set -euo pipefail

export DIR
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/_common.sh"

# Install dependencies
if [[ -f "/etc/redhat-release" ]]; then
  # Fedora
  rpm --import "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
  curl "https://download.mono-project.com/repo/centos7-stable.repo" | tee "/etc/yum.repos.d/mono-centos7-stable.repo"
  dnf update -y

  dnf install -y \
      git cmake scons pkgconfig gcc-c++ curl libxml2-devel libX11-devel \
      libXcursor-devel libXrandr-devel libXinerama-devel mesa-libGL-devel \
      alsa-lib-devel pulseaudio-libs-devel freetype-devel \
      libudev-devel mesa-libGLU-devel mingw32-gcc-c++ mingw64-gcc-c++ \
      mingw32-winpthreads-static mingw64-winpthreads-static yasm \
      wget zip unzip ncurses-compat-libs wine xz openssh-clients make which \
      mono-devel
else
  # Ubuntu
  apt-key adv --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys "3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
  apt-get update -yqq
  apt install -y apt-transport-https
  echo "deb https://download.mono-project.com/repo/ubuntu stable-trusty main" | tee "/etc/apt/sources.list.d/mono-official-stable.list"

  apt-get install -yqq software-properties-common
  add-apt-repository -y ppa:ubuntu-toolchain-r/test
  apt-get update -yqq

  apt-get install -y \
      git cmake wget zip unzip build-essential scons pkg-config \
      libx11-dev libxcursor-dev libxinerama-dev libgl1-mesa-dev \
      libglu-dev libasound2-dev libpulse-dev libfreetype6-dev \
      libssl-dev libudev-dev libxrandr-dev libxi-dev yasm \
      gcc-8 g++-8 mono-devel
fi

# Prepare build directories
# Changing into the build directory is done in `.gitlab-ci.yml`, not here
if [[ "$BUILD_MONO_LIBRARY" == "yes" ]]; then
  # Build only Mono
  wget -q "$MONO_SOURCE_TARBALL_URL"
  tar xf ./*.tar.bz2
  mv mono-*/ "mono/"
else
  # Build Godot
  git clone --depth=1 "$GODOT_REPO_URL"
  mkdir -p "$ARTIFACTS_DIR/editor" "$ARTIFACTS_DIR/templates"

  # Copy user-supplied modules into the Godot directory
  # (don't fail in case no modules are present)
  cp $CI_PROJECT_DIR/modules/* "$GODOT_DIR/modules/" || true

  # Download the generated Mono glue from the last successful `generate:mono_glue` job
  wget \
      -q "https://gitlab.com/Calinou/godot-builds-ci/-/jobs/artifacts/master/raw/mono_glue.gen.cpp?job=generate:mono_glue" \
      -O "$GODOT_DIR/modules/mono/glue/mono_glue.gen.cpp"
fi
