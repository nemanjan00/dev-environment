FROM nemanjan00/dev:base

USER 0

# Install reversing tools from official repos and sudo for AUR builds
RUN pacman -Syu --noconfirm \
    sudo \
    radare2 \
    r2ghidra \
    python-r2pipe \
    binwalk \
    python-jsbeautifier && \
    echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

# Install apktool from AUR
USER 1000
RUN git clone https://aur.archlinux.org/android-apktool.git /tmp/android-apktool && \
    cd /tmp/android-apktool && \
    makepkg -si --noconfirm && \
    rm -rf /tmp/android-apktool

# Install radare2 MCP plugin
RUN r2pm -U && r2pm -ci r2mcp

# Remove passwordless sudo after build
USER 0
RUN rm /etc/sudoers.d/user
USER 1000
