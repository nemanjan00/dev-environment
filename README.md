# dev-environment

> **Hand Claude Code its own machine — sandboxed, disposable, and pre-loaded
> with the exact toolchain the job needs.**

[![Build](https://github.com/nemanjan00/dev-environment/actions/workflows/build.yml/badge.svg)](https://github.com/nemanjan00/dev-environment/actions/workflows/build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/nemanjan00/dev?logo=docker&label=pulls)](https://hub.docker.com/r/nemanjan00/dev)
[![Base image size](https://img.shields.io/docker/image-size/nemanjan00/dev/base?logo=docker&label=base%20image)](https://hub.docker.com/r/nemanjan00/dev)
![Profiles](https://img.shields.io/badge/profiles-10-blue)
![Arch Linux](https://img.shields.io/badge/built%20on-Arch%20Linux-1793D1?logo=archlinux&logoColor=white)

![Screenshot](https://github.com/nemanjan00/dev-environment/blob/master/screenshot/nvim.png?raw=true)

One command drops you into a containerized **Claude Code** session backed by a
real IDE (Neovim + LSP, tmux, zsh) and a **profile** that pre-installs exactly
the toolkit your task needs — reverse engineering, Android, embedded, data,
binary exploitation, and more. Claude runs wide-open *because* it's boxed in:
your laptop stays clean, the box is throwaway, and you just talk to Claude.

## Quickstart

No image building required — the wrapper pulls prebuilt images from Docker Hub.

```bash
git clone https://github.com/nemanjan00/dev-environment && cd dev-environment
claude login                       # once, on the host (or use ANTHROPIC_API_KEY)

bin/claude-docker                  # sandboxed Claude in your current project
bin/claude-docker --profile ctf    # ...with a full binary-exploitation toolkit
```

That's it — your project is mounted, your Claude auth/config/git identity come
along automatically, and you're talking to Claude in a throwaway box.

## Why devs reach for it

- 🧰 **Pick a loadout.** Ten ready-made [profiles](#profiles) — `reversing`,
  `android`, `embedded`, `maker`, `analyst`, `librarian`, `presenter`,
  `scraper`, `ctf`, or plain `default` — each layered on a shared base image so
  pulls stay small and switching is one flag.
- 🔒 **Sandboxed by default.** Claude runs with `--dangerously-skip-permissions`
  *because* it's boxed in — your host stays untouched. Need Docker-in-Docker?
  [`bin/claude-vm`](#vm-isolation) drops the whole thing inside an ephemeral
  Vagrant/libvirt VM.
- 🧠 **Claude already knows the box.** Every image ships a `/work/CLAUDE.md`,
  and profiles append their own tool docs — even bundled Claude **skills** that
  auto-load (the `ctf` profile drops a `/pwn` exploitation playbook).
- ⚡ **Zero setup.** `claude login` on the host once; the wrapper mounts your
  auth, config, and git identity automatically. Nothing is written back to your
  host beyond your project.
- 🖥️ **Doubles as a portable IDE.** Neovim (LSP via coc.nvim), tmux, zsh, and
  asdf-managed Node/Python — useful even with Claude turned off.

## Table of contents

<!-- vim-markdown-toc GFM -->

* [Quickstart](#quickstart)
* [Why devs reach for it](#why-devs-reach-for-it)
* [Build it](#build-it)
* [Profiles](#profiles)
* [Run it](#run-it)
* [Opening project inside of it](#opening-project-inside-of-it)
* [Claude Code](#claude-code)
  * [Authentication](#authentication)
  * [What gets mounted](#what-gets-mounted)
  * [Manual Docker usage](#manual-docker-usage)
* [VM isolation](#vm-isolation)
* [Components](#components)
* [Supported languages](#supported-languages)
* [Author](#author)

<!-- vim-markdown-toc -->

## Build it

```bash
# Build base image
docker build -t nemanjan00/dev:base .

# Build a profile (default, reversing, etc.)
docker build -t nemanjan00/dev:default profiles/default/
docker build -t nemanjan00/dev:reversing profiles/reversing/
docker build -t nemanjan00/dev:embedded profiles/embedded/
docker build -t nemanjan00/dev:android profiles/android/
docker build -t nemanjan00/dev:maker profiles/maker/
docker build -t nemanjan00/dev:analyst profiles/analyst/
docker build -t nemanjan00/dev:librarian profiles/librarian/
docker build -t nemanjan00/dev:presenter profiles/presenter/
docker build -t nemanjan00/dev:scraper profiles/scraper/
docker build -t nemanjan00/dev:ctf profiles/ctf/

# With custom UID/GID (to match your host user) — apply to the base image
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t nemanjan00/dev:base .
```

## Profiles

The image is split into a base layer and profile-specific layers. The base image (`nemanjan00/dev:base`) contains the common dev environment (zsh, Neovim, tmux, Node.js, Python, Claude Code). Profiles extend it with domain-specific tools.

| Profile | Tag | Description |
|---------|-----|-------------|
| `default` | `nemanjan00/dev:default` | Base environment, no extras |
| `reversing` | `nemanjan00/dev:reversing` | Reverse engineering & forensics: radare2, r2ghidra, r2mcp, jadx, binwalk, apktool, volatility3, unicorn, keystone, magika, wireshark-cli, foremost |
| `embedded` | `nemanjan00/dev:embedded` | Embedded development: arm-none-eabi toolchain, platformio, avrdude, esptool, openocd, stlink, sigrok-cli, flashrom |
| `android` | `nemanjan00/dev:android` | Android / LineageOS builds: repo, git-lfs, JDK 17/11, android-tools, ccache, multilib libs, AOSP host toolchain |
| `maker` | `nemanjan00/dev:maker` | Physical-world maker: OpenSCAD for 3D-printable parts, bun + pre-installed tscircuit CLI for PCB design |
| `analyst` | `nemanjan00/dev:analyst` | Data / infra analyst (extends `reversing`): aws-cli, s3cmd, rclone, psql, mariadb, sqlite, duckdb, valkey-cli, rabbitmq admin, lnav, httpie, protoc, dig |
| `librarian` | `nemanjan00/dev:librarian` | Document & ebook reading: pandoc, poppler (pdftotext), mupdf-tools, qpdf, pdfgrep, catdoc, djvulibre, unrtf, tesseract OCR, glow, w3m |
| `presenter` | `nemanjan00/dev:presenter` | Slide decks from Markdown via pandoc → beamer → xelatex: pandoc-cli, texlive (xetex, latexextra, fontsextra, pictures), fontconfig, Hack Nerd Font |
| `scraper` | `nemanjan00/dev:scraper` | Web scraping against anti-bot sites: CloakBrowser (stealth Chromium, Playwright/Puppeteer drop-in), Xvfb for headed mode, Chromium runtime libs, full font set |
| `ctf` | `nemanjan00/dev:ctf` | Binary exploitation / CTF (extends `reversing`): pwntools, GEF, ROPgadget, ropper, one_gadget, seccomp-tools, patchelf — plus an auto-loaded `pwn` exploitation skill |

To use a profile with the CLI scripts:

```bash
bin/claude-docker --profile reversing

bin/claude-vm --profile reversing
```

### Creating a new profile

Add a directory under `profiles/` with a `Dockerfile` that extends the base image:

```dockerfile
FROM nemanjan00/dev:base

USER 0
RUN pacman -Syu --noconfirm your-packages-here
USER 1000
```

CI automatically discovers and builds all profiles under `profiles/`.

If the profile needs extra bind mounts or env vars at runtime (e.g. a persistent ccache for Android builds), add an executable `docker-args.sh` in the profile directory. `bin/claude-docker` runs it when the profile is selected and appends its stdout to the `docker run` arguments:

```bash
#!/bin/bash
# profiles/myprofile/docker-args.sh
mkdir -p "$HOME/.cache/myprofile"
echo "-v $HOME/.cache/myprofile:/work/.cache/myprofile"
```

## Run it

```bash
docker run -ti nemanjan00/dev:default
```

## Opening project inside of it

```bash
docker run -ti -eTERM=xterm-256color -v$(pwd):/work/project nemanjan00/dev:default zsh -ic "cd project ; tmux"
```

## Claude Code

Claude Code is pre-installed. The quickest way to get started is with the CLI scripts:

```bash
# Direct Docker — simple, no VM overhead
bin/claude-docker

# VM-isolated — Claude gets its own Docker daemon, fully sandboxed
bin/claude-vm
```

Both scripts auto-detect and mount `~/.claude.json` (OAuth), `~/.claude/` (config), and `~/.gitconfig` into the container. Claude runs with `--dangerously-skip-permissions` since the environment is sandboxed.

### Authentication

```bash
# API key (works with both scripts)
ANTHROPIC_API_KEY=sk-... bin/claude-docker

# OAuth — just run `claude login` on the host first, then:
bin/claude-docker  # ~/.claude.json is mounted automatically
```

### What gets mounted

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.claude.json` | `/work/.claude.json` | OAuth credentials (from `claude login`) |
| `~/.claude` | `/work/.claude` | Full Claude config (settings, memory, CLAUDE.md) |
| `~/.gitconfig` | `/work/.gitconfig` | Git identity and settings (read-only) |

The container ships with a `/work/CLAUDE.md` that documents the environment for Claude. Profile images append profile-specific tool documentation to it. Since Claude Code walks up from the project directory, `/work/CLAUDE.md` is always loaded as an ancestor of `/work/project/`. Your project can still have its own `CLAUDE.md` — both will be read.

### Host network mode

Frontend developers who need container ports (e.g. dev servers) accessible on the host can enable host networking:

```bash
bin/claude-docker --host-network
```

This passes `--network host` to Docker, so any ports the container listens on are directly available on localhost.

### Manual Docker usage

```bash
# Minimal
docker run -ti -e ANTHROPIC_API_KEY -v$(pwd):/work/project nemanjan00/dev:default zsh -ic "cd project ; claude"

# Full setup
docker run -ti -e ANTHROPIC_API_KEY \
  -v$(pwd):/work/project \
  -v~/.claude:/work/.claude \
  -v~/.claude.json:/work/.claude.json \
  -v~/.gitconfig:/work/.gitconfig:ro \
  nemanjan00/dev:default zsh -ic "cd project ; claude"
```

## VM isolation

For full isolation (e.g. giving Claude access to Docker), use `bin/claude-vm` to run the dev container inside a lightweight VM via Vagrant + libvirt. Each invocation creates an ephemeral VM that is destroyed on exit.

### Prerequisites

```bash
# Arch Linux
pacman -S vagrant libvirt qemu-full qemu-img
vagrant plugin install vagrant-libvirt
```

### Usage

```bash
# Run from your project directory — it gets mounted into the VM
cd /path/to/project
/path/to/dev-environment/bin/claude-vm

# With API key
ANTHROPIC_API_KEY=sk-... bin/claude-vm
```

By default, `claude-vm` auto-detects `~/.claude.json`, `~/.claude/`, and `~/.gitconfig`. You can override with env vars:

| Env var | Default | Purpose |
|---------|---------|---------|
| `PROJECT_DIR` | `$(pwd)` | Project directory to mount |
| `CLAUDE_CONFIG_DIR` | `~/.claude` | Claude config (settings, memory) |
| `CLAUDE_AUTH` | `~/.claude.json` | OAuth credentials file |
| `ANTHROPIC_API_KEY` | (none) | API key authentication |

VMs are ephemeral — each `claude-vm` invocation gets a unique VM ID and cleans up on exit (including Ctrl-C). Multiple instances can run in parallel.

The container inside the VM has access to the VM's Docker socket (with correct group permissions via `--group-add`), so Claude can spin up additional containers as needed, fully isolated from the host.

### How it works

```
Host (your machine)
└── Vagrant/libvirt VM (Alpine Linux, 4GB RAM, 2 vCPUs)
    ├── Docker daemon
    └── dev container (this image)
        ├── Claude Code (--dangerously-skip-permissions)
        ├── Docker CLI → VM's Docker socket
        ├── Neovim, tmux, zsh
        └── Project files (virtiofs mount)
```

Project files are mounted into the VM via virtiofs (native libvirt filesystem passthrough), so changes are reflected in both directions. The dev container cannot affect the host.

### Troubleshooting

If `vagrant up` fails with `dnsmasq: failed to create listening socket ... Address already in use`, you have something bound on port 53 that conflicts with libvirt's DHCP. Run `sudo bin/claude-vm-setup` to create a custom network with DNS disabled.

## Components

* [Neovim](https://neovim.io/) with [my config](https://github.com/nemanjan00/vim) and [coc.nvim](https://github.com/neoclide/coc.nvim) for LSP
* [zsh](https://www.zsh.org/) with [zplug](https://github.com/zplug/zplug) and [my config](https://github.com/nemanjan00/zsh)
* [tmux](https://github.com/tmux/tmux) with [gpakosz/.tmux](https://github.com/gpakosz/.tmux)
* [asdf](https://asdf-vm.com/) version manager (Node.js, Python pre-installed)
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

