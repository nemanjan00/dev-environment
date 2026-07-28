FROM nemanjan00/dev:base

USER 0

# PHP runtime + Composer. Arch's core `php` package already bundles most of the
# extensions this profile targets as *shared* modules (curl, mbstring, exif,
# bcmath, gmp, intl) — they just ship disabled. `zlib` is compiled in
# statically (always on). Only `gd` lives in a separate package (php-gd), and
# `gmp` needs the system GMP library present at runtime to load its module.
RUN pacman -Syu --noconfirm \
    php \
    php-gd \
    composer \
    gmp

# Enable the extensions required by the target composer projects. Arch's php is
# built with --with-config-file-scan-dir=/etc/php/conf.d, so a drop-in here is
# picked up without editing the main php.ini. mbstring is listed before exif
# because the exif extension depends on it being loaded first.
RUN printf '%s\n' \
    'extension=mbstring' \
    'extension=curl' \
    'extension=exif' \
    'extension=bcmath' \
    'extension=gmp' \
    'extension=gd' \
    > /etc/php/conf.d/dev-extensions.ini

USER 1000

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
