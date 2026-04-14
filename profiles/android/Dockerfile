FROM nemanjan00/dev:base

USER 0

# Enable multilib for 32-bit libraries required by the Android build system
RUN printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf

# sudo is needed for makepkg to install AUR build deps
RUN pacman -Syu --noconfirm sudo && \
    echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

# Install Android / LineageOS build dependencies
# See: https://wiki.lineageos.org/devices/ (per-device build instructions)
RUN pacman -Syu --noconfirm \
    jdk17-openjdk \
    jdk11-openjdk \
    repo \
    android-tools \
    git-lfs \
    bc \
    bison \
    flex \
    gperf \
    imagemagick \
    lzop \
    lz4 \
    pngcrush \
    rsync \
    schedtool \
    squashfs-tools \
    libxslt \
    libxml2 \
    zip \
    unzip \
    xxd \
    ccache \
    maven \
    ninja \
    protobuf \
    python-protobuf \
    elfutils \
    libelf \
    gnutls \
    openssl \
    sdl2 \
    lib32-glibc \
    lib32-gcc-libs \
    lib32-zlib \
    lib32-ncurses \
    lib32-readline

USER 1000

# AUR packages: ncurses5-compat-libs is needed by old AOSP host prebuilts (libncurses.so.5)
RUN for pkg in ncurses5-compat-libs; do \
    git clone https://aur.archlinux.org/$pkg.git /tmp/$pkg && \
    cd /tmp/$pkg && \
    makepkg -si --noconfirm --skippgpcheck && \
    cd /tmp && rm -rf /tmp/$pkg; \
    done

# ccache tuning for Android builds (LineageOS recommends 50G+)
ENV USE_CCACHE=1
ENV CCACHE_EXEC=/usr/bin/ccache
ENV CCACHE_DIR=/work/.ccache

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md

# Remove passwordless sudo after build
USER 0
RUN rm /etc/sudoers.d/user
USER 1000
