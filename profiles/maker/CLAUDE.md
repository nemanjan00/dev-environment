
# Maker Profile

For physical-world projects: 3D-printable parts and PCB design.

## 3D / CAD

- **openscad** — parametric, code-first CAD. Headless CLI for scripted model generation:
  - Render to STL: `openscad -o part.stl part.scad`
  - Render to PNG preview: `openscad -o preview.png part.scad`
  - Override parameters: `openscad -D 'width=40' -D 'height=20' -o part.stl part.scad`
  - Prefer authoring `.scad` files over binary CAD formats — they diff cleanly in git.

## PCB / Electronics — use tscircuit

For any electronics / PCB / schematic / circuit-board task in this profile, **use [tscircuit](https://tscircuit.com/)**. It's a TypeScript/React framework for designing circuits as code: you write JSX describing components and nets, and it produces schematics, PCB layouts, and manufacturing files (Gerber, BOM, pick-and-place).

### Runtime: bun, not node

tscircuit requires **bun** — the `tsci` CLI has a `#!/usr/bin/env bun` shebang, and the runtime relies on bun's CJS-to-ESM interop (named imports from CJS packages like `circuit-json`). Running it under plain node/npm fails with `SyntaxError: The requested module 'circuit-json' does not provide an export named 'ms'`.

Do **not** fall back to `npm` / `npx` for tscircuit. Use `bun` and the `tsci` CLI.

### What's pre-installed

- **bun** — installed via asdf, on PATH.
- **`tsci`** — tscircuit CLI, globally installed via `bun add -g tscircuit @tscircuit/cli`. Available directly on PATH (`/work/.bun/bin`), no `bun x` wrapper needed.
- **bun install cache** — pre-warmed with tscircuit's dep tree, so `tsci init` in a user project completes in ~250ms with no network.

### Starting a new board

In an empty project directory, run:

```sh
cd /work/project
tsci init
```

This scaffolds:
- `package.json` with local tscircuit deps (needed for bun to resolve `tscircuit` / `react` from the project)
- `index.circuit.tsx` — starter circuit
- `tscircuit.config.json`, `tsconfig.json`
- **`.claude/skills/tscircuit/`** — a tscircuit-authored Claude skill with detailed syntax/workflow docs. Read the files in that directory when doing real work — they're more current than this CLAUDE.md.

### Common commands

`tsci` is on PATH, so just run it directly.

- `tsci dev` — live-reload preview server (schematic + PCB view in browser).
- `tsci build <file>` — evaluate the circuit and emit `dist/<name>/circuit.json`.
- `tsci export --format gerbers <file>` / `--format bom` / `--format pnp` — export a single fab artifact.
- `tsci snapshot <file>` — generate schematic + PCB PNG snapshots (add `--3d` for a 3D preview).
- `tsci check` — validate the circuit without a full build.

### Component libraries

Three sources, all reachable from the CLI with no auth (just network):

- **JLCPCB / LCSC parts** — `tsci search --jlcpcb --json <query>` returns live catalog results (LCSC part #, mfr, package, stock, price). `tsci import --jlcpcb <lcsc-part>` generates `imports/<name>.tsx` with pin labels, footprint, and the LCSC part # baked in as `supplierPartNumbers.jlcpcb` — exactly what JLC assembly consumes. Prefer `is_basic: true` parts from search results (no setup fee).
- **tscircuit registry** — `tsci search --tscircuit <query>` / `tsci add <author/pkg>` for community-published subcircuits.
- **KiCad footprints** — `tsci search --kicad <query>` to reuse footprints from KiCad libraries.

When the user names a part (e.g. "use an STM32F103" or "C8734"), default to `tsci import --jlcpcb` so the resulting board is directly fabbable via JLCPCB.

### Workflow guidance

- When the user asks for a PCB, default to tscircuit rather than generating KiCad/Eagle files.
- For an existing project, check `.claude/skills/tscircuit/` first — the skill ships authoritative syntax and workflow notes straight from tscircuit.
- Keep each board as its own `.tsx` entry file; share reusable subcircuits as `<group>` components.
- Use `tsci snapshot <file>` to produce a visual artifact you can describe back to the user after changes, since this is a headless environment.
- Footprint strings (`"0402"`, `"sot23"`, `"soic8"`) and `sel.*` net references are the two idioms that most often trip up first drafts.
