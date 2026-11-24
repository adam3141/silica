# silica

silica is the workspace that holds the silica family of projects. Each project is its own repository, included here as a git submodule, and the whole family builds together from this root.

| Project | Repository | What it is | Status |
|---|---|---|---|
| **flint** | [adam3141/flint](https://github.com/adam3141/flint) | Foundation library: logging, JSON, benchmarking and profiling, reflection helpers, platform and networking | Logger complete; growing |
| **agate** | [adam3141/agate](https://github.com/adam3141/agate) | UI library in the style of WPF: XML layout, styles and control templates, animations, dependency properties and data binding, panels, themes. SDL3 and OpenGL for now | Design |
| **opal** | [adam3141/opal](https://github.com/adam3141/opal) | A graphical programming editor built on agate | After agate |

## Getting started

1. Clone with submodules:

   ```bash
   git clone --recurse-submodules git@github.com:adam3141/silica.git
   ```

2. Open the folder in VS Code and choose **Reopen in Container**. The dev container (Ubuntu 26.04) provides GCC 16, LLVM 23 clangd, clang-tidy and clang-format, CMake, Ninja, SDL3 build dependencies, the Tracy profiler, and GUI and GPU access. See [docs/architecture/dev-environment.md](docs/architecture/dev-environment.md).

3. Build and test:

   ```bash
   cmake --preset debug
   cmake --build --preset debug
   ctest --preset debug
   ```

   Presets: `debug`, `release`, `profile` (Tracy), `asan` (AddressSanitizer and UBSan). Build trees go in `build/<preset>`.

## Documentation

- [Workspace architecture](docs/architecture/overview.md)
- [Development environment](docs/architecture/dev-environment.md)
- [Coding style](docs/architecture/coding-style.md)
- [Workspace decision records](docs/adr/README.md)
- [Workspace tasks](TASKS.md)
- [Original project brief](docs/brief.md)
- Each library has its own `docs/architecture.md`, `docs/api/`, `docs/adr/` and `TASKS.md`.

## Licence

MIT. See [LICENSE](LICENSE).
