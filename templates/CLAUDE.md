# Dev Environment

This is a Docker-based development environment running Arch Linux.

## Environment

- **Shell**: zsh with zplug plugins
- **Editor**: Neovim with coc.nvim LSP support
- **Multiplexer**: tmux
- **User**: unprivileged user (uid 1000), home at `/work`
- **Projects**: mount to `/work/project`

## Package Management

- **System packages**: installed via `pacman` (requires root — not available in this container)
- **Language versions**: managed via [asdf](https://asdf-vm.com/) v0.18.1 (Go binary at `~/.local/bin/asdf`)
  - Node.js is installed via asdf. Use `asdf install nodejs <version>` and `asdf set nodejs <version>` to switch.
  - Add new languages with `asdf plugin add <name>` then `asdf install <name> <version>`.
- **Node.js packages**: install globally with `npm install -g <package>` (no root needed, managed by asdf)

## Key Paths

- `~/.config/nvim` — Neovim configuration
- `~/.config/coc` — coc.nvim extensions
- `~/.local/bin` — user binaries (asdf)
- `~/.asdf` — asdf data (plugins, installs, shims)
- `~/.zsh/index.zsh` — zsh configuration entrypoint
- `~/.tmux.conf` — tmux configuration
