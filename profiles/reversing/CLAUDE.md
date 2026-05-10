# Reversing & Forensics Profile

## Disassembly & Binary Analysis

- **radare2** with **r2ghidra** decompiler and **r2mcp** plugin for AI integration
- **gdb** — native x86_64 debugger for live debugging, core-dump analysis, and scripted inspection (`gdb -batch -ex 'disas main' ./bin`). For aarch64 targets use `aarch64-linux-gnu-gdb` (see cross-toolchain section).
- **muxmcp** — generic stdio MCP multiplexer (documented in base `CLAUDE.md`). Useful here for running `muxmcp -- r2mcp` to analyze multiple binaries concurrently, since `r2mcp` is single-session.
- **python-r2pipe** — script radare2 from Python
- **capstone** / **python-capstone** — disassembly framework
- **python-keystone** — assembler framework for patching binaries
- **python-unicorn** — CPU emulation for unpacking/deobfuscation
- **angr** — symbolic execution and binary analysis
- **lief** — parse and modify ELF, PE, Mach-O binaries
- **pefile** — PE file parsing

## Forensics & File Analysis

- **binwalk** — firmware analysis and extraction
- **foremost** — file carving from disk images
- **sleuthkit** — disk image forensics
- **volatility3** — memory forensics
- **wireshark-cli** (`tshark`) — network packet analysis
- **bind** (`dig`, `host`, `nslookup`) — DNS lookups for IOC/infra investigation; pairs with `jc --dig` for JSON output
- **nmap** — port scanning and service/version detection. Use `-sV` for service probes, `-oX -` for XML output (pipe to `jc --xml`).
- **gnu-netcat** (`nc`) — raw TCP/UDP connections for banner grabbing, manual protocol probing, and shoveling data over sockets. Pairs with `socat` (base) when you need TLS or more complex relays.
- **magika** — AI-powered file type identification
- **yara** — pattern matching for malware classification
- **perl-image-exiftool** — metadata extraction

## Archive & Filesystem Extraction

- **p7zip**, **unrar**, **unshield** — archive extraction
- **squashfs-tools**, **sasquatch** — squashfs extraction (including non-standard vendor formats)
- **upx** — packed executable extraction

## aarch64 cross toolchain

For inspecting, patching, and (re)building ARM64 ELF objects / shared libraries
without an actual aarch64 host. All binaries are prefixed `aarch64-linux-gnu-`:

- **aarch64-linux-gnu-gcc** — cross-compiler. Pair with `-c` for objects,
  `-shared` for `.so`, `-static` to avoid the runtime loader.
- **aarch64-linux-gnu-binutils** — full binutils suite: `objdump` (use
  `-d -M reg-names-std` for AArch64-aware disasm), `readelf`, `nm`, `strings`,
  `strip`, `ar`, `ld`, `as`, `objcopy` (extract/replace sections, e.g.
  `objcopy --dump-section .rodata=out.bin lib.so`), `addr2line`, `size`.
- **aarch64-linux-gnu-gdb** — cross-debugger; attach to a remote `gdbserver`
  on the target with `target remote host:port`.
- **aarch64-linux-gnu-glibc** + **linux-api-headers** — sysroot bits so the
  cross-gcc can actually link executables / shared libs against libc.

For host-side disasm of arbitrary AArch64 blobs (no toolchain prefix needed),
`radare2`, `r2ghidra`, `capstone`, and `lief` all handle ARM64 natively.

## .NET & Windows RE

- **dotnet-sdk** with **ilspycmd** — .NET decompilation; runs modern .NET (Core/5+) assemblies.
- **mono** — runs legacy .NET Framework 2.0–4.x EXEs that `dotnet` won't load (de4dot, older dnSpy CLIs, ConfuserEx unpackers, most pre-Core malware samples). Invoke as `mono Tool.exe`.
- **msitools** — MSI package inspection
- **wine** — run Windows binaries (native PE that isn't .NET, or .NET tools that refuse mono)

## Hardware & Serial

- **minicom** — serial terminal
- **python-pyserial** — scriptable serial communication
- **tio** — serial port tool
- **openocd** — JTAG/SWD debugging
- **flashrom** — flash chip read/write
- **sigrok-cli** — logic analyzer protocol decoding
- **dtc** — device tree compiler

## Android

- **apktool** — APK decompilation and recompilation
- **zipalign** (from `android-sdk-build-tools`) — align APK uncompressed entries on 4-byte boundaries before signing; required after `apktool b` and before `apksigner sign`
- **smalizator** — smali helper that generates Frida (and Xposed) method hooks from a smali invoke line, and grep-searches an apktool-extracted tree for `.implements`/`.super` declarations. Subcommands:
  - `smalizator hook "<smali invoke line>"` — emits a ready-to-paste `Java.use(...).method.implementation = ...` hook for the targeted method (`--xposed` switches to an Xposed hook).
  - `smalizator implements "L<iface>;"` — find every class declaring `.implements L<iface>;`.
  - `smalizator extends "L<class>;"` — find every class declaring `.super L<class>;`.
  - Run `smalizator` with no args for an interactive wizard. The search subcommands shell out to `ag` if present (else `grep -r`) over the **current working directory**, so `cd` into the apktool output (`./smali`, `./smali_classesN/...`) before invoking. Class/interface arguments must be in smali notation (`Lpkg/Cls;`).

## Crypto

- **python-pycryptodome** — cryptographic analysis
- **python-jsbeautifier** — JavaScript deobfuscation
