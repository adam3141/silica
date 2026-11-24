#!/usr/bin/env bash
# Runs once inside the container after it is created.
set -euo pipefail

cd "$(dirname "$0")/.."

git submodule update --init --recursive

# The ccache and Claude volumes are created by root; hand them to the container user.
sudo chown -R "$(id -u):$(id -g)" "${HOME}/.cache/ccache" "${HOME}/.claude" 2>/dev/null || true

echo "Toolchain:"
g++ --version | head -n 1
clangd --version | head -n 1
clang-tidy --version | grep -m 1 version
clang-format --version
cmake --version | head -n 1
