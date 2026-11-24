# CLAUDE.md

Guidance for Claude Code sessions in the silica workspace. Read this first, then the `TASKS.md` of whichever project you are working on.

## What this is

silica is an umbrella repository with three submodules:

- **flint**: the foundation library (no UI).
- **agate**: a WPF-style UI library on SDL3 and OpenGL.
- **opal**: a programming editor on agate, not started.

The owner's original brief is in `docs/brief.md`. Work on flint and agate first; opal comes after agate's UI model is settled.

## Where things stand (update this section at the end of each session)

_Last updated: 2026-11-24, end of session 1. flint#1, agate#1, agate#3, agate#4 and silica#1 are merged to `main`._

### Done

- **Workspace** (silica#1): dev container (Ubuntu 26.04, GCC 16, LLVM 23, SDL3 deps, Tracy 0.15), shared `.clang-format`, `.clang-tidy` and `.clangd`, `tools/tidy.sh`, `tools/sync-configs.sh`, root CMake and presets (`debug`, `release`, `profile`, `asan`), ADRs 0001–0005, coding guide updated for C++26 and British spelling. Dev container GPU fix: `.devcontainer/post-start.sh` opens `/dev/dri` to `vscode` (VS Code starts the container as root, so the NVIDIA render node was unreadable and EGL fell back to Mesa → `EGL_BAD_MATCH`).
- **flint** (flint#1): logger (standard and custom severity levels, categories and channels, per-sink filters, async with synchronous Fatal flush, console/file/JSON Lines/TCP/Tracy/callback sinks, JSON config with JSON Pointer errors), `flint-logcat`, `flint::json`, `flint::bench` and `FLINT_PROFILE_*`, `flint::meta` enum reflection, platform, net, text. 64 tests. ADRs 0001–0008.
- **agate design** (agate#1): ADRs 0001–0014 — near-XAML markup, runtime loading with hot reload, MVVM with `Find<T>(name)`, visual states, own SDF GPU renderer, FreeType + HarfBuzz, DIPs with per-monitor scale, themes as resource dictionaries, OpenGL 4.6 core, mineral themes × Dark/Light, UI thread + Dispatcher, bundled Inter and JetBrains Mono, sRGB blending, on-demand rendering.
- **agate milestone 1** (agate#3): SDL3 `Application`/`Window`, `GlRenderer` (one instanced draw per frame, SDF shapes, shadows and glow, gradients, clips), text, frame overlay (F12), headless harness (SDL offscreen + EGL, input scripts, PNG capture), `agate_render_demo`. 24 tests including GPU pixel tests. Clean under clang-tidy, ASan and UBSan.

### Owner feedback on the milestone 1 demo (recorded in agate/TASKS.md, agate#4)

- Glow and toggle timing are good. **Timings and easing must come from style/theme markup, not C++** (ADR-0004 `VisualTransition`); defaults: toggle 180 ms CubicOut, hover 140 ms CubicOut.
- No title bar is fine; the owner wants **window chrome declarable in markup** later.
- The owner approved the PRs and accepted tests/demos disabling `readability-magic-numbers` (tests also disable `bugprone-unchecked-optional-access` and `misc-non-private-member-variables-in-classes`). Still unanswered: should Fatal optionally terminate the process?

### Next

1. **Ask whether the VS Code dev container now works** after "Dev Containers: Rebuild Container". The owner reported it not working at the end of session 1 but had no time to paste the errors; the fix was verified only with a container started like VS Code's, not by VS Code itself. If it still fails, ask for the demo output, `eglinfo -B` and `ls -ln /dev/dri` from inside the container. Meanwhile the owner runs demos from the host with `docker exec -it silica-claude bash -c 'cd /workspaces/silica && build/debug/agate/demos/agate_render_demo'`.
2. **agate milestone 2**: DependencyObject and the property system, element tree, Measure and Arrange, panels (StackPanel, Grid, DockPanel, Canvas), routed input, hit testing, focus. **Ask the owner about the property-system shape first** (how properties are declared and whether reflection generates registration; how view models expose observable properties; value precedence; attached properties). Then build, demo, and get feedback.
3. Then milestones 3 to 5 per `agate/TASKS.md` (controls, styles and themes; markup and binding; animation). opal starts after that.

## Working agreements (from the owner)

- **Ask, don't guess.** Ask design questions a few at a time (three or four per round). Do not invent product decisions. Record each decision as an ADR in the right library.
- **Follow `docs/architecture/coding-style.md`.** clang-format and clang-tidy (`tools/tidy.sh`) must be clean. Every public declaration gets a `///` comment. Errors are `std::expected`.
- **Non-UI code goes in flint.** flint must stay usable by command-line tools, services, other GUI apps and games.
- **Cross-platform later**, for both OS and graphics API: keep platform and GL code behind interfaces.
- **Performance matters**: UI must be fluid. Use `FLINT_PROFILE_*` (Tracy) and `flint::bench`.
- **Demos**: at milestones, give the owner something to run and ask for feedback.
- **Git**: the initial scaffold went to `main`. Since then every change, docs included, goes on a branch (`feature/<name>`, `docs/<name>`) with a PR; direct pushes to `main` are blocked. Ask the owner before merging a PR (blanket merge approval was given only for the session 1 PRs). After a submodule PR merges, bump the pointer in silica via a PR. Don't stack PRs on branches that `--delete-branch` removes: GitHub closes the dependent PR (this happened to agate#2, replaced by agate#3).
- **Docs**: keep `docs/architecture.md`, `docs/api/`, `docs/adr/` and `TASKS.md` current in each repository. opal's design will be based on agate's API docs.

## Toolchain facts that matter

- GCC 16 (`-freflection`) is the only compiler with C++26 reflection. clangd and clang-tidy (LLVM 23) cannot parse it.
  - Reflection syntax lives **only** in `*/meta/detail/*_impl.hpp`. `flint/meta/reflection.hpp` gives clang tooling stub bodies when `FLINT_REFLECTION_TOOLING_STUBS` is defined (`.clangd` and `tools/tidy.sh` define it). Never use meta functions in `static_assert` outside the meta headers. See flint ADR-0003.
- GCC 16's `-Wshadow` warns when a scoped enumerator has the same name as a type alias in an enclosing scope (for example `Kind::Array` and `json::Array`). Declare the enum first, or rename.
- clang rejects incomplete-type uses that GCC accepts. When several types refer to each other, define constructors after every type is complete (see `flint/json/value.hpp`).
- `misc-include-cleaner` only sees the active preprocessor branch. Check `#ifdef` platform and Tracy blocks by hand after `-fix`.

## Commands (inside the dev container, from the silica root)

```bash
cmake --preset debug && cmake --build --preset debug && ctest --preset debug
cmake --preset asan && cmake --build --preset asan && ctest --preset asan
cmake --preset profile && cmake --build --preset profile        # Tracy; then run tracy-profiler
tools/tidy.sh build/debug 'flint/.*\.cpp'                        # clang-tidy, must print no warnings
find flint agate \( -name '*.cpp' -o -name '*.hpp' \) | xargs clang-format -i
tools/sync-configs.sh                                            # after editing the root .clang-format, .clang-tidy or .clangd
```

## Driving the container from the host (when Claude runs outside it)

The host has no toolchain. Build the image (`docker build -t silica-dev .devcontainer`), then start a long-lived container:

```bash
docker run -d --name silica-claude --gpus all --device /dev/dri --ipc=host \
  -v /home/adam/Development/silica:/workspaces/silica -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /run/user/1000:/run/host-runtime -v silica-ccache:/home/vscode/.cache/ccache -v /etc/localtime:/etc/localtime:ro \
  -e DISPLAY=:0 -e WAYLAND_DISPLAY=wayland-0 -e XDG_RUNTIME_DIR=/run/host-runtime -e NVIDIA_DRIVER_CAPABILITIES=all \
  -u vscode -w /workspaces/silica silica-dev sleep infinity
docker exec silica-claude bash -c '<command>'
```

To see the UI without touching the owner's desktop, run agate demos with `--headless --script "...; shot /tmp/x.png"` (GPU, EGL surfaceless), then `docker cp` the PNG out and view it. Xvfb cannot run agate (llvmpipe stops at GL 4.5). See `docs/architecture/dev-environment.md`.

Decisions the owner has made beyond the ADRs: British spelling everywhere (silica ADR-0005); demos and tests may disable `readability-magic-numbers`.
