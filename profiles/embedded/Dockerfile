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
    picocom \
    cmake

USER 1000

# Install Python packages via pip (asdf Python)
RUN pip install pyserial

# Append profile context to base AGENTS.md
COPY AGENTS.md /tmp/profile-agents.md
RUN cat /tmp/profile-agents.md >> /work/AGENTS.md
