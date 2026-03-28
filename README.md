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

