
# Multimedia Profile

For command-line **audio, video and image** manipulation: transcoding,
editing, resizing, format conversion, optimization, and metadata inspection of
media files already on disk.

## What's installed

- **ffmpeg** — the universal audio/video tool. Transcode, cut/trim, concat,
  remux, apply filters, extract frames or audio, generate thumbnails.
  `ffprobe` ships with it for inspecting streams.
- **imagemagick** — `magick` (v7 entrypoint; `convert`/`mogrify`/`identify`/
  `composite`/`montage` remain as compatibility commands) for raster image
  conversion, resize, crop, composite, annotate, and batch processing.
- **graphicsmagick** (`gm`) — leaner ImageMagick fork, faster for batch
  resize; here for scripts/muscle memory that call `gm`.
- **sox** — audio effects, resampling, and format conversion; `soxi` for
  audio metadata.
- **libwebp** — `cwebp` / `dwebp` / `gif2webp` for WebP encode/decode.
- **libavif** — `avifenc` / `avifdec` for AVIF encode/decode.
- **mediainfo** — one-shot technical metadata dump for any container.
- **exiftool** (`perl-image-exiftool`) — read/write/strip EXIF and media
  metadata.
- **jpegoptim / optipng / gifsicle** — lossless (optionally lossy) size
  optimizers for JPEG, PNG and GIF.
- **potrace** — trace a bitmap into vector (SVG/EPS).
- **ghostscript** (`gs`) — PDF/PostScript rasterizer; ImageMagick delegates to
  it for PDF input/output.

## Canonical commands

```sh
# Video: transcode to H.264 mp4, scale to 720p, keep audio
ffmpeg -i in.mov -c:v libx264 -crf 23 -preset medium -vf scale=-2:720 -c:a aac out.mp4

# Extract audio / a single frame
ffmpeg -i in.mp4 -vn -c:a libmp3lame -q:a 2 out.mp3
ffmpeg -i in.mp4 -ss 00:00:05 -frames:v 1 frame.png

# Inspect (no decode)
ffprobe -v error -show_format -show_streams in.mp4
mediainfo in.mp4

# Image: convert + resize + strip metadata
magick in.png -resize 800x600 -strip out.jpg
magick mogrify -format webp -resize 50% *.png       # batch in place

# Modern formats
cwebp -q 80 in.png -o out.webp
avifenc --min 20 --max 30 in.png out.avif

# Optimize losslessly
jpegoptim --strip-all photo.jpg
optipng -o5 image.png
gifsicle -O3 anim.gif -o anim.opt.gif

# Bitmap -> vector
potrace logo.pbm -s -o logo.svg        # potrace wants PBM/PGM; magick converts first
```

## Tips

- **ImageMagick v7**: prefer `magick ...` and `magick mogrify ...`. The bare
  `convert`/`mogrify` names still work but are the legacy v6 spelling.
- **`-2` in ffmpeg scale** keeps dimensions even (H.264 requires it) while
  preserving aspect ratio; use `-vf scale=w:-2` or `scale=-2:h`.
- **potrace only reads bitmap** (PBM/PGM/PPM/BMP). For a PNG/JPEG, threshold
  it first: `magick in.png -threshold 50% pbm:- | potrace -s -o out.svg`.
- **PDF via ImageMagick** works only because ghostscript is installed; render
  a page with `magick -density 300 in.pdf[0] page0.png`.

## What's *not* here

- **Media *downloading*** (yt-dlp, streamlink) — this profile edits files you
  already have; pull them in with the base `curl`/`wget` or add a downloader
  per project.
- **GUI editors** (GIMP, Kdenlive, Audacity, Blender) — headless CLI only.
- **Capture/streaming** (OBS, ffserver, v4l tooling) — no devices in the
  sandbox; out of scope.
- **Document/ebook extraction** — see the `librarian` profile
  (pdftotext, poppler, tesseract OCR, catdoc, …).
- **Deep media forensics / carving** — see the `reversing` profile
  (binwalk, foremost, exiftool is shared).
