# Reversing & Forensics Profile

## Disassembly & Binary Analysis

- **radare2** with **r2ghidra** decompiler and **r2mcp** plugin for AI integration
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
- **magika** — AI-powered file type identification
- **yara** — pattern matching for malware classification
- **perl-image-exiftool** — metadata extraction

## Archive & Filesystem Extraction

- **p7zip**, **unrar**, **unshield** — archive extraction
- **squashfs-tools**, **sasquatch** — squashfs extraction (including non-standard vendor formats)
- **upx** — packed executable extraction

## .NET & Windows RE

- **dotnet-sdk** with **ilspycmd** — .NET decompilation
- **msitools** — MSI package inspection
- **wine** — run Windows binaries

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
- **smalizator** — smali helper that generates Frida (and Xposed) method hooks from a smali invoke line, and grep-searches an apktool-extracted tree for `.implements`/`.super` declarations. Subcommands:
  - `smalizator hook "<smali invoke line>"` — emits a ready-to-paste `Java.use(...).method.implementation = ...` hook for the targeted method (`--xposed` switches to an Xposed hook).
  - `smalizator implements "L<iface>;"` — find every class declaring `.implements L<iface>;`.
  - `smalizator extends "L<class>;"` — find every class declaring `.super L<class>;`.
  - Run `smalizator` with no args for an interactive wizard. The search subcommands shell out to `ag` if present (else `grep -r`) over the **current working directory**, so `cd` into the apktool output (`./smali`, `./smali_classesN/...`) before invoking. Class/interface arguments must be in smali notation (`Lpkg/Cls;`).

## Crypto

- **python-pycryptodome** — cryptographic analysis
- **python-jsbeautifier** — JavaScript deobfuscation
