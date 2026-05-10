# Dev Environment

This is a Docker-based development environment running Arch Linux.

## Environment

- **Shell**: zsh with zplug plugins
- **Editor**: Neovim with coc.nvim LSP support
- **Multiplexer**: tmux
- **User**: unprivileged user (uid 1000), home at `/work`
- **Projects**: mount to `/work/project`

## Scripting Tools

The following CLI tools are available for use in scripts and pipelines:

- **jq** — JSON processor. Filter, transform, and extract data from JSON.
- **jc** — Converts output of common commands (`ps`, `mount`, `ls`, `dig`, `git log`, etc.) to JSON. Use as `command | jc --command-name | jq ...`.
- **miller** (`mlr`) — Like jq but for CSV, TSV, and tabular data. Use `mlr --csv filter '$col == "val"' file.csv`.
- **ripgrep** (`rg`) — Fast recursive code search with regex support.
- **the_silver_searcher** (`ag`) — Older code-search tool; honors `.gitignore`/`.agignore` and predates `rg`. Prefer `rg` for new scripts; `ag` is here for muscle memory and existing tooling that shells out to it.
- **fzf** — Fuzzy finder, scriptable with `--filter` for non-interactive use.
- **tree** — Directory structure listing. Use `tree -J` for JSON output.
- **curl** / **wget** — HTTP requests (curl for APIs, wget for file downloads).
- **socat** — Multipurpose network relay for socket operations, port forwarding, and proxying.
- **strace** — Trace system calls for debugging process failures. Use `strace -e trace=open,read cmd` to diagnose issues.
- **eza** — Modern `ls` replacement with `--json` output support.
- **file** — Identify file type from contents (magic-based). Use `file -b` for bare output, `file -i` for MIME types; works on unknown blobs, firmware dumps, stripped binaries.
- **xxd** — Hex dump and reverse. `xxd file` to inspect bytes, `xxd -r` to patch back from edited hex, `xxd -s OFF -l LEN` for windowed dumps.
- **diffutils** (`diff`, `cmp`) / **patch** — Generate and apply unified diffs outside of git (e.g. against extracted firmware trees, vendor drops, generated output).
- **man** (`man-db` + `man-pages`) — Offline manpages. Use `man -k <keyword>` (apropos) to search, `man <n> <name>` for a specific section when names collide (e.g. `man 2 open`).

### Archive / compression

`tar`, `gzip`, `xz` ship with the base image. Additionally installed:

- **zip** / **unzip** — ZIP archive create/extract.
- **7zip** (`7z`) — handles 7z, plus zip/tar/gz/xz/bz2/cab/iso and many others;
  the most format-flexible CLI here. Use `7z x file.ext` to extract anything
  it recognises, `7z l file.ext` to list.
- **unrar** — RAR extraction only. RAR creation is non-free and not in the
  official repos; use `zip` or `7z` if you need to *write* an archive.
- **zstd** — Zstandard compress/decompress (`zstd file`, `unzstd file.zst`).
  For tar streams: `tar --zstd -cf out.tar.zst dir/`.

## Package Management

