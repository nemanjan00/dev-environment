FROM nemanjan00/dev:base

USER 0

# Audio/video/image manipulation from the command line. The set is
# deliberately scoped to *transcoding, editing and inspection* of media files
# already on disk — not capture, not downloading, not streaming servers.
#
#  - ffmpeg          the universal audio/video swiss-army knife (transcode,
#                    cut, concat, filter, extract frames/audio, remux).
#  - imagemagick     `convert`/`magick` + `mogrify`/`identify`/`montage` for
#                    raster image conversion, resize, composite, annotate.
#  - graphicsmagick  leaner ImageMagick fork (`gm`); faster for batch resize,
#                    kept for scripts/muscle memory that shell out to it.
#  - sox             audio processing/effects and format conversion; `soxi`
#                    for audio metadata.
#  - libwebp         `cwebp`/`dwebp`/`gif2webp` — WebP encode/decode.
#  - libavif         `avifenc`/`avifdec` — AVIF encode/decode.
#  - mediainfo       one-shot technical metadata dump for any media container.
#  - perl-image-exiftool  read/write/strip image & media metadata (`exiftool`).
#  - jpegoptim / optipng / gifsicle  lossless (and optional lossy) size
#                    optimizers for JPEG, PNG and GIF respectively.
#  - potrace         raster -> vector (bitmap to SVG/EPS) tracer.
#  - ghostscript     PDF/PostScript rasterizer that ImageMagick delegates to
#                    for PDF in/out; also `gs` directly.
RUN pacman -Syu --noconfirm \
    ffmpeg \
    imagemagick \
    graphicsmagick \
    sox \
    libwebp \
    libavif \
    mediainfo \
    perl-image-exiftool \
    jpegoptim \
    optipng \
    gifsicle \
    potrace \
    ghostscript

USER 1000

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
