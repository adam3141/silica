# Development environment

The host needs only Docker (with the NVIDIA container toolkit for GPU access) and VS Code with the Dev Containers extension. Everything else is in the container.

## The container

`.devcontainer/Dockerfile` builds on `mcr.microsoft.com/devcontainers/base:ubuntu26.04`, which provides the non-root `vscode` user, and adds:

| Group | Packages |
|---|---|
| Compiler | `gcc-16` and `g++-16` (default `gcc`/`g++`/`cc`/`c++` via alternatives), `gdb`, `ccache` |
| LLVM tooling | `clangd-23`, `clang-tidy-23`, `clang-format-23`, `clang-tools-23` from apt.llvm.org, linked to the unversioned names |
| Build | `cmake`, `ninja-build`, `pkg-config`, `git`, `git-lfs`, `python3` |
| SDL3 and OpenGL build dependencies | X11, Wayland, libdecor, xkbcommon, EGL, GL, GLES, DRM, GBM, ALSA, PulseAudio, PipeWire, D-Bus, udev, FreeType, HarfBuzz, fontconfig headers |
| Runtime graphics | Mesa (GL, EGL, Vulkan), `mesa-utils` (`glxinfo`, `eglinfo`). No libdecor plugin: see Known issues |
| Fonts | DejaVu, Noto, JetBrains Mono |
| Headless and screenshot tools | `xvfb`, `xdotool`, `imagemagick`, `x11-apps` (`xwd`), `x11-utils`, `wmctrl`, `openbox`, `weston` (agate itself renders headless with `--headless`; see below) |
| Profiler | `tracy-profiler` 0.15.0, built from source |

VS Code extensions: `llvm-vs-code-extensions.vscode-clangd`, `Anthropic.claude-code`, `ms-vscode.cpptools` (debugger only; IntelliSense disabled) and `ms-vscode.cmake-tools`.

clangd reads `build/debug/compile_commands.json`, and uses `--query-driver` to pick up GCC 16's standard library headers. `.clangd` removes GCC-only flags and defines `FLINT_REFLECTION_TOOLING_STUBS` (flint ADR-0003).

## GUI applications

| What | How |
|---|---|
| X11 / XWayland | `/tmp/.X11-unix` is bind-mounted and `DISPLAY` is passed through. `initializeCommand` runs `.devcontainer/initialize.sh` on the host, which runs `xhost +SI:localuser:$USER`, so the container's `vscode` user (same uid) may connect |
| Wayland | The host's `XDG_RUNTIME_DIR` is mounted at `/run/host-runtime` and `WAYLAND_DISPLAY` is passed through. SDL3 prefers Wayland when it is available; set `SDL_VIDEO_DRIVER=x11` to force X11 |
| GPU device access | `.devcontainer/post-start.sh` opens the container's copies of `/dev/dri/card*` and `renderD*` to the `vscode` user on every start. VS Code creates the container as root, so the nodes keep the host's root owner and host-specific `video`/`render` group ids. Without this, NVIDIA's Wayland EGL cannot open the render node and EGL falls back to Mesa, which cannot create a GL 4.6 context (`EGL_BAD_MATCH`) |
| GPU | `hostRequirements.gpu: optional` adds `--gpus all` when the host has an NVIDIA GPU (container toolkit required), with `NVIDIA_DRIVER_CAPABILITIES=all`. `/dev/dri` is passed for Mesa GPUs. Without a GPU, Mesa's llvmpipe renders in software |
| Shared memory | `--ipc=host` lets X11's MIT-SHM work |
| Debugging | `SYS_PTRACE` and `seccomp=unconfined` for gdb |
| Time zone | `initialize.sh` writes the host's zone name (for example `Australia/Sydney`) to `.devcontainer/.host-timezone` (git-ignored), and `post-start.sh` points `/etc/localtime` at it. `/etc/localtime` is not bind-mounted: the container's copy is a symlink to `Etc/UTC`, so a mount overwrites the UTC zone file, and `std::chrono::current_zone()`, which flint uses for log timestamps, still reports UTC |

Check: `glxinfo -B` inside the container should report the host GPU. On the reference machine it shows "NVIDIA RTX 4000 SFF Ada Generation, OpenGL 4.6".

## Headless runs (screenshots and automation)

agate needs OpenGL 4.6 (agate ADR-0009). Mesa's software renderer under Xvfb stops at 4.5, so **agate renders headless on the GPU** instead, through SDL3's offscreen driver and EGL surfaceless. No display server is involved:

```bash
build/debug/agate/demos/agate_render_demo --headless --script "wait 2; move 300 300; wait 15; shot /tmp/demo.png"
```

Scripts can move the pointer, click, press keys, wait for frames and take screenshots (see agate's `docs/api/testing.md`). Xvfb, xdotool and ImageMagick remain in the image for non-agate tools and for post-processing screenshots (`convert`, `identify`).

## Known issues

- **No title bar on GNOME Wayland.** GNOME leaves window decorations to the client, and SDL3 draws them through a libdecor plugin. The image installs none, so libdecor prints `No plugins found, falling back on no decorations`, which is harmless. The GTK plugin (`libdecor-0-plugin-1-gtk`) aborts the app in a container: GTK loads its icons through glycin, which sandboxes its loaders with bubblewrap, and bubblewrap cannot create namespaces under Docker's default AppArmor profile (`bwrap: Failed to make / slave: Permission denied`). agate will draw its own window chrome, declared in markup.
- **X11 from the container on NVIDIA is slow.** GLX over XWayland presents at about 2 fps (`glxgears` shows the same), because the driver's explicit-sync waits time out inside the container. SDL3 picks **Wayland** by default, which runs at full speed with vsync, so this only matters if you force `SDL_VIDEO_DRIVER=x11`. It is tracked in agate's TASKS.md.

## Volumes

| Volume | Mounted at | Why |
|---|---|---|
| `silica-ccache` | `~/.cache/ccache` | Keeps compile cache across container rebuilds |
| `silica-claude` | `~/.claude` | Keeps the Claude Code login and settings |

## Without VS Code

The same container can be run directly:

```bash
docker build -t silica-dev .devcontainer
.devcontainer/initialize.sh          # X11 access and the host time zone
docker run -it --rm --gpus all --device /dev/dri --ipc=host \
  -v "$PWD":/workspaces/silica -v /tmp/.X11-unix:/tmp/.X11-unix -v "$XDG_RUNTIME_DIR":/run/host-runtime \
  -e DISPLAY -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR=/run/host-runtime -e NVIDIA_DRIVER_CAPABILITIES=all \
  -u vscode -w /workspaces/silica silica-dev bash -c '.devcontainer/post-start.sh && exec bash'
```
