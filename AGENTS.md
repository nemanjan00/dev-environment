# Maintaining this repo (dev-environment)

This repo builds a Docker-based dev environment for running Claude Code in a
sandbox. It ships as a **base image** plus a set of **profile images** that
extend it with domain-specific tooling.

> Note: this `AGENTS.md` is guidance for working **on this repo**. It is
> distinct from `templates/AGENTS.md`, which is baked into the image as the
> in-container `/work/AGENTS.md` that the *running* environment shows the agent.
> If you change tooling, update the right one — see "Two different AGENTS.md
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
- The "what's deliberately *not* here" sections in each profile's AGENTS.md are
  intentional rails, not just notes — keep writing them.

## Layout

- `Dockerfile` — the **base** image (`nemanjan00/dev:base`): zsh, Neovim,
  tmux, asdf (Node/Python), Claude Code, opencode, and the common CLI tools.
- `templates/AGENTS.md` — copied into the base image as `/work/AGENTS.md`
  (the docs the running container presents to the agent), alongside
  `templates/CLAUDE.md`, a one-line `@AGENTS.md` import shim (see "One file,
  two names" below).
- `profiles/<name>/` — one directory per profile:
  - `Dockerfile` — `FROM nemanjan00/dev:base` (or another profile), adds tools.
  - `AGENTS.md` — profile-specific docs, **appended** to `/work/AGENTS.md` at
    build time. Every profile except `default` has one.
  - `docker-args.sh` (optional, executable) — emits extra `docker run` args on
    stdout (bind mounts, env) when the profile is selected. See `android`.
  - `mcp.d/*.json` (optional) — MCP server configs for the profile. See
    `reversing/mcp.d/r2.json`.
- `.github/workflows/build.yml` — CI: builds base, then every profile. Base
  profiles are a **matrix**; `reversing` is a dedicated job, and the profiles
  that extend it (`analyst`, `ctf`) are a `chained` matrix that `needs:
  reversing`. A `coverage` job fails the run if a `profiles/*` dir isn't wired
  in. `pull_request` builds everything (no push); only `master` pushes. Builds
  use `--pull` and also tag an immutable `:<name>-<sha>`.
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
  agent (it auto-loads bundled skills). It lives in the `dev_*_launch_cmd`
  helpers (`bin/lib/docker-common.sh` and `bin/lib/vm-common.sh`) — *not* in the
  one-line `claude-docker`/`claude-vm` shims.
- **`--mcp-config /work/.config/claude/mcp.d/*.json` must be passed for the
  `claude` preset in BOTH `dev_docker_launch_cmd` and `dev_vm_launch_cmd`** —
  it's how the baked MCP servers (base `shell-session-mcp`, plus any profile
  `mcp.d/*.json` like reversing's r2) reach the agent. The two helpers must stay
  in parity; the VM path silently dropped this once already.
- **Launcher args are built as bash arrays**, expanded `"${DOCKER_ARGS[@]}"`,
  and any value that crosses a shell layer (`zsh -ic` → tmux, or `vagrant ssh
  -c`) is quoted with `dev_shq` / `dev_join_cmd` from `common.sh`. Don't go back
  to space-joined `DOCKER_ARGS` strings or `${arr[*]}` passthrough — paths with
  spaces and prompts with apostrophes depend on this. `dev_*_launch_cmd` must
  return 0 even with no passthrough args (they're called in `CMD="$(...)"` under
  `set -e`).
- **`.dev/config.json` is optional and host-parsed.** Absent file (or absent
  `jq`) → no behavior change. It declares extra `mounts` and read-only
  `project.readonly` carve-outs; the whole `.dev/` dir is mounted `:ro` so the
  sandboxed agent can't edit its own sandbox config. Read-only carve-outs are
  **directory-granular** because macOS bind mounts don't enforce file-level
  permissions — keep it that way. Because the file ships in the repo and the
  agent can write it, config-sourced `mounts:` are screened against a
  sensitive-path denylist (`dev_docker_safe_mount_src`) and `readonly` entries
  are rejected if absolute / containing `..` / whitespace — keep those guards.
- **Env passthrough is host-controlled only.** Per-agent vars are declared in
  `dev_preset_env_vars` (`bin/lib/common.sh`, e.g. `pi` → `ABL_KEY`) and
  one-offs via the `--env` flag; never add env passthrough to
  `.dev/config.json` — the agent can write that file, so naming host vars
  there would exfiltrate secrets. The docker path forwards bare `-e NAME`
  (value stays out of argv); the VM path must embed `NAME=VALUE` (it crosses
  `vagrant ssh -c`), shq-quoted like everything else.
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
   # Append profile context to base AGENTS.md
   COPY AGENTS.md /tmp/profile-agents.md
   RUN cat /tmp/profile-agents.md >> /work/AGENTS.md
   ```
2. Create `profiles/<name>/AGENTS.md` documenting what's installed, why, and
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
README table and its `profiles/<name>/AGENTS.md`.

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
- **It auto-loads, no manual step.** Both launch paths (`dev_docker_launch_cmd`
  and `dev_vm_launch_cmd` in `bin/lib/`, used by `claude-docker`/`claude-vm`)
  always launch Claude with `--add-dir /work/skills`, and
  Claude Code auto-discovers any skill under `<added-dir>/.claude/skills/`.
  The base image pre-creates the (empty) `/work/skills/.claude/skills` dir so
  `--add-dir` stays valid even for profiles that ship no skill. Open the
  sandbox and the skill is just *there*.

- **Document it** in `profiles/<name>/AGENTS.md` with a short "skill" callout
  (what it does, that it's already loaded) — see `ctf`. The base
  `templates/AGENTS.md` already tells the running Claude that skills auto-load
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
setting does **not** load skills. Keep the flag in both `dev_*_launch_cmd`
helpers.

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

## One file, two names (AGENTS.md + the CLAUDE.md shim)

Instructions live in **`AGENTS.md`** — the cross-tool convention that Claude
Code (v2.1.277+), opencode, kimi and pi all read, so the four agents this repo
ships share one file instead of four.

Next to every `AGENTS.md` there is a **`CLAUDE.md` containing only
`@AGENTS.md`**. Keep it. Claude Code reads an `AGENTS.md` *only when there is no
`CLAUDE.md` in the working directory or any directory above it*, and both of
this repo's `AGENTS.md` files sit under such a directory:

- `/work/AGENTS.md` is an **ancestor** of `/work/project/`. A mounted project
  with its own `CLAUDE.md` would make Claude skip `/work/AGENTS.md` entirely —
  the environment docs would silently vanish.
- this repo sits under `$HOME`, and a `~/CLAUDE.md` would hide the root
  `AGENTS.md` the same way.

The `@AGENTS.md` import sidesteps both: the shim is a `CLAUDE.md`, so it always
loads, and Claude Code never reads the imported file twice. Do **not** "clean
up" the shims by deleting them, and do not copy content into them.

## Two different AGENTS.md files

- Tooling available **in the running container** → document in
  `templates/AGENTS.md` (base, image-wide) or the relevant
  `profiles/<name>/AGENTS.md` (profile-specific). These are appended together
  inside the image.
- Conventions for **editing this repo** (the above) → this root `AGENTS.md`.
  It is the only AGENTS.md that is *not* shipped into an image; it exists
  purely to guide maintenance work on the repo.
