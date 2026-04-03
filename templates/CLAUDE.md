# Dev Environment

This is a Docker-based development environment running Arch Linux.

## Environment

- **Shell**: zsh with zplug plugins
- **Editor**: Neovim with coc.nvim LSP support
- **Multiplexer**: tmux
- **User**: unprivileged user (uid 1000), home at `/work`
- **Projects**: mount to `/work/project`

## Scripting Tools

The following CLI tools are available for use in scripts and pipelines:

- **jq** — JSON processor. Filter, transform, and extract data from JSON.
- **jc** — Converts output of common commands (`ps`, `mount`, `ls`, `dig`, `git log`, etc.) to JSON. Use as `command | jc --command-name | jq ...`.
- **miller** (`mlr`) — Like jq but for CSV, TSV, and tabular data. Use `mlr --csv filter '$col == "val"' file.csv`.
- **ripgrep** (`rg`) — Fast recursive code search with regex support.
- **fzf** — Fuzzy finder, scriptable with `--filter` for non-interactive use.
- **tree** — Directory structure listing. Use `tree -J` for JSON output.
- **curl** / **wget** — HTTP requests (curl for APIs, wget for file downloads).
- **socat** — Multipurpose network relay for socket operations, port forwarding, and proxying.
- **strace** — Trace system calls for debugging process failures. Use `strace -e trace=open,read cmd` to diagnose issues.
- **eza** — Modern `ls` replacement with `--json` output support.

## Package Management

- **System packages**: installed via `pacman` (requires root — not available in this container)
- **Language versions**: managed via [asdf](https://asdf-vm.com/) v0.18.1 (Go binary at `~/.local/bin/asdf`)
  - Node.js is installed via asdf. Use `asdf install nodejs <version>` and `asdf set nodejs <version>` to switch.
  - Python is installed via asdf. Use `asdf install python <version>` and `asdf set python <version>` to switch. `pip` is available.
  - Add new languages with `asdf plugin add <name>` then `asdf install <name> <version>`.
- **Node.js packages**: install globally with `npm install -g <package>` (no root needed, managed by asdf)

## Key Paths

- `~/.config/nvim` — Neovim configuration
- `~/.config/coc` — coc.nvim extensions
- `~/.local/bin` — user binaries (asdf)
- `~/.asdf` — asdf data (plugins, installs, shims)
- `~/.zsh/index.zsh` — zsh configuration entrypoint
- `~/.tmux.conf` — tmux configuration
