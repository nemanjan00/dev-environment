FROM nemanjan00/dev:reversing

USER 0

# Install "analyst" related packages (AWS S3, Postgres, Redis, RabbitMQ)
RUN pacman -Syu --noconfirm \
    aws-cli-v2 \
    postgresql \
    redis \
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