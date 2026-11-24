#!/usr/bin/env bash
# Runs clang-tidy over the workspace with the flags GCC-built compile databases need under clang.
#   tools/tidy.sh [build-dir] [file-regex] [extra run-clang-tidy args...]
# Example: tools/tidy.sh build/debug 'flint/src/.*' -fix
set -euo pipefail
cd "$(dirname "$0")/.."
build="${1:-build/debug}"
files="${2:-(flint|agate|opal)/(src|tools|examples|tests|demos)/.*\.cpp}"
shift $(( $# > 2 ? 2 : $# ))
exec run-clang-tidy -p "${build}" -quiet -j "$(nproc)" \
  -extra-arg=-Wno-unknown-warning-option \
  -extra-arg=-DFLINT_REFLECTION_TOOLING_STUBS \
  -removed-arg=-freflection \
  "$@" "${files}"
