# silica workspace architecture

## Layers

```
┌──────────────────────────────────────────────┐
│ opal        programming editor (application) │
├──────────────────────────────────────────────┤
│ agate       UI: markup, styles, templates,   │
│             animation, dependency properties,│
│             binding, panels, themes          │
│             ── backends: SDL3 window/input,  │
│                OpenGL renderer (more later)  │
├──────────────────────────────────────────────┤
│ flint       foundation: log, json, bench,    │
│             profile, meta (reflection),      │
│             platform, net, text              │
├──────────────────────────────────────────────┤
│ C++26 standard library · OS                  │
└──────────────────────────────────────────────┘
```

- Dependencies point downward only. flint knows nothing of agate; agate knows nothing of opal.
- Anything not specific to UI belongs in flint, because flint is also meant for command-line tools and services, other GUI applications, and games and real-time code.
- Platform and graphics specifics sit behind interfaces at the edges (`flint/platform`, agate's windowing and rendering backends), so Windows, macOS and other graphics APIs (Vulkan, Metal, D3D) can be added without touching the core.

## Repositories

silica is the umbrella repository. flint, agate and opal are separate repositories, included as git submodules with relative URLs (`../flint.git`), so they follow whatever protocol silica was cloned with. See ADR-0001.

The root `CMakeLists.txt` adds each library with `add_subdirectory`, so one build tree compiles the whole family and a change to flint is seen by agate at once. Each library also builds on its own.

## Shared conventions

- [coding-style.md](coding-style.md) governs all code. `.clang-format`, `.clang-tidy` and `.clangd` at the silica root are the source of truth; `tools/sync-configs.sh` copies them into each library, so standalone clones format and lint the same way.
- Every repository has `README.md`, `TASKS.md`, `docs/architecture.md`, `docs/api/` and `docs/adr/`.
- Macros are prefixed with the library name: `FLINT_`, `AGATE_`, `OPAL_`.
- Errors are `std::expected` values. See coding-style.md section 13.

## Tooling summary

| Tool | Version | Role |
|---|---|---|
| GCC | 16.0.1 (Ubuntu 26.04 package) | Compiler, with C++26 reflection |
| clangd, clang-tidy, clang-format | 23.1 (apt.llvm.org) | Editor intelligence, lint, format. Cannot parse reflection; see flint ADR-0003 |
| CMake, Ninja | Ubuntu 26.04 | Build |
| ccache | Ubuntu 26.04 | Rebuild cache, kept in a Docker volume |
| Tracy | 0.15.0 | Profiler: client fetched by CMake, GUI built into the image |
| GoogleTest | 1.18.0 | Unit tests |
