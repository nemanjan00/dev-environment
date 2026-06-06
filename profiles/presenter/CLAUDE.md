
# Presenter Profile

For building slide decks from Markdown using **pandoc → beamer → xelatex**.
Mirrors the CI workflow in this repo's downstream presentation projects, so
local renders match what gets published.

## Canonical render command

```sh
pandoc \
  -t beamer \
  --pdf-engine=xelatex \
  -H header.tex \
  --highlight-style=breezedark \
  README.md -o pres.pdf
```

- `-t beamer` → LaTeX beamer class (slides, not a paper).
- `--pdf-engine=xelatex` → required for system fonts (Hack Nerd Font, any
  OpenType you `\setmainfont` in `header.tex`). pdflatex can't see them.
- `-H header.tex` → injects preamble into beamer's document head. This is
  where `\usepackage{fontspec}`, `\setmainfont{...}`, `\setmonofont{Hack
  Nerd Font Mono}`, theme, and color tweaks go.
- `--highlight-style=breezedark` → dark syntax highlighting for fenced code
  blocks. Other built-in styles: `pygments`, `kate`, `tango`, `espresso`,
  `zenburn`, `haddock`, `monochrome`. List with `pandoc --list-highlight-styles`.

## What's installed

- **pandoc-cli** — the universal converter; here used as the Markdown → LaTeX
  front-end.
- **texlive-xetex** — the XeTeX engine (`xelatex`).
- **texlive-latex** + **texlive-latexrecommended** + **texlive-latexextra** —
  base LaTeX, the recommended classes/packages, and the long tail that
  beamer + most themes pull in (beamer itself lives in `latexextra`).
- **texlive-fontsrecommended** — bundles Latin Modern (`lmodern`), CM-Super,
  and friends. There is no separate `lmodern` package on Arch.
- **texlive-fontsextra** — extra font packages beamer themes reach for
  (FiraSans, Inconsolata, etc.).
- **texlive-pictures** — TikZ / PGF, for diagrams inside slides.
- **fontconfig** — `fc-cache`, `fc-list`, so XeTeX can discover system fonts.
- **ttf-hack-nerd** — Hack Nerd Font (official Arch `extra` repo). Use as
  `\setmonofont{Hack Nerd Font Mono}` in `header.tex` to get powerline /
  devicon glyphs in code blocks.

## What's *not* here

- **texlive-bibtexextra**, **texlive-science**, **texlive-publishers** —
  paper-writing scope, not slides. Add per project if needed.
- **lualatex** (in `texlive-luatex`) — pandoc's beamer pipeline works fine
  with xelatex; add only if a template specifically requires Lua.
- **Calibre / LibreOffice** — out of scope; see the `librarian` profile for
  document extraction.
- **chromium / wkhtmltopdf / reveal.js tooling** — this profile is the
  LaTeX path. HTML-based slide decks (reveal.js, remark) need a different
  stack.

## Inspecting available fonts

XeTeX uses fontconfig, so anything `fc-list` sees, `\setmainfont` can use:

```sh
fc-list | grep -i hack         # confirm Hack Nerd Font is registered
fc-list :lang=en family         # list font families known to fontconfig
```

If a font you just installed isn't showing up, run `fc-cache -f` and retry.

## Debugging a failing render

Pandoc swallows LaTeX errors by default. To see the underlying TeX log:

```sh
pandoc ... --pdf-engine=xelatex --pdf-engine-opt=-interaction=nonstopmode \
       -V keep_tex=true README.md -o pres.pdf
# or keep the intermediate .tex and run xelatex by hand:
pandoc ... -o pres.tex && xelatex pres.tex
```

The `.log` next to the `.tex` has the real error (missing package, font not
found, undefined control sequence). Missing-package errors usually mean the
template wants something outside `texlive-latexextra`; check the package's
`tlmgr` collection and add the matching Arch `texlive-*` package.

## Common header.tex starting point

```latex
\usepackage{fontspec}
\setmainfont{Latin Modern Roman}
\setmonofont{Hack Nerd Font Mono}[Scale=0.85]
\usetheme{metropolis}        % needs texlive-latexextra
\setbeamertemplate{navigation symbols}{}
```

If `metropolis` is missing, it's in `texlive-latexextra` — already installed
here. Other popular themes (`Madrid`, `Berlin`, `Warsaw`) are in
`texlive-latexrecommended`.
