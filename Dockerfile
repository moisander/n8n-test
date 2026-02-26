ARG NODE_VERSION=24.13.1
ARG N8N_VERSION=snapshot

# ==============================================================================
# Stage 1: Build from source (conditional)
#
# When compiled/ is already present in the build context (e.g. from a prior
# `pnpm build:deploy`), the builder simply passes it through to stage 2.
# Otherwise it performs a full build inside Docker so that standalone
# `docker build` works without any pre-build step.
# ==============================================================================
FROM node:22-alpine AS builder

WORKDIR /build
COPY . .

ENV CI=true
RUN if [ ! -f compiled/build-manifest.json ]; then \
      apk add --no-cache python3 make g++ git && \
      corepack enable && \
      corepack prepare pnpm@10.22.0 --activate && \
      pnpm install --frozen-lockfile && \
      N8N_SKIP_LICENSES=true node scripts/build-n8n.mjs; \
    fi

# ==============================================================================
# Stage 2: Production image
# ==============================================================================
FROM n8nio/base:${NODE_VERSION}

ARG N8N_VERSION
ARG N8N_RELEASE_TYPE=dev
ENV NODE_ENV=production
ENV N8N_RELEASE_TYPE=${N8N_RELEASE_TYPE}
ENV SHELL=/bin/sh

WORKDIR /home/node

COPY --from=builder /build/compiled /usr/local/lib/node_modules/n8n
COPY docker/images/n8n/docker-entrypoint.sh /

RUN cd /usr/local/lib/node_modules/n8n && \
    npm rebuild sqlite3 && \
    ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
    mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node && \
    rm -rf /root/.npm /tmp/*

EXPOSE 5678/tcp
USER node
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

LABEL org.opencontainers.image.title="n8n" \
      org.opencontainers.image.description="Workflow Automation Tool" \
      org.opencontainers.image.source="https://github.com/n8n-io/n8n" \
      org.opencontainers.image.url="https://n8n.io" \
      org.opencontainers.image.version=${N8N_VERSION}
