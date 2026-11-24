#!/usr/bin/env bash
# Runs every time the container starts.
set -euo pipefail

# GPU access. Docker copies /dev/dri into the container with the host's owners: root, plus the host's `video` and
# `render` group ids, which do not match any group the vscode user is in. Without access to the render node, NVIDIA's
# Wayland EGL fails to initialise and EGL falls back to Mesa's software renderer, which cannot create the OpenGL 4.6
# context agate needs (EGL_BAD_MATCH). These are the container's own copies of the device nodes, so changing them does
# not affect the host.
if compgen -G "/dev/dri/*" >/dev/null; then
  sudo chmod a+rw /dev/dri/card* /dev/dri/renderD* 2>/dev/null || true
fi

# Shader caches (Mesa, NVIDIA) live in ~/.cache.
sudo chown "$(id -u):$(id -g)" "${HOME}/.cache" 2>/dev/null || true
