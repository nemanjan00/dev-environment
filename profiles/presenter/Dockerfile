FROM nemanjan00/dev:base

USER 0

# Pandoc + the slice of TeX Live that pandoc's beamer pipeline actually
# touches. xelatex is the engine; `latexextra` brings beamer itself plus the
# usual long tail of class/style files; `fontsextra` covers the fonts beamer
# themes reach for; `pictures` pulls TikZ/PGF for diagrams in slides.
# `lmodern` is bundled into `texlive-fontsrecommended` on Arch — no separate
# package. `ttf-hack-nerd` lives in the official `extra` repo (no AUR).
RUN pacman -Syu --noconfirm \
    pandoc-cli \
    texlive-xetex \
    texlive-latex \
    texlive-latexrecommended \
    texlive-latexextra \
    texlive-fontsrecommended \
    texlive-fontsextra \
    texlive-pictures \
    fontconfig \
    ttf-hack-nerd && \
    fc-cache -f

USER 1000

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
