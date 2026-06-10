
# CTF Profile

Binary-exploitation / capture-the-flag work. Extends the **`reversing`**
profile, so everything from that layer (gdb, radare2, r2ghidra, capstone,
keystone, unicorn, angr, pycryptodome, nmap/netcat/socat) is already here.
This profile adds the pwn-specific tooling on top.

## The `pwn` skill (already loaded)

This profile ships a **`pwn` Claude skill** — a step-by-step exploitation
playbook (triage → find the bug → build a pwntools exploit → land a shell →
read the flag). It's baked into the image and auto-loaded; the `claude-docker`
/ `claude-vm` wrappers pass `--add-dir /work/skills`, so the skill is live the
moment you open the sandbox. Nothing to install. Invoke it with `/pwn`, or
just describe a challenge ("here's an ELF and an nc host:port") and it kicks
in. The skill source is at `/work/skills/.claude/skills/pwn/SKILL.md`.

## The exploit-dev loop

A typical `pwn` challenge ships a binary plus the remote's libc. The loop:

```sh
checksec --file=./chall            # pwntools' checksec: NX, PIE, RELRO, canary
patchelf --set-interpreter ./ld-2.31.so \
         --replace-needed libc.so.6 ./libc-2.31.so ./chall   # run vs remote libc
one_gadget ./libc-2.31.so          # one-shot execve("/bin/sh") offsets
ROPgadget --binary ./chall | grep ': pop rdi'   # find ROP gadgets
gdb ./chall                        # GEF auto-loads: heap, vmmap, pattern, ...
```

Then drive it from a pwntools script:

```python
from pwn import *
context.binary = elf = ELF('./chall')
libc = ELF('./libc-2.31.so')

io = process('./chall')            # swap for remote('host', 1337) against the server
# ... build payload: cyclic(), elf.symbols, ROP(elf), fmtstr_payload, etc.
io.interactive()
```

## What's installed

- **pwntools** — the framework. `from pwn import *` gives you `process` /
  `remote` I/O, `cyclic`/`cyclic_find` for offset discovery, `ELF` symbol &
  GOT/PLT lookup, `ROP()` chain builder, `shellcraft`, `fmtstr_payload`, and
  the `checksec` / `cyclic` / `pwn` CLIs.
- **GEF** — GDB Enhanced Features, auto-sourced from `~/.gdbinit`. Adds
  `checksec`, `vmmap`, `heap chunks`, `pattern create/search`, `got`,
  `telescope`, and registers/stack/code context on every stop. Just run
  `gdb ./chall`. (`gdb` itself comes from the reversing layer.)
- **ROPgadget** & **ropper** — gadget finders. ROPgadget is fast for quick
  greps; ropper has a richer query language and can build chains.
- **one_gadget** — scans a libc for the one-shot `execve("/bin/sh", 0, 0)`
  gadgets and prints their constraints. Indispensable for short ROP chains.
- **seccomp-tools** — `seccomp-tools dump ./chall` disassembles the seccomp
  BPF filter so you know which syscalls survive (sandbox-escape challenges).
- **patchelf** — repoint a binary's loader/RPATH so it runs against the
  challenge's bundled libc instead of the host's.
- **angr** (from `reversing`) — symbolic execution for `rev` challenges and
  constraint-solving (`crackme`-style "find the input" problems).

## What's *not* here

- **pwndbg / pwninit** — GEF covers the same debugging ground without an AUR
  build, and `patchelf` + a one-liner replace what `pwninit` automates. Add
  per project if you specifically want them.
- **A GUI** — this is a CLI box. GEF gives you the runtime view; for static
  decompilation reach for `r2ghidra` / `jadx` from the reversing layer.
- **Web / crypto-CTF heavyweights** (sage, z3 standalone) — `angr` bundles a
  z3 you can `import claripy`; full SageMath is out of scope.
