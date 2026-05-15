FROM nemanjan00/dev:base

USER 0

# Chromium runtime libs + Xvfb for headed-mode stealth + fonts so the
# fingerprint surface (font enumeration) matches a real desktop.
# CloakBrowser ships its own patched Chromium binary (auto-downloaded
# on first launch); these are the shared libraries that binary links
# against on Arch.
RUN pacman -Syu --noconfirm \
    nss \
    nspr \
    alsa-lib \
    atk \
    at-spi2-atk \
    at-spi2-core \
    cups \
    dbus \
    gtk3 \
    pango \
    cairo \
    mesa \
    libdrm \
    libxkbcommon \
    libxcomposite \
    libxdamage \
    libxfixes \
    libxrandr \
    libxtst \
    libxi \
    libxcursor \
    libxss \
    libxshmfence \
    xorg-server-xvfb \
    xorg-xauth \
    ttf-liberation \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk

USER 1000

# CloakBrowser — drop-in Playwright/Puppeteer replacement with C++ source
# patched Chromium for anti-bot fingerprint resistance. Python + Node bindings.
RUN pip install cloakbrowser && \
    npm install -g cloakbrowser

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
