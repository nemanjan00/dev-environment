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

