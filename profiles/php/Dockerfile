FROM nemanjan00/dev:base

USER 0

# PHP runtime + Composer. Arch's core `php` package compiles `mbstring` and
# `zlib` in statically (always on) and enables `curl` in the stock php.ini;
# the other extensions this profile targets ship as disabled *shared* modules
# (exif, bcmath, gmp, intl). Only `gd` lives in a separate package (php-gd),
# and `gmp` needs the system GMP library present at runtime to load its module.
RUN pacman -Syu --noconfirm \
    php \
    php-gd \
    composer \
    gmp

# Enable the extensions required by the target composer projects. Arch's php is
# built with --with-config-file-scan-dir=/etc/php/conf.d, so a drop-in here is
# picked up without editing the main php.ini. mbstring (exif's dependency) is
# compiled in statically and curl is enabled by the stock php.ini — listing
# either here would warn (missing .so / already loaded).
RUN printf '%s\n' \
    'extension=exif' \
    'extension=bcmath' \
    'extension=gmp' \
    'extension=gd' \
    > /etc/php/conf.d/dev-extensions.ini

USER 1000

# Append profile context to base AGENTS.md
COPY AGENTS.md /tmp/profile-agents.md
RUN cat /tmp/profile-agents.md >> /work/AGENTS.md
