FROM nemanjan00/dev:reversing

USER 0

# Data / infra client tooling for analyst work (S3, SQL, Redis, RabbitMQ,
# columnar analytics, log triage, network debugging).
# Note: `redis` was replaced by `valkey` in Arch — valkey is a drop-in fork
# that provides the `redis` virtual package and ships `valkey-cli` (the
# renamed `redis-cli`, same wire protocol).
RUN pacman -Syu --noconfirm \
    aws-cli-v2 \
    postgresql \
    valkey \
    rabbitmq \
    duckdb \
    dsq \
    rclone \
    mariadb-clients \
    protobuf \
    s3cmd \
    httpie \
    websocat \
    lnav \
    sqlite \
    go-yq \
    bind

USER 1000

# MongoDB shell — not in Arch [extra]; install the official npm release and
# symlink into ~/.local/bin so the binary survives asdf nodejs version switches
# (asdf shims are per-version; the symlink pins the current resolution).
RUN npm install -g mongosh && \
    ln -sf "$(asdf which mongosh)" /work/.local/bin/mongosh

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
