FROM nemanjan00/dev:base

USER 0

# Install reversing tools from official repos and sudo for AUR builds
RUN pacman -Syu --noconfirm \
    sudo \
    radare2 \
    r2ghidra \
    python-r2pipe \
    binwalk \
    p7zip \
    upx \
    perl-image-exiftool \
    yara \
    sleuthkit \
    squashfs-tools \
    unrar \
    python-jsbeautifier \
    unshield \
    capstone \
    python-capstone \
    python-pefile \
    dotnet-sdk \
    msitools \
    wine \
    minicom \
    python-pycryptodome \
    python-unicorn \
    python-keystone \
    foremost \
    wireshark-cli \
    volatility3 \
    flashrom \
    openocd \
    sigrok-cli \
    dtc \
    python-pyserial && \
    echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

# Install AUR packages
USER 1000
RUN for pkg in android-apktool tio magika sasquatch python-lief python-angr; do \
    git clone https://aur.archlinux.org/$pkg.git /tmp/$pkg && \
    cd /tmp/$pkg && \
    makepkg -si --noconfirm && \
    rm -rf /tmp/$pkg; \
    done

# Install .NET decompiler (ilspycmd)
RUN dotnet tool install -g ilspycmd

# Install radare2 MCP plugin
RUN r2pm -U && r2pm -ci r2mcp

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md

# Remove passwordless sudo after build
USER 0
RUN rm /etc/sudoers.d/user
USER 1000
