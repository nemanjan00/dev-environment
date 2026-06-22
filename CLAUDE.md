# Maintaining this repo (dev-environment)

This repo builds a Docker-based dev environment for running Claude Code in a
sandbox. It ships as a **base image** plus a set of **profile images** that
extend it with domain-specific tooling.

> Note: this `CLAUDE.md` is guidance for working **on this repo**. It is
> distinct from `templates/CLAUDE.md`, which is baked into the image as the
> in-container `/work/CLAUDE.md` that the *running* environment shows Claude.
> If you change tooling, update the right one — see "Two different CLAUDE.md
> files" below.

## Why profiles exist (design intent)

Profiles aren't just a convenience for bundling tools — they exist to
**constrain the agent's action space** so it doesn't wander off in the wrong
direction. A tool that isn't installed is a path the model never considers;
absence is a stronger guardrail than a "don't use X" instruction. The profile
narrows *what* the agent can do; a bundled skill (see "Shipping a Claude skill"
below) narrows *how* it does it.

This is the lens for maintaining profiles:

- When adding a tool, ask **"does this open a door I want open?"** — not "might
  this ever be useful?". Resist kitchen-sink images.
- Prefer the **smallest profile** that covers a task; that's why profiles are
  domain-scoped and chain (`analyst`/`ctf` off `reversing`) rather than merging.
- The "what's deliberately *not* here" sections in each profile's CLAUDE.md are
  intentional rails, not just notes — keep writing them.

## Layout

- `Dockerfile` — the **base** image (`nemanjan00/dev:base`): zsh, Neovim,
  tmux, asdf (Node/Python), Claude Code, opencode, and the common CLI tools.
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
- `bin/` — host entrypoints. The real launchers are the generic `dev-docker`
  (local Docker) and `dev-vm` (Vagrant VM); `claude-docker`/`claude-vm` and
  `opencode-docker`/`opencode-vm` are **one-line shims** (`exec dev-* --claude`
  / `--opencode`). `dev-ollama` launches opencode against a host Ollama model
  (`dev-ollama opencode --model …`; Claude+Ollama is rejected pending a router).
  Plus `claude-vm-setup`. Shared logic lives in `bin/lib/`
  (`common.sh` self-update, `docker-common.sh`, `vm-common.sh`), sourced by the
  launchers — don't duplicate it back into the wrappers.
- `README.md` — user-facing docs, including the profile table.

## Launcher invariants (don't break these)

- **`claude-docker` must stay behavior-identical.** It is the headline command;
  a non-breaking update means running it after a `git pull` works exactly as
  before. It is `dev-docker --claude`, so any change to the shared libs must
  keep that path producing the same `docker run`. There is a stub-`docker`
  smoke test pattern in the git history of this change — re-run it after editing
  `docker-common.sh`.
- **`--add-dir /work/skills` must remain** in the launch command for every
  agent (it auto-loads bundled skills). It now lives in the `dev_*_launch_cmd`
  helpers.
- **`.dev/config.json` is optional and host-parsed.** Absent file (or absent
  `jq`) → no behavior change. It declares extra `mounts` and read-only
  `project.readonly` carve-outs; the whole `.dev/` dir is mounted `:ro` so the
  sandboxed agent can't edit its own sandbox config. Read-only carve-outs are
  **directory-granular** because macOS bind mounts don't enforce file-level
  permissions — keep it that way.
- **opencode** is installed in the base image (npm `opencode-ai`). Its Ollama
  provider config is baked at `/work/opencode-ollama.json` (outside every mount
  so a bind-mounted `~/.config/opencode` can't shadow it) and selected via
  `OPENCODE_CONFIG` only when a launcher gets `--ollama`.

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
5. Optional: add `docker-args.sh` for runtime mounts/env, `mcp.d/*.json`
   for MCP servers, or a bundled Claude skill (see "Shipping a Claude skill"
   below).

When you change a profile's tool set, also refresh that profile's row in the
README table and its `profiles/<name>/CLAUDE.md`.

## Shipping a Claude skill in a profile

Some profiles bundle a Claude Code **skill** (a `SKILL.md`-based playbook the
running Claude can invoke, e.g. `ctf`'s `/pwn`). There is one standard way to
do it — don't improvise per profile:

- **Author it at** `profiles/<name>/skills/<skill>/SKILL.md` (a directory per
  skill, `SKILL.md` as the entry point, plus any supporting files).
- **Install it at build time** by copying that tree into the standard
  image-wide skills dir:
  ```dockerfile
  COPY --chown=1000:1000 skills/ /work/skills/.claude/skills/
  ```
  So `profiles/<name>/skills/pwn/` lands at
  `/work/skills/.claude/skills/pwn/SKILL.md`.
- **It auto-loads, no manual step.** Both wrappers (`bin/claude-docker`,
  `bin/claude-vm`) always launch Claude with `--add-dir /work/skills`, and
  Claude Code auto-discovers any skill under `<added-dir>/.claude/skills/`.
  The base image pre-creates the (empty) `/work/skills/.claude/skills` dir so
  `--add-dir` stays valid even for profiles that ship no skill. Open the
  sandbox and the skill is just *there*.

- **Document it** in `profiles/<name>/CLAUDE.md` with a short "skill" callout
  (what it does, that it's already loaded) — see `ctf`. The base
  `templates/CLAUDE.md` already tells the running Claude that skills auto-load
  from `/work/skills`; the profile section names the specific one.

**Why this exact path** (the constraints that rule out the obvious spots):

- `~/.claude/skills` — the host's `~/.claude` is bind-mounted over
  `/work/.claude` at runtime, so anything baked there is shadowed.
- the project's `.claude/skills` — that's the user's mounted project; writing
  into it dirties their repo on the host. The sandbox must not write to the
  host.
- `/work/skills` is image-internal, untouched by either mount → the skill is
  available with zero setup and nothing persisted to the host.

`--add-dir` is the *only* discovery mechanism that surfaces a skills dir from
outside `~/.claude`/the project; the `permissions.additionalDirectories`
setting does **not** load skills. Keep the flag in both wrappers.

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
