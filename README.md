# dev-environment

[![Build](https://github.com/nemanjan00/dev-environment/actions/workflows/build.yml/badge.svg)](https://github.com/nemanjan00/dev-environment/actions/workflows/build.yml)

![Screenshot](https://github.com/nemanjan00/dev-environment/blob/master/screenshot/nvim.png?raw=true)

My docker-based dev environment.

I am Vim person, but, my setup is not quite git clone, so, I have decided to
build docker based IDE, for editing actual code on servers. 

## Table of contents

<!-- vim-markdown-toc GFM -->

* [Build it](#build-it)
* [Run it](#run-it)
* [Opening project inside of it](#opening-project-inside-of-it)
* [Claude Code](#claude-code)
* [VM isolation](#vm-isolation)
* [Components](#components)
* [Supported languages](#supported-languages)
* [Author](#author)

<!-- vim-markdown-toc -->

## Build it

```bash
docker build -t nemanjan00/dev .
```

## Run it

```bash
docker run -ti nemanjan00/dev
```

## Opening project inside of it

```bash
docker run -ti -eTERM=xterm-256color -v$(pwd):/work/project nemanjan00/dev zsh -ic "cd project ; tmux"
```

## Claude Code

Claude Code is pre-installed. To use it, pass your API key and optionally mount your config:

```bash
# Minimal — just the API key
docker run -ti -e ANTHROPIC_API_KEY -v$(pwd):/work/project nemanjan00/dev zsh -ic "cd project ; claude"

# Mount your Claude config (settings, memory, etc.)
docker run -ti -e ANTHROPIC_API_KEY \
  -v$(pwd):/work/project \
  -v~/.claude:/work/.claude \
  nemanjan00/dev zsh -ic "cd project ; claude"
```

The container ships with a default `~/.claude/CLAUDE.md` that documents the environment for Claude. When you mount your own `~/.claude`, you can add your own settings, custom skills, and memory files.

### What you can mount

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.claude` | `/work/.claude` | Full Claude config (settings, memory, CLAUDE.md) |
| `~/.claude/settings.json` | `/work/.claude/settings.json` | Just your settings |
| `~/.claude/commands/` | `/work/.claude/commands/` | Custom slash commands |

## VM isolation

For full isolation (e.g. giving Claude access to Docker), run the dev container inside a lightweight VM using Vagrant + libvirt.

### Prerequisites

```bash
# Arch Linux
pacman -S vagrant libvirt qemu-full qemu-img
vagrant plugin install vagrant-libvirt
```

### Setup (one-time, needs sudo)

```bash
# Creates a libvirt network with DNS disabled (avoids port 53 conflicts)
sudo ./vm/setup.sh
```

### Usage

```bash
# Start VM and open a project inside it
# Claude gets Docker socket access inside the VM
ANTHROPIC_API_KEY=sk-... ./vm/run.sh /path/to/project

# Stop the VM
./vm/stop.sh

# Destroy the VM entirely
vagrant destroy
```

The VM boots Alpine Linux with Docker, pulls the dev image from Docker Hub, and runs the container with the Docker socket mounted. Claude can spin up additional containers as needed, fully isolated from the host.

### How it works

```
Host (your machine)
└── Vagrant/libvirt VM (Alpine Linux, 4GB RAM, 2 vCPUs)
    ├── Docker daemon
    └── dev container (this image)
        ├── Claude Code
        ├── Neovim, tmux, zsh
        └── /var/run/docker.sock → VM's Docker
```

Project files are mounted into the VM via virtiofs (native libvirt filesystem passthrough), so changes are reflected in both directions. The dev container has access to the VM's Docker socket, so Claude can create sibling containers but cannot affect the host.

## Components

* [Neovim](https://neovim.io/) with [my config](https://github.com/nemanjan00/vim) and [coc.nvim](https://github.com/neoclide/coc.nvim) for LSP
* [zsh](https://www.zsh.org/) with [zplug](https://github.com/zplug/zplug) and [my config](https://github.com/nemanjan00/zsh)
* [tmux](https://github.com/tmux/tmux) with [gpakosz/.tmux](https://github.com/gpakosz/.tmux)
* [asdf](https://asdf-vm.com/) version manager
* [fzf](https://github.com/junegunn/fzf) fuzzy finder
* [ripgrep](https://github.com/BurntSushi/ripgrep) fast search
* [jq](https://jqlang.github.io/jq/) JSON processor
* [ctags](https://ctags.io/) code indexing

## Supported languages

* CSS
* Dockerfile
* HTML (with emmet support)
* JS (eslint and tsserver)
* JSON
* PHP
* Python
* Bash
* SQL
* VimL
* XML
* YAML
* Much more (via coc.nvim extensions)

## Author

* [nemanjan00](https://github.com/nemanjan00)

