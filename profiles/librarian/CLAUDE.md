
# Librarian Profile

For reading, extracting, and converting documents and ebooks from the command
line. Optimised for piping document text into other tools (`grep`, `jq`, an
LLM) rather than for visual rendering.

## Universal converter — pandoc

**pandoc-cli** (`pandoc`) is the swiss army knife. It reads / writes ~40
formats including DOCX, ODT, EPUB, RTF, HTML, Markdown, LaTeX, MediaWiki, and
plain text. Default to pandoc first; reach for the format-specific tools only
when pandoc can't handle the input.

```sh
pandoc book.epub -o book.txt              # epub -> plain text
pandoc report.docx -o report.md           # docx -> markdown
pandoc page.html -t plain -o page.txt     # html -> text
pandoc --list-input-formats                # see what it accepts
```

Pandoc does **not** read PDF, legacy `.doc` (Word 97-2003 binary), DjVu, or
MOBI/AZW — use the format-specific tools below for those.

## PDF

- **poppler** — ships `pdftotext`, `pdfinfo`, `pdfimages`, `pdftoppm`,
  `pdftohtml`. Default toolkit for text extraction.
  - `pdftotext -layout file.pdf -` — preserve column layout, write to stdout.
  - `pdftotext file.pdf -` — reflowed text (better for prose, worse for tables).
  - `pdfinfo file.pdf` — page count, metadata, embedded fonts.
  - `pdfimages -all file.pdf out` — extract embedded images.
  - `pdftoppm -png -r 200 file.pdf page` — rasterise pages (e.g. before OCR).
- **mupdf-tools** (`mutool`) — alternative renderer / extractor, often
  cleaner output than poppler on awkward PDFs. `mutool draw -F txt file.pdf`,
  `mutool extract file.pdf`, `mutool show file.pdf trailer`.
- **qpdf** — structural PDF transforms: decrypt, linearize, split, merge,
  inspect object streams. `qpdf --decrypt --password=foo in.pdf out.pdf`,
  `qpdf --split-pages in.pdf out-%d.pdf`.
- **pdfgrep** — regex search across PDFs without extracting first.
  `pdfgrep -rn 'pattern' library/` — recursive, with page numbers.

### Scanned PDFs (no embedded text)

`pdftotext` returns empty on image-only PDFs. Detect with `pdfinfo` (no text
layer) or just check whether `pdftotext` output is empty, then OCR:

```sh
pdftoppm -png -r 300 scan.pdf page          # rasterise
for p in page-*.png; do tesseract "$p" "${p%.png}" -l eng; done
cat page-*.txt > scan.txt
```

`ocrmypdf` (which wraps this and re-embeds the text layer) is **not**
installed — it's AUR-only. If you need it, `pip install --user ocrmypdf` or
do the manual `pdftoppm | tesseract` pipeline above.

## Legacy MS Office binary formats (.doc / .xls / .ppt)

- **catdoc** — extract text from Word 97-2003 `.doc`. Also ships `xls2csv`
  (`.xls` → CSV) and `catppt` (`.ppt` → text). For modern `.docx` / `.xlsx` /
  `.pptx`, use **pandoc** instead.

## Ebooks

- **EPUB** — `pandoc book.epub -o book.txt` (or `-t markdown`).
- **MOBI / AZW / AZW3** — no FOSS CLI in the official repos. Options:
  1. AUR: `libmobi` ships `mobitool` for unpacking + text extraction.
  2. Convert with Calibre's `ebook-convert` on another machine, then bring
     the resulting `.epub` here.
- **FB2** — pandoc reads `fb2` directly.

## DjVu

- **djvulibre** — text + structural extraction from `.djvu` scans.
  - `djvutxt file.djvu` — extract OCR'd text layer if present.
  - `djvused file.djvu -e 'select; print-meta'` — metadata.
  - `ddjvu -format=tiff -page=1 file.djvu page1.tiff` — render a page.

## RTF

- **unrtf** — `unrtf --text file.rtf` for plain text, `--html` for HTML.
  Pandoc also handles RTF and usually gives cleaner output; reach for `unrtf`
  when pandoc chokes on a malformed file.

## OCR

- **tesseract** with **tesseract-data-eng** (English only by default — install
  `tesseract-data-<lang>` for others, e.g. `tesseract-data-fra`).
  - `tesseract image.png stdout -l eng` — print recognised text.
  - `tesseract image.png out -l eng pdf` — produce a searchable PDF.
  - For multi-language documents: `-l eng+deu`.

## Terminal rendering

These are for reading content interactively, not for piping into other tools.

- **glow** — Markdown renderer with paging and styling. `glow README.md`,
  or `pandoc file.docx -t gfm | glow -` to read a Word doc in the terminal.
- **w3m** — text-mode HTML renderer. `w3m file.html`, or `w3m -dump
  file.html` for a non-interactive plain-text dump (preserves layout better
  than `pandoc -t plain`).

## Common pipelines

Combine with the base tools (`jq`, `mlr`, `rg`, `fzf`) for library-scale work:

```sh
# Search a directory of mixed PDFs and EPUBs
pdfgrep -rn 'TLS 1.3' library/
find library -name '*.epub' -exec sh -c \
  'pandoc "$1" -t plain | grep -Hn --label="$1" "TLS 1.3"' _ {} \;

# Index every PDF's title + page count to JSONL
find library -name '*.pdf' -exec sh -c \
  'pdfinfo "$1" | jc --pdfinfo 2>/dev/null || \
   pdfinfo "$1" | awk -v f="$1" "BEGIN{print \"{\\\"file\\\":\\\"\" f \"\\\"}\"}"' _ {} \;

# Word-count an entire shelf of EPUBs
for f in shelf/*.epub; do
  printf "%6d  %s\n" "$(pandoc "$f" -t plain | wc -w)" "$f"
done | sort -n
```

## What's *not* here

- **Calibre** (`ebook-convert`, `ebook-meta`) — intentionally omitted to keep
  the image small. Install with `pacman -S calibre` if you need MOBI/AZW
  conversion or library management.
- **LibreOffice** — same reason. For `.doc` extraction use `catdoc`; for
  `.docx` / `.odt` use `pandoc`.
- **ocrmypdf**, **libmobi** — AUR only; see notes above.
