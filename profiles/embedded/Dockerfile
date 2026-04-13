FROM nemanjan00/dev:base

USER 0

# Install embedded development tools from official repos
RUN pacman -Syu --noconfirm \
    arm-none-eabi-gcc \
    arm-none-eabi-newlib \
    arm-none-eabi-binutils \
    avrdude \
    esptool \
    platformio-core \
    openocd \
    stlink \
    sigrok-cli \
    dtc \
    flashrom \
    i2c-tools \
    python-pyserial \
    picocom \
    cmake

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
USER 1000
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
