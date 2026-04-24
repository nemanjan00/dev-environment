
# Analyst Profile

For inspecting live systems and data stores: pulling logs, querying databases,
poking at S3 buckets and message queues, and slicing structured data. Extends
the `reversing` profile, so all binary/forensics tooling is also available.

## Object storage / S3

- **aws-cli-v2** (`aws`) — official AWS CLI. Supports AWS, and any S3-compatible
  endpoint via `--endpoint-url` (MinIO, Ceph, Wasabi, etc.).
- **s3cmd** — scriptable S3 client, handy for batch ops and non-AWS providers.
- **rclone** — universal remote-storage mover. Handles S3, GCS, Azure, SFTP,
  WebDAV, and 40+ more. Use `rclone lsf`, `rclone cat`, `rclone copy` for quick
  pulls from any configured remote.

## SQL clients

- **postgresql** (`psql`) — PostgreSQL client. Server not started by default;
  this is the CLI only.
- **mariadb-clients** (`mariadb`, `mysqldump`) — MySQL/MariaDB CLI.
- **sqlite** (`sqlite3`) — SQLite CLI for local `.db` / `.sqlite` files.
- **duckdb** — in-process analytical SQL engine. Queries CSV/Parquet/JSON
  directly: `duckdb -c "SELECT count(*) FROM 'data.parquet'"`. Great for
  ad-hoc analysis without loading into a real warehouse.

## Key-value / in-memory

- **valkey** (`valkey-cli`) — Redis-compatible CLI. Arch replaced `redis` with
  `valkey` (BSD fork); `valkey-cli` speaks the same RESP protocol, so use it
  exactly like `redis-cli`: `valkey-cli -h host -p 6379 KEYS '*'`.

## Message queues

- **rabbitmq** — ships `rabbitmqctl` and `rabbitmqadmin` for inspecting /
  managing a RabbitMQ broker. The broker itself is not started; these are
  admin CLIs you point at an existing cluster.

## Log / data triage

- **lnav** — curses log viewer with auto-format detection, SQL queries over
  log contents, and timestamp-aware navigation. `lnav file.log` or tail many:
  `lnav /var/log/*.log`.
- **httpie** (`http`, `https`) — human-friendly HTTP client. Cleaner than
  `curl` for API probing: `http POST api.example.com/v1/x name=foo`.
- **go-yq** (`yq`) — YAML processor with jq-like syntax. Use for reading /
  patching k8s manifests, CI config, etc. (Note: this is the Go implementation
  from mikefarah/yq — syntax differs from the Python `yq` wrapper.)
- **protobuf** (`protoc`) — compile / decode protobuf messages. `protoc
  --decode_raw < msg.bin` is the quickest way to peek at an unknown wire-format
  payload.

## Network debugging

- **bind** — ships `dig`, `nslookup`, `host` for DNS debugging. `dig +short`
  is the fastest way to resolve a record from a script.

## Base tools worth remembering

From the base image (documented in the top-level `CLAUDE.md` — not repeated
here): `jq`, `jc`, `miller` (`mlr`), `ripgrep`, `fzf`, `curl`, `wget`,
`socat`. Combine with the analyst tools above for log/data pipelines, e.g.
`aws s3 cp s3://bucket/data.jsonl - | jq '.event' | sort | uniq -c`.

## Inherited from reversing profile

This profile extends `nemanjan00/dev:reversing`, so all the RE / forensics
tools (radare2, binwalk, volatility3, wireshark-cli / `tshark`, yara, angr,
lief, etc.) are also on PATH. See the Reversing & Forensics section of this
`CLAUDE.md` for details. Useful for analysts who need to pivot from "what's
in this log" into "what's in this binary / pcap / memory dump".
