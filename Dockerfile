ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION}

USER root

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV DB_TYPE=postgresdb

USER node
WORKDIR /home/node

ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]
