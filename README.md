# dev-environment

[![Build Status](https://travis-ci.org/nemanjan00/dev-environment.svg?branch=master)](https://travis-ci.org/nemanjan00/dev-environment)

## Table of contents

<!-- vim-markdown-toc GFM -->

* [Run it](#run-it)
* [Opening project inside of it](#opening-project-inside-of-it)
* [Components](#components)
* [Author](#author)

<!-- vim-markdown-toc -->

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

## Author

* [nemanjan00](https://github.com/nemanjan00)

