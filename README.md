# dev-environment

[![Build Status](https://travis-ci.org/nemanjan00/dev-environment.svg?branch=master)](https://travis-ci.org/nemanjan00/dev-environment)

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
docker run -ti -v$(pwd):/work/project nemanjan00/dev zsh -ic "cd project ; tmux"
```

## Components

* [vim](https://www.vim.org/) with [my config](https://github.com/nemanjan00/vim)

## Supported languages

* CSS

* Dockerfile

* HTML (with emmet support)

* JS (eslint and tsserver)

* JSon

* PHP

* Python

* Bash

* SQL

* VimL

* XML

* Yaml

* Much more

## Author

* [nemanjan00](https://github.com/nemanjan00)

