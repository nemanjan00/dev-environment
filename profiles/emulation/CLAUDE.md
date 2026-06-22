# Emulation Profile

For *running* the foreign-architecture binaries and firmware the `reversing`
profile pulls apart: execute an ARM/MIPS/RISC-V/PPC userland binary on this
x86_64 host, or boot a whole extracted firmware image under full-system QEMU,
and drive either under a debugger. Extends `reversing`, so binwalk, radare2,
the aarch64 cross-toolchain, `dtc`, and the forensics tooling are all on PATH —
extract with reversing, *run* with this.

## User-mode emulation (run a single foreign binary)

Two flavours of `qemu-<arch>` are installed:

- **`qemu-<arch>-static`** (from `qemu-user-static`) — statically linked, no
  host libraries needed. This is the one to reach for. Point `-L` at the
  sysroot that owns the binary's interpreter / shared libs (e.g. the rootfs
  binwalk just carved out):
  ```sh
  qemu-aarch64-static -L ./extracted-rootfs ./extracted-rootfs/usr/bin/foo --help
  ```
- **`qemu-<arch>`** (from `qemu-emulators-full`) — dynamically linked; same
  invocation, but it needs matching host libs, so prefer the `-static` build
  unless you specifically want it.

Common targets: `qemu-arm`, `qemu-aarch64`, `qemu-mips`, `qemu-mipsel`,
`qemu-mips64`, `qemu-ppc`, `qemu-ppc64`, `qemu-riscv64`, `qemu-sparc`,
`qemu-i386`, `qemu-x86_64` (each with a `-static` twin).

**binfmt_misc is NOT pre-registered.** Transparent `./foo` execution of a
foreign binary needs a kernel binfmt handler, which requires registering it
under `/proc/sys/fs/binfmt_misc` — a privileged, host-level operation this
unprivileged sandbox can't perform. Inside the container, always invoke the
`qemu-<arch>-static` binary **explicitly** as above. (`qemu-user-static-binfmt`
ships the registration files for completeness / for use on a privileged host;
they are not active here.)

## Full-system emulation (boot a firmware image / disk)

`qemu-system-<arch>` boots a complete machine — kernel, firmware, peripherals.
Useful for firmware that won't run as a bare userland binary.

```sh
# aarch64 'virt' board with UEFI, headless serial console:
qemu-system-aarch64 -M virt -cpu cortex-a72 -m 2G -nographic \
  -bios /usr/share/edk2/aarch64/QEMU_EFI.fd \
  -drive if=none,file=disk.img,format=raw,id=hd0 \
  -device virtio-blk-device,drive=hd0

# x86_64 with OVMF UEFI firmware:
qemu-system-x86_64 -M q35 -m 2G -nographic \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file=OVMF_VARS.4m.fd \
  -drive file=disk.img,format=raw
```

- **Run headless.** This is a CLI sandbox with no display — always use
  `-nographic` (or `-display none -serial mon:stdio`) and talk to the guest
  over the serial console. Drive long-running boots through the
  `shell-session-mcp` PTY server (see base `CLAUDE.md`) so the console stays
  live across tool calls.
- **No KVM.** Hardware acceleration isn't available in the sandbox; emulation
  runs under TCG (pure software). Fine for analysis, just slower — keep `-m`
  modest and don't expect native speed.

### UEFI firmware images (edk2)

- **x86_64**: `/usr/share/edk2/x64/OVMF_CODE.4m.fd` (+ a writable copy of
  `OVMF_VARS.4m.fd` for NVRAM).
- **aarch64**: `/usr/share/edk2/aarch64/QEMU_EFI.fd` (pad to 64M for `-bios`,
  or split CODE/VARS pflash) and `QEMU_VARS.fd`.
- **arm**: `/usr/share/edk2/arm/`.

### Building/inspecting boot media

- **dosfstools** (`mkfs.fat`) + **mtools** (`mcopy`, `mdir`, `mmd`) — create
  and populate the FAT EFI System Partition images UEFI boots from *without
  needing loop-mount/root*: `mkfs.fat -C esp.img 65536 && mcopy -i esp.img
  BOOTAA64.EFI ::/EFI/BOOT/`.
- **qemu-img** (from `qemu-emulators-full`) — create/convert/inspect disk
  images: `qemu-img info fw.img`, `qemu-img convert -O qcow2 raw.img out.qcow2`.

## Debugging the guest

QEMU exposes a GDB stub for both modes — `-s` opens it on `tcp::1234`, `-S`
freezes the guest at start so you can connect before the first instruction:

```sh
qemu-aarch64-static -g 1234 -L ./rootfs ./rootfs/bin/foo   # user mode
qemu-system-aarch64 -M virt ... -S -s                      # system mode
```

Then attach a cross-debugger from the `reversing` profile:

```sh
aarch64-linux-gnu-gdb ./foo -ex 'target remote :1234'
```

`gdb` (the native build) is multiarch-capable — `set architecture`,
`set sysroot`, then `target remote :1234` works too when no arch-specific gdb
is installed for the guest. Pair with radare2 (`r2 -d gdb://localhost:1234`)
for stub-level debugging from r2 instead.

## What's deliberately not here

- **No GUI / SDL / VNC display path** — the sandbox is headless; system
  emulation is serial-console only (`-nographic`). Don't add `-display gtk`.
- **No KVM / hardware virtualization** — unprivileged container, TCG only.
  This profile is for *analysis-scale* emulation, not running fast VMs (that's
  what the host-side `dev-vm` Vagrant launcher is for).
- **No active binfmt registration** — see the user-mode note above; invoke the
  `-static` emulators explicitly.
