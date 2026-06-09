# Maintaining this repo (dev-environment)

This repo builds a Docker-based dev environment for running Claude Code in a
sandbox. It ships as a **base image** plus a set of **profile images** that
extend it with domain-specific tooling.

> Note: this `CLAUDE.md` is guidance for working **on this repo**. It is
> distinct from `templates/CLAUDE.md`, which is baked into the image as the
> in-container `/work/CLAUDE.md` that the *running* environment shows Claude.
> If you change tooling, update the right one — see "Two different CLAUDE.md
> files" below.

## Layout

- `Dockerfile` — the **base** image (`nemanjan00/dev:base`): zsh, Neovim,
  tmux, asdf (Node/Python), Claude Code, and the common CLI tools.
- `templates/CLAUDE.md` — copied into the base image as `/work/CLAUDE.md`
  (the docs the running container presents to Claude).
- `profiles/<name>/` — one directory per profile:
  - `Dockerfile` — `FROM nemanjan00/dev:base` (or another profile), adds tools.
  - `CLAUDE.md` — profile-specific docs, **appended** to `/work/CLAUDE.md` at
    build time. Every profile except `default` has one.
  - `docker-args.sh` (optional, executable) — emits extra `docker run` args on
    stdout (bind mounts, env) when the profile is selected. See `android`.
  - `mcp.d/*.json` (optional) — MCP server configs for the profile. See
    `reversing/mcp.d/r2.json`.
- `.github/workflows/build.yml` — CI: builds and pushes base, then every
  profile. The profile list is a **matrix** that must be kept in sync.
- `bin/` — host entrypoints: `claude-docker`, `claude-vm`, `claude-vm-setup`.
- `README.md` — user-facing docs, including the profile table.

## Profile inheritance

Most profiles are `FROM nemanjan00/dev:base`. Some chain off another profile:
`analyst` is `FROM nemanjan00/dev:reversing`. A chained profile must be built
*after* its parent — in CI that means a separate job with `needs:`, not just a
matrix entry (see the `analyst` job in `build.yml`).

## Adding a new profile — checklist

1. Create `profiles/<name>/Dockerfile`:
   ```dockerfile
   FROM nemanjan00/dev:base
   USER 0
   RUN pacman -Syu --noconfirm pkg-a pkg-b
   USER 1000
   # Append profile context to base CLAUDE.md
   COPY CLAUDE.md /tmp/profile-claude.md
   RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
   ```
2. Create `profiles/<name>/CLAUDE.md` documenting what's installed, why, and
   how to use it (follow the tone of existing profile docs — what's here,
   what's deliberately *not*, and canonical commands).
3. **Document it in `README.md` in two places:**
   - the `docker build ... profiles/<name>/` list under **Build it**;
   - a row in the **Profiles** table.
4. **Add it to CI** in `.github/workflows/build.yml`:
   - if it extends `base`, append `<name>` to the `profile` matrix;
   - if it extends another profile, add a dedicated job with `needs:` on that
     profile's build (mirror the `analyst` job).
5. Optional: add `docker-args.sh` for runtime mounts/env, or `mcp.d/*.json`
   for MCP servers.

When you change a profile's tool set, also refresh that profile's row in the
README table and its `profiles/<name>/CLAUDE.md`.

## Packaging conventions

- **Base image: official Arch repos only (core/extra/multilib), no AUR.**
  Verify with `pacman -Si <pkg>` before adding. AUR needs build tooling that
  doesn't belong in the base layer.
- **Profiles may use AUR when a tool isn't in the official repos**, via the
  established build-as-user pattern (grant passwordless sudo, then loop
  `git clone` + `makepkg -si` as uid 1000 — see `reversing/Dockerfile`).
  Prefer an official package whenever one exists.
- Keep `pacman` invocations grouped per logical concern for readable Docker
  layer caching; splitting further for finer cache granularity is fine.

## Two different CLAUDE.md files

- Tooling available **in the running container** → document in
  `templates/CLAUDE.md` (base, image-wide) or the relevant
  `profiles/<name>/CLAUDE.md` (profile-specific). These are appended together
  inside the image.
- Conventions for **editing this repo** (the above) → this root `CLAUDE.md`.
  It is the only CLAUDE.md that is *not* shipped into an image; it exists
  purely to guide maintenance work on the repo.
