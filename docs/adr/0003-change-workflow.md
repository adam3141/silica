# 0003. Scaffold on main, then pull requests

- Status: Accepted
- Date: 2026-11-24

## Context

The owner wants to review work without slowing the initial setup.

## Decision

- The initial scaffold of each repository goes straight to `main`: build system, configuration, documentation skeleton, dev container.
- After that, each feature goes on a branch (`feature/<name>`) with a pull request for the owner to review and merge. When a submodule PR merges, silica gets a follow-up commit or PR that bumps the submodule pointer.

## Consequences

- `main` stays reviewable history. Demos that need feedback are linked from their PR.