- **System packages**: installed via `pacman` (requires root — not available in this container)
- **Language versions**: managed via [asdf](https://asdf-vm.com/) v0.18.1 (Go binary at `~/.local/bin/asdf`)
  - Node.js is installed via asdf. Use `asdf install nodejs <version>` and `asdf set nodejs <version>` to switch.
  - Python is installed via asdf. Use `asdf install python <version>` and `asdf set python <version>` to switch. `pip` is available.
  - Add new languages with `asdf plugin add <name>` then `asdf install <name> <version>`.
- **Node.js packages**: install globally with `npm install -g <package>` (no root needed, managed by asdf)

## MCP multiplexer (muxmcp)

`muxmcp` is a generic stdio MCP proxy installed globally. It wraps **any** stdio MCP server and exposes it as a multi-instance service. Use it whenever the upstream server is single-session (only one document / binary / connection / project at a time) but you need to hold several open concurrently in one conversation. The wrapped server is opaque to muxmcp — it doesn't care what the server does.

### Configuring an MCP server through muxmcp

Point your MCP client at `muxmcp` and pass the wrapped command (and its args) after `--`:

```json
{
  "mcpServers": {
    "wrapped": {
      "command": "muxmcp",
      "args": ["--", "<upstream-server>", "<upstream-arg>", "..."]
    }
  }
}
```

The proxy only advertises capabilities the wrapped server actually supports — wrapping a tools-only server yields a tools-only proxy.

### Workflow

1. **Spawn an instance per document/binary/session.** Call `spawn_instance` once per item. It returns `{instance_id: N}`. Record which ID maps to which item in your working notes — there is no built-in label.
2. **Open the item in that instance.** Every upstream tool now takes a required `instance_id`. Call the wrapped server's open/load tool with `instance_id: N` to load into that instance.
3. **Route every subsequent call.** Pass the right `instance_id` on every tool call — calls without it are rejected. Mixing IDs across calls is how you cross-reference (e.g. read a function from instance 1, then search for the same constant in instance 2).
4. **Tear down when done.** Call `kill_instance(instance_id)` to free the child. Use `list_instances` to see what's live. If a child crashes the instance is gone — there is no auto-respawn; spawn a fresh one and re-open.

### Resources and prompts

- Resource URIs are rewritten as `mux://<instance_id>/<urlencoded-original>`. Pass the full `mux://...` URI to `resources/read` — muxmcp decodes and routes. Don't hand-construct upstream URIs.
- Prompt names are rewritten as `i<instance_id>__<original>`. Use the rewritten name verbatim when calling `prompts/get`.
- `resources/list`, `resources/templates/list`, and `prompts/list` aggregate across all live instances, so the same logical resource appears once per instance.

### Tips

- **Label instances in prose.** Right after `spawn_instance`, write a one-line note like "instance 3 = <name of the thing you opened>" so the mapping survives mid-session.
- **One item per instance.** Don't reuse an instance for a different item — upstream state (analysis, cursor, auth, working dir) carries over and will mislead you. Kill and respawn.
- **Per-instance work isn't shared.** Any heavy setup on instance 1 (indexing, analysis, auth handshake) doesn't help instance 2. Budget accordingly when opening many.
- **Limitations:** no sampling, no resource subscriptions, no server-initiated logging, no crash recovery. If a tool call hangs, call `list_instances` to confirm the child died, then respawn.

## Interactive shell sessions (shell-session-mcp)

`shell-session-mcp` is an MCP server that runs interactive programs inside a real PTY and keeps them alive across many tool calls. Use it whenever a task wants long-lived state in a `bash`, `gdb`, `radare2`, `python`, `node`, `psql`, or any other REPL/TUI — anything where one-shot `Bash` calls lose context between turns or where the program insists on `isatty(stdin)`. Output is held in a 1 MiB ring buffer per session with a monotonic cursor for incremental polling.

### Configuring it as an MCP server

```json
{
  "mcpServers": {
    "shell": {
      "command": "shell-session-mcp"
    }
  }
}
```

To receive output/exit notifications the client must declare the `logging` capability and call `logging/setLevel` (any level — the server emits at `info`).

### Tools

- `spawn {command, args?, cwd?, env?, cols?, rows?, notify?}` → `{id, pid}`. Starts a PTY-backed process; record which `id` maps to which session in your notes.
- `write {id, data}` → `{id, written}`. Raw bytes to stdin. **You** decide line endings — append `\n` for shells, `\r` for some REPLs. Control chars pass through (`\x03` Ctrl-C, `\x04` EOF).
- `read {id, since?, wait_ms?, max_bytes?, force?}` → `{id, data, cursor, truncated, bytes, exited, exitInfo}`, or `{oversized: true, available, max_bytes, cursor, hint, …}` if the 32 KiB inline guard tripped (cursor not advanced — retry with `force: true`, raise `max_bytes`, or use `read_to_file`).
- `read_to_file {id, path, since?, append?, wait_ms?}` → metadata only; bulk output goes to disk, not into context. Use it for build logs, gdb dumps, fuzzer output, etc.
- `set_notifications {id, enabled}` — toggle push of new-output notifications. Exit notifications fire regardless.
- `resize {id, cols, rows}` — propagates `SIGWINCH`, useful for full-screen TUIs.
- `kill {id, signal?}` — default `SIGTERM`; the entry survives exit so you can still `read` final output and inspect `exitInfo`.
- `list` / `info {id}` / `remove {id}` — registry inspection and cleanup.

### Notification payloads

`notifications/message` with `logger: "shell-session-mcp"`, level `info`, `params.data`:
- `{type: "output", id, chunk, cursor}` — only if `notify`/`set_notifications` enabled it.
- `{type: "exit", id, exitCode, signal}` — always sent.

### Tips

- **One process per session.** No auto-respawn on crash; `spawn` a fresh one if the child dies.
- **Drain large output to disk.** Multi-megabyte build/fuzzer/debugger output should go through `read_to_file`, not `read` — keeps the conversation context small.
- **Pick the right line ending.** Most shells want `\n`; some REPLs (notably ones that read line-buffered via readline on a raw tty) want `\r`. If a `write` seems to go nowhere, try the other.
- **UTF-8 only.** Binary stdin/stdout isn't directly representable; base64 in your own protocol layer if you need hex-clean transport.

## Persistence

Only `/work/project` (the host cwd) and `/work/.claude` (your config/memory) persist across container runs — both are host bind-mounts. Everything else (installed packages, asdf languages, `~/.config/*`, shell/editor configs, files written outside `/work/project`) is ephemeral and vanishes on container exit.

You own everything ephemeral — install, switch, or reconfigure asdf languages, npm globals, Neovim/coc extensions, or any other tooling without asking. If something needs to survive the container, keep it inside `/work/project`.

## Key Paths

- `~/.config/nvim` — Neovim configuration
- `~/.config/coc` — coc.nvim extensions
- `~/.local/bin` — user binaries (asdf)
- `~/.asdf` — asdf data (plugins, installs, shims)
- `~/.zsh/index.zsh` — zsh configuration entrypoint
- `~/.tmux.conf` — tmux configuration
