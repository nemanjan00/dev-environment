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
    rclone \
    mariadb-clients \
    protobuf \
    s3cmd \
    httpie \
    lnav \
    sqlite \
    go-yq \
    bind

USER 1000

# Append profile context to base CLAUDE.md
COPY CLAUDE.md /tmp/profile-claude.md
RUN cat /tmp/profile-claude.md >> /work/CLAUDE.md
