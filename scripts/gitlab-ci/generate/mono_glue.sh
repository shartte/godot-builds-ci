#!/bin/bash
#
# This build script is licensed under CC0 1.0 Universal:
# https://creativecommons.org/publicdomain/zero/1.0/

set -euo pipefail

export DIR
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/../_common.sh"


# Build Linux editor (only used to generate the Mono glue)
scons platform=x11 \
      module_mono_enabled=yes \
      mono_glue=no \
      use_static_cpp=yes \
      LINKFLAGS="-fuse-ld=gold" \
      $SCONS_FLAGS

# Generate Mono glue
bin/godot.x11.tools.64.mono --generate-mono-glue "../../"
