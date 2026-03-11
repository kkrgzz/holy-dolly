ARG DNS_PLUGIN=porkbun

FROM caddy:builder AS builder
ARG DNS_PLUGIN
RUN xcaddy build --output /usr/bin/caddy --with github.com/caddy-dns/${DNS_PLUGIN}

FROM caddy:latest
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
