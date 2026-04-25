FROM nemanjan00/dev:base

USER 0

# CLI tooling for reading and extracting text from documents and ebooks.
# Pandoc is the universal converter (DOCX, ODT, EPUB, RTF, HTML, Markdown,
# LaTeX, ...); the rest cover formats pandoc can't handle natively.
RUN pacman -Syu --noconfirm \
    poppler \
    mupdf-tools \
    qpdf \
    pdfgrep \
    tesseract \
    tesseract-data-eng \
    pandoc-cli \
    catdoc \
    djvulibre \
    unrtf \
    w3m \
    glow

USER 1000

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
