FROM nemanjan00/dev:base

USER 0

# 3D / CAD tooling
RUN pacman -Syu --noconfirm \
    openscad

USER 1000

# bun is required by tscircuit: the `tsci` CLI has a `#!/usr/bin/env bun`
# shebang, and the tscircuit runtime relies on bun's CJS-to-ESM interop
# (named imports from CJS packages like `circuit-json`). Node fails with
# "does not provide an export named 'ms'".
RUN asdf plugin add bun && \
    asdf install bun latest && \
    asdf set -u bun latest

# Put bun's global bin dir on PATH so `tsci` is directly callable.
ENV PATH="/work/.bun/bin:${PATH}"

# Pre-install tscircuit globally. This gives us the `tsci` CLI on PATH and
# warms bun's install cache so `tsci init` in a user project completes in
# ~250ms with no network. A project-local install is still needed (bun must
# resolve `tscircuit` / `react` from the project's node_modules), but `tsci
# init` handles that and also drops a tscircuit Claude skill into
# `.claude/skills/tscircuit`.
RUN bun add -g tscircuit @tscircuit/cli

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
