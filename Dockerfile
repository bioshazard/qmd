# Pinned Bun preserves the deployed SQLite runtime/ABI.
FROM oven/bun:1.4.0@sha256:5ff609364c049b54eb0ff560ec96319729a972078ef2c755d758f0c6ef89c2d6 AS build
WORKDIR /opt/qmd
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --ignore-scripts --omit=optional
COPY src ./src
COPY scripts ./scripts
COPY tsconfig.json tsconfig.build.json ./
RUN bun scripts/build.mjs

FROM oven/bun:1.4.0@sha256:5ff609364c049b54eb0ff560ec96319729a972078ef2c755d758f0c6ef89c2d6 AS dependencies
WORKDIR /opt/qmd
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile --ignore-scripts --production --omit=optional \
    && rm -rf /root/.bun/install/cache /home/bun/.bun/install/cache

FROM oven/bun:1.4.0@sha256:5ff609364c049b54eb0ff560ec96319729a972078ef2c755d758f0c6ef89c2d6
WORKDIR /opt/qmd
COPY --from=build /opt/qmd/dist ./dist
COPY --from=dependencies /opt/qmd/node_modules ./node_modules
COPY package.json LICENSE ./
ENV HOME=/data/home XDG_CONFIG_HOME=/data/config XDG_CACHE_HOME=/data/cache \
    QMD_FORCE_CPU=1 QMD_LLAMA_GPU=off DO_NOT_TRACK=1
RUN mkdir -p /data/home /data/config/qmd /data/cache/qmd /data/library \
    && chown -R bun:bun /data
USER bun
EXPOSE 8181
ENTRYPOINT ["bun", "--no-env-file", "/opt/qmd/dist/cli/qmd.js"]
CMD ["mcp", "--http", "--host", "0.0.0.0"]
