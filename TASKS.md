# silica workspace tasks

Workspace-level work only. Each library tracks its own work in its `TASKS.md`: [flint](flint/TASKS.md), [agate](agate/TASKS.md), [opal](opal/TASKS.md).

Status: `[ ]` to do, `[~]` in progress, `[x]` done.

## Done

- [x] Repositories created and linked as submodules with relative URLs (ADR-0001)
- [x] Dev container: Ubuntu 26.04, GCC 16, LLVM 23 tooling, SDL3 and GL dependencies, Xvfb and xdotool, Tracy GUI, GPU, X11, Wayland and time-zone passthrough (ADR-0002)
- [x] `.clang-format`, `.clang-tidy` and `.clangd` matching coding-style.md; `tools/sync-configs.sh`, `tools/tidy.sh`
- [x] Root CMake build and presets (debug, release, profile, asan)
- [x] Coding guide updated for C++26 and per-library macro prefixes
- [x] Workspace docs: overview, dev environment, ADRs 0001 to 0004

## Next

- [ ] CI (GitHub Actions) using the dev container image: build every preset, ctest, `tools/tidy.sh -warnings-as-errors='*'`, `clang-format --dry-run --Werror`, `tools/sync-configs.sh --check`
- [ ] Publish the dev container image (GHCR) so CI and new machines skip the 10-minute build
- [ ] Decide whether agate's repository becomes public (a public silica clone cannot fetch it while it is private)
