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
- **fzf** — Fuzzy finder, scriptable with `--filter` for non-interactive use.
- **tree** — Directory structure listing. Use `tree -J` for JSON output.
- **curl** / **wget** — HTTP requests (curl for APIs, wget for file downloads).
- **socat** — Multipurpose network relay for socket operations, port forwarding, and proxying.
- **strace** — Trace system calls for debugging process failures. Use `strace -e trace=open,read cmd` to diagnose issues.
- **eza** — Modern `ls` replacement with `--json` output support.

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
