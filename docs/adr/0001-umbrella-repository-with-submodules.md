# 0001. Umbrella repository with one submodule per project

- Status: Accepted
- Date: 2026-11-24

## Context

silica is the company's primary product: a workspace holding several projects (flint, agate, opal, and more later). Each project should have its own repository, history and issue tracker, but they are developed together and change in lockstep early on.

## Decision

- `adam3141/silica` holds the workspace: the dev container, shared tooling configuration, the coding guide, workspace documentation, and a root `CMakeLists.txt` and `CMakePresets.json` that build every project together.
- Each project is a git submodule at the root (`flint/`, `agate/`, `opal/`), using **relative URLs** (`../flint.git`). Clones over SSH or HTTPS then fetch submodules the same way.
- Each project builds on its own as well. When it is the top-level CMake project, it enables its own tests and examples, and it fetches what it depends on (agate will fetch flint if `flint::flint` is not already defined).

## Consequences

- A cross-project change is a commit in each affected submodule plus a pointer update in silica.
- `git clone --recurse-submodules` is needed (or `git submodule update --init` afterwards; the dev container's post-create script does this).
- agate's GitHub repository is currently private while the others are public. A public clone of silica cannot fetch agate until that changes.
