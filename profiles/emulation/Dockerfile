FROM nemanjan00/dev:reversing

USER 0

# Full-system + user-mode emulation for running and debugging foreign-arch
# binaries and firmware pulled apart with the reversing tools.
#  - qemu-emulators-full: pulls in every official qemu-system-<arch> package
#    (arm, aarch64, mips, ppc, riscv, ...) plus qemu-user (the user-mode
#    qemu-<arch> emulators) and qemu-img. This single meta-package is what
#    provides qemu-system-mips / qemu-system-arm / qemu-user.
#  - edk2-ovmf / edk2-armvirt: UEFI firmware (x86_64 OVMF, aarch64/arm AAVMF)
#    needed to boot `virt`-machine system images.
#  - dosfstools / mtools: build/inspect the FAT ESP images UEFI boots from
#    without needing root / loop-mounts.
RUN pacman -Syu --noconfirm \
    qemu-emulators-full \
    edk2-ovmf \
    edk2-armvirt \
    dosfstools \
    mtools

USER 1000

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
