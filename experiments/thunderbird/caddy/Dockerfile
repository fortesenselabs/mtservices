FROM golang:1.14-buster AS caddy-build
WORKDIR /src
RUN echo 'module caddy' > go.mod && \
    echo 'require github.com/caddyserver/caddy/v2 v2.1.1' >> go.mod && \
    echo 'require github.com/mholt/caddy-webdav v0.0.0-20200523051447-bc5d19941ac3' >> go.mod
RUN echo 'package main' > caddy.go && \
    echo 'import caddycmd "github.com/caddyserver/caddy/v2/cmd"' >> caddy.go && \
    echo 'import _ "github.com/caddyserver/caddy/v2/modules/standard"' >> caddy.go && \
    echo 'import _ "github.com/mholt/caddy-webdav"' >> caddy.go && \
    echo 'func main() { caddycmd.Main() }' >> caddy.go
RUN go build -o /bin/caddy .

FROM debian:buster

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends gosu && \
    rm -rf /var/lib/apt/lists

COPY --from=caddy-build /bin/caddy /usr/local/bin/
COPY Caddyfile /etc/
EXPOSE 8080

RUN groupadd --gid 1000 app && \
    useradd --home-dir /data --shell /bin/bash --uid 1000 --gid 1000 app && \
    mkdir -p /data
VOLUME /data

WORKDIR /data
CMD ["sh", "-c", "chown app:app /data && exec gosu app /usr/local/bin/caddy run -adapter caddyfile -config /etc/Caddyfile"]