FROM nemanjan00/dev:base

USER 0

# Install reversing tools from official repos and sudo for AUR builds
RUN pacman -Syu --noconfirm \
    sudo \
    radare2 \
    r2ghidra \
    binwalk \
    p7zip \
    upx \
    perl-image-exiftool \
    yara \
    sleuthkit \
    squashfs-tools \
    unrar \
    unshield \
    capstone \
    dotnet-sdk \
    msitools \
    wine \
    minicom \
    foremost \
    wireshark-cli \
    volatility3 \
    flashrom \
    openocd \
    sigrok-cli \
    dtc && \
    echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

# Install AUR packages
USER 1000
RUN for pkg in android-apktool tio magika sasquatch; do \
    git clone https://aur.archlinux.org/$pkg.git /tmp/$pkg && \
    cd /tmp/$pkg && \
    makepkg -si --noconfirm && \
    cd /tmp && rm -rf /tmp/$pkg; \
    done

# Install Python packages via pip (asdf Python)
RUN pip install r2pipe pefile capstone keystone-engine unicorn \
    pyserial pycryptodome jsbeautifier lief angr

# Install .NET decompiler (ilspycmd)
RUN dotnet tool install -g ilspycmd

# Install smalizator (Frida hook generator + smali search helper)
RUN npm install -g smalizator && \
    ln -sf "$(asdf which smalizator)" /work/.local/bin/smalizator

# Install radare2 MCP plugin
RUN r2pm -U && r2pm -ci r2mcp
ENV PATH="/work/.local/share/radare2/prefix/bin:${PATH}"

# Multiplex r2mcp via muxmcp so multiple binaries can be analyzed concurrently
# in one Claude session (r2mcp itself is single-session — see base CLAUDE.md).
COPY mcp.d/ /work/.config/claude/mcp.d/

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md

# Remove passwordless sudo after build
USER 0
RUN rm /etc/sudoers.d/user
USER 1000
