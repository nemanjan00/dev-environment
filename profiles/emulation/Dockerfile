FROM nemanjan00/dev:reversing

USER 0

# Full-system + user-mode emulation for running and debugging foreign-arch
# binaries and firmware pulled apart with the reversing tools.
#  - qemu-emulators-full: qemu-system-* and (dynamically-linked) qemu-<arch>
#    user emulators for every supported guest architecture, plus qemu-img.
#  - edk2-ovmf / edk2-armvirt: UEFI firmware (x86_64 OVMF, aarch64/arm AAVMF)
#    needed to boot `virt`-machine system images.
#  - dosfstools / mtools: build/inspect the FAT ESP images UEFI boots from.
# Grant passwordless sudo for the AUR build below (reversing dropped it).
RUN pacman -Syu --noconfirm \
    qemu-emulators-full \
    edk2-ovmf \
    edk2-armvirt \
    dosfstools \
    mtools && \
    echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

# Statically-linked user-mode emulators (qemu-<arch>-static). Not in the
# official repos; the static build is self-contained, so a freshly extracted
# foreign-arch binary runs with just `-L <sysroot>` and no host guest-libs,
# and it's the binary binfmt_misc points at when the host has it registered.
USER 1000
RUN for pkg in qemu-user-static qemu-user-static-binfmt; do \
    git clone https://aur.archlinux.org/$pkg.git /tmp/$pkg && \
    cd /tmp/$pkg && \
    makepkg -si --noconfirm && \
    cd /tmp && rm -rf /tmp/$pkg; \
    done

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md

# Remove passwordless sudo after build
USER 0
RUN rm /etc/sudoers.d/user
USER 1000
