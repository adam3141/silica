# CLAUDE.md

Guidance for Claude Code sessions in the silica workspace. Read this first, then the `TASKS.md` of whichever project you are working on.

## What this is

silica is an umbrella repository with three submodules:

- **flint**: the foundation library (no UI).
- **agate**: a WPF-style UI library on SDL3 and OpenGL.
- **opal**: a programming editor on agate, not started.

The owner's original brief is in `docs/brief.md`. Work on flint and agate first; opal comes after agate's UI model is settled.

## Where things stand (update this section at the end of each session)

_Last updated: 2026-11-24 (end of session 1)_

- **Workspace**: dev container, tooling configs, root CMake and presets, and docs are done. See `TASKS.md`.
- **flint**: the foundation is in review in adam3141/flint#1 (branch `feature/foundation`). silica's submodule pointer is still on flint's scaffold commit; bump it after the PR merges. The logger is complete. It has custom levels, categories, console, file, JSON Lines, network and Tracy sinks, and JSON config. Also done: JSON library, bench and profiling, enum reflection, platform and net. There are 64 tests, and clang-tidy and clang-format are clean. The demos are `flint_log_demo`, `flint_bench_demo` and `flint-logcat`. Next steps are in `flint/TASKS.md`.
- **agate**: the design is agreed in ADRs 0001 to 0014 (adam3141/agate#1, branch `feature/design-decisions`). Milestone 1 (SDL3 window, GL 4.6 SDF renderer, HarfBuzz and FreeType text, frame overlay, headless harness, `agate_render_demo`) is in review in adam3141/agate#2 (branch `feature/milestone-1-rendering`). **Next: milestone 2** (DependencyObject and property system, element tree, Measure and Arrange, panels, routed input). Ask the owner about the property-system shape before coding it.
- **opal**: skeleton only.

## Working agreements (from the owner)

- **Ask, don't guess.** Ask design questions a few at a time (three or four per round). Do not invent product decisions. Record each decision as an ADR in the right library.
- **Follow `docs/architecture/coding-style.md`.** clang-format and clang-tidy (`tools/tidy.sh`) must be clean. Every public declaration gets a `///` comment. Errors are `std::expected`.
- **Non-UI code goes in flint.** flint must stay usable by command-line tools, services, other GUI apps and games.
- **Cross-platform later**, for both OS and graphics API: keep platform and GL code behind interfaces.
- **Performance matters**: UI must be fluid. Use `FLINT_PROFILE_*` (Tracy) and `flint::bench`.
- **Demos**: at milestones, give the owner something to run and ask for feedback.
- **Git**: the initial scaffold went to `main`. Since then, each feature goes on a `feature/<name>` branch with a PR. After a submodule PR merges, bump the submodule pointer in silica.
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

Decisions the owner has made beyond the ADRs: British spelling everywhere (silica ADR-0005); demos and tests may disable `readability-magic-numbers` (pending the owner's confirmation in the PRs).
