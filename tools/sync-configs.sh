#!/usr/bin/env bash
# Copies the workspace's formatting and lint configuration into each library, so each repository also works when it is
# cloned on its own. The copies in silica's root are the source of truth.
#   tools/sync-configs.sh          copy
#   tools/sync-configs.sh --check  fail if any copy differs (for CI)
set -euo pipefail
cd "$(dirname "$0")/.."
status=0
for repo in flint agate opal; do
  [ -d "${repo}" ] || continue
  for file in .clang-format .clang-tidy .clangd; do
    if [ "${1:-}" = "--check" ]; then
      cmp -s "${file}" "${repo}/${file}" || { echo "${repo}/${file} differs from ${file}"; status=1; }
    else
      cp "${file}" "${repo}/${file}"
    fi
  done
done
exit ${status}
