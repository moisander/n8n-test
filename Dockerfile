ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION} AS n8n-upstream

FROM node:24-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

COPY --from=n8n-upstream /usr/local/lib/node_modules/n8n /usr/local/lib/node_modules/n8n
RUN ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n

RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node

ENV NODE_ENV=production
ENV SHELL=/bin/sh
ENV DB_TYPE=postgresdb
ENV N8N_PORT=5678

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /home/node
USER node

ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]
