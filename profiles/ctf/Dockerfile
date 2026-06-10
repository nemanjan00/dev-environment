FROM nemanjan00/dev:reversing

USER 0

# Binary-exploitation / CTF layer on top of `reversing` (which already brings
# gdb, radare2, capstone/keystone/unicorn, angr, pycryptodome and the network
# recon tools). Here we add the pwn-specific bits:
#   patchelf — swap the interpreter / RPATH of a challenge binary so it runs
#              against the libc the remote uses (the classic ret2libc setup).
#   ruby     — runtime for the one_gadget / seccomp-tools gems below.
RUN pacman -Syu --noconfirm \
    patchelf \
    ruby

USER 1000

# pwntools — the exploit-dev framework (`from pwn import *`): process/remote
# I/O, cyclic patterns, ELF/ROP helpers, shellcraft, checksec.
# ROPgadget / ropper — gadget finders for ROP/JOP chains.
# (angr for symbolic execution already comes from the reversing layer.)
RUN pip install --no-cache-dir pwntools ROPgadget ropper

# Ruby gems install into a fixed GEM_HOME so their CLI entry points land on
# PATH regardless of the active ruby version.
#   one_gadget      — find the magic one-shot execve("/bin/sh") gadgets in libc.
#   seccomp-tools   — dump a binary's seccomp-bpf filter (`seccomp-tools dump`).
ENV GEM_HOME=/work/.gem
ENV PATH="/work/.gem/bin:${PATH}"
RUN gem install --no-document one_gadget seccomp-tools

# GEF — GDB Enhanced Features. Pure-Python, sourced from ~/.gdbinit; the
# canonical "just curl it" install. Turns gdb into a pwn-aware debugger
# (heap visualisation, `checksec`, `pattern`, `ropper`/`got`/`vmmap`, etc).
RUN curl -fsSL https://raw.githubusercontent.com/hugsy/gef/main/gef.py \
        -o /work/.gef.py && \
    echo 'source /work/.gef.py' >> /work/.gdbinit

# Bundle the `pwn` Claude skill. It lands in /work/skills/.claude/skills/,
# the build-time skills dir the wrappers auto-load with `--add-dir /work/skills`
# (see root CLAUDE.md → "Shipping a Claude skill in a profile"). This path is
# outside the bind-mounted ~/.claude, so the skill is always available with
# zero setup and nothing written to the host.
COPY --chown=1000:1000 skills/ /work/skills/.claude/skills/

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
