# 0002. Development happens in an Ubuntu 26.04 dev container

- Status: Accepted
- Date: 2026-11-24

## Context

The host machine does not have the toolchain installed: GCC 16 for reflection, the latest LLVM tooling, and the SDL3 and OpenGL development headers. GUI applications must still run on the host display, preferably with GPU acceleration, and an AI assistant needs to be able to see and drive the UI.

## Decision

- Use a VS Code dev container based on `mcr.microsoft.com/devcontainers/base:ubuntu26.04` (non-root `vscode` user).
- Install GCC 16 from the Ubuntu archive, and LLVM 23 clangd, clang-tidy and clang-format from apt.llvm.org (the newest release; Ubuntu ships 21 and 22).
- Pass through X11, Wayland, the GPU (NVIDIA via `hostRequirements.gpu: optional`, Mesa via `/dev/dri`) and the host time zone.
- Include Xvfb, xdotool and ImageMagick for headless screenshots and input automation, and build the Tracy profiler GUI into the image.
- The full details are in [dev-environment.md](../architecture/dev-environment.md).

## Consequences

- One image defines the toolchain for everyone, including CI later.
- `--device=/dev/dri` requires the host to have DRM devices. On hosts without them (some cloud VMs), remove it from `runArgs`.
- `xhost +SI:localuser:<user>` is run on the host by `initializeCommand`. It grants X access only to processes with the same uid.
