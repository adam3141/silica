# CLAUDE.md

Guidance for Claude Code sessions in the silica workspace. Read this first, then the `TASKS.md` of whichever project you are working on.

## What this is

silica is an umbrella repository with three submodules:

- **flint**: the foundation library (no UI).
- **agate**: a WPF-style UI library on SDL3 and OpenGL.
- **opal**: a programming editor on agate, not started.

The owner's original brief is in `docs/brief.md`. Work on flint and agate first; opal comes after agate's UI model is settled.

## Where things stand (update this section at the end of each session)

_Last updated: 2026-11-25, session 2. Milestones 2 and 3 are merged (flint#3–#5, agate#5–#6, opal#1, silica#4–#7). The owner has started milestone 4._

### Done

- **Workspace** (silica#1): dev container (Ubuntu 26.04, GCC 16, LLVM 23, SDL3 deps, Tracy 0.15), shared `.clang-format`, `.clang-tidy` and `.clangd`, `tools/tidy.sh`, `tools/sync-configs.sh`, root CMake and presets (`debug`, `release`, `profile`, `asan`), ADRs 0001–0005, coding guide updated for C++26 and British spelling. Dev container GPU fix: `.devcontainer/post-start.sh` opens `/dev/dri` to `vscode` (VS Code starts the container as root, so the NVIDIA render node was unreadable and EGL fell back to Mesa → `EGL_BAD_MATCH`).
- **flint** (flint#1): logger (standard and custom severity levels, categories and channels, per-sink filters, async with synchronous Fatal flush, console/file/JSON Lines/TCP/Tracy/callback sinks, JSON config with JSON Pointer errors), `flint-logcat`, `flint::json`, `flint::bench` and `FLINT_PROFILE_*`, `flint::meta` enum reflection, platform, net, text. 64 tests. ADRs 0001–0008.
- **agate design** (agate#1): ADRs 0001–0014 — near-XAML markup, runtime loading with hot reload, MVVM with `Find<T>(name)`, visual states, own SDF GPU renderer, FreeType + HarfBuzz, DIPs with per-monitor scale, themes as resource dictionaries, OpenGL 4.6 core, mineral themes × Dark/Light, UI thread + Dispatcher, bundled Inter and JetBrains Mono, sRGB blending, on-demand rendering.
- **Dev container fixes** (silica#3): removed the libdecor GTK plugin (GTK's glycin/bubblewrap sandbox aborted demos under Docker; no title bar on GNOME, accepted); host time zone passed by name (`initialize.sh` → `post-start.sh`) so `std::chrono::current_zone()` is local. The owner confirmed the demo runs in VS Code.
- **agate milestone 1** (agate#3): SDL3 `Application`/`Window`, `GlRenderer` (one instanced draw per frame, SDF shapes, shadows and glow, gradients, clips), text, frame overlay (F12), headless harness (SDL offscreen + EGL, input scripts, PNG capture), `agate_render_demo`. 24 tests including GPU pixel tests. Clean under clang-tidy, ASan and UBSan.

### Owner feedback on the milestone 1 demo (recorded in agate/TASKS.md, agate#4)

- Glow and toggle timing are good. **Timings and easing must come from style/theme markup, not C++** (ADR-0004 `VisualTransition`); defaults: toggle 180 ms CubicOut, hover 140 ms CubicOut.
- No title bar is fine; the owner wants **window chrome declarable in markup** later.
- The owner approved the PRs and accepted tests/demos disabling `readability-magic-numbers` (tests also disable `bugprone-unchecked-optional-access` and `misc-non-private-member-variables-in-classes`). Logging at Fatal must **not** terminate the process (owner decision, 2026-11-25; flint ADR-0004).

- **agate milestone 2** (agate#5, flint#3, silica#5; merged; owner: "looks great so far" from screenshots):
  - flint: `event::Signal` with scoped `Connection`, plus `model::Observable` and `Command` (flint ADR-0009).
  - agate core: `DependencyObject`, `Property<T, Metadata...>` registered by reflection, `ReadOnlyProperty`, `AttachedProperty`; precedence, coercion and inheritance (ADRs 0015 and 0016).
  - Elements: `Visual`, `UIElement` and `FrameworkElement` with cached two-pass layout, plus routed events, hit testing, capture, focus and Tab navigation, all run by `ElementHost` (ADR-0017).
  - Panels and elements: StackPanel, Grid, DockPanel, Canvas, Border, TextBlock, TextElement (ADR-0018). Layout rounding is on by default (ADR-0019).
  - Demos and checks: `agate_layout_demo` (six pages) and `agate_layout_bench`; 77 agate and 89 flint tests. Clean under clang-tidy, ASan and UBSan, and the release build is fixed.
  - Owner decisions this session:
    - reflected member properties, with metadata **in template arguments**, because clang tooling cannot parse `[[=...]]` annotations;
    - WPF precedence with coercion; WPF-style attached properties;
    - `Observable<T>` in flint; parent-owned children (`unique_ptr`); scoped connections; layout rounding on.

- **agate milestone 3** (flint#4, agate#6; merged). Owner decisions this session: bring the XML loader forward from milestone 4; visual-state transitions now (storyboards stay in milestone 5); all four extra controls; window chrome in markup now.
  - **flint**: `flint::xml`, an XML parser with line and column locations (flint ADR-0010).
  - **Markup** (ADR-0020): loader, type registry, resources, `Style`, `ControlTemplate` with visual states, `{StaticResource}`, `{DynamicResource}`, `{TemplateBinding}`, `{x:Null}` and `{x:Type}`.
  - **Precedence correction**: VisualState now ranks above Template (amends ADR-0015). My milestone 2 order would have stopped states from changing template parts; flagged to the owner.
  - **Animation** (ADR-0021): an animation clock with transitions whose timings are theme resources, plus timers.
  - **Controls** (ADR-0022): Button, ToggleSwitch, CheckBox, RadioButton, Slider, ScrollViewer, TextBox and TitleBar.
  - **Themes**: base, dark, light and five minerals in XML (`agate/themes`), `ApplyTheme`, the System variant, animated switching.
  - **Window chrome**: borderless windows with WindowChrome regions, commands and SDL hit testing.
  - **Demo**: `agate_controls_demo` loads `demos/controls_demo.xml`.
  - **Checks**: 95 agate and 96 flint tests. Clean under clang-tidy, ASan and UBSan, and in the release build.

### Milestone 3 interaction check

The owner asked whether the UI can be tested by clicking and dragging. Headless scripts (`--headless --script`, see
`Application::RunScript`) drove the controls demo with clicks, drags, keys, the wheel and theme switches, capturing
frames mid-transition. Hover, press, toggles, radio groups, slider and scroll-bar drags, track clicks, typing, Tab,
Space/Enter and theme fades all behaved. Two bugs were found and fixed (agate#6):

- states set by code before the first frame animated in. Elements now snap until first arranged (`HasBeenArranged`);
- the window background switched instantly on a theme change. It now fades with the theme.

Not testable headlessly: the compositor moving and resizing a real window from the custom title bar. The owner has
not yet confirmed that on GNOME Wayland.

### Next

1. **Milestone 4, first tasks (the owner started milestone 4 on 2026-11-25):** in flint, replace `flint::json` with
   glaze and the hand-written XML parser with pugixml behind the existing `flint::xml` types (flint/TASKS.md). New
   ADRs supersede flint ADR-0005 and ADR-0010. Re-run agate's markup and theme tests afterwards.
2. **agate milestone 4**: binding, view models and hot reload. Ask the owner first, a few questions at a time:
   - binding syntax and modes (OneWay, TwoWay, OneTime);
   - how view models are found: reflection over `flint::model::Observable` members by name;
   - converters;
   - how DataContext flows down the tree;
   - command binding;
   - hot-reload scope (views, themes, both) and file watching (a flint facility).
3. Then milestone 5 (storyboards and keyframes on the existing clock). opal starts after that.

## Working agreements (from the owner)

- **Ask, don't guess.** Ask design questions a few at a time (three or four per round). Do not invent product decisions. Record each decision as an ADR in the right library.
- **Prefer established libraries.** Before writing our own version of a commodity component (parsers, serialisation), offer the owner the established libraries and let them choose.
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
- clang tooling (LLVM 23) cannot parse C++26 annotations (`[[=...]]`), so agate property metadata is template arguments (`Property<T, Affects::Measure, Inherits{}>`; ADR-0015). Do not put annotations in headers.
- GCC 16 reflection quirks (see `agate/core/meta/detail/class_info_impl.hpp`):
  - A pointer to a function template specialised on a `std::meta::info` is consteval-only. Pass a member pointer (`&[:member:]`) as the template argument instead.
  - Bind reflected values to `constexpr` locals before using them in run-time expressions.
  - In a consteval function, a range-for over a temporary `std::vector<info>` fails. Bind the vector to a local first.
- clang (LLVM 23) rejects `std::expected<std::any, E>` built from a `std::any`, and `std::optional<std::expected<std::any, E>>`: its constraint check recurses, while GCC accepts both. Construct with `std::in_place`.
- GCC's `-O3` `-Wnull-dereference` fires on unchecked pointer results in release builds only. Check pointers (`ASSERT_NE` in tests) before dereferencing, and build the release preset before opening a PR.
- Public dependency properties, observables, signals and routed events are PascalCase public members. `.clang-tidy` ignores PascalCase public members and class constants, and review enforces that only those kinds use the exception (coding-style.md sections 4 and 7).

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
  -v /run/user/1000:/run/host-runtime -v silica-ccache:/home/vscode/.cache/ccache \
  -e DISPLAY=:0 -e WAYLAND_DISPLAY=wayland-0 -e XDG_RUNTIME_DIR=/run/host-runtime -e NVIDIA_DRIVER_CAPABILITIES=all \
  -u vscode -w /workspaces/silica silica-dev sleep infinity
docker exec silica-claude .devcontainer/post-start.sh   # GPU device access and time zone (run .devcontainer/initialize.sh on the host first)
docker exec silica-claude bash -c '<command>'
```

To see the UI without touching the owner's desktop, run agate demos with `--headless --script "...; shot /tmp/x.png"` (GPU, EGL surfaceless), then `docker cp` the PNG out and view it. Xvfb cannot run agate (llvmpipe stops at GL 4.5). See `docs/architecture/dev-environment.md`.

Decisions the owner has made beyond the ADRs: British spelling everywhere (silica ADR-0005); demos and tests may disable `readability-magic-numbers`; Fatal never terminates the process (flint ADR-0004).
