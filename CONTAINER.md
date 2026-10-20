# QMD container packaging fork

This branch starts at upstream v2.8.3 (`facd35e01359e59d938bc9418e93fb9318addee3`).
Only container packaging is added; QMD source is unchanged. Upstream-tracking
`main` remains separate. Images publish to `ghcr.io/bioshazard/qmd`.

The image builds the checked-out source and includes frozen production dependencies.
It uses Bun's SQLite runtime, CPU mode and no install scripts/optional native addons.
This packaging targets keyword/BM25 deployments. Models/embeddings are not installed
or tested; this image does not promise upstream's full semantic-search feature set.

Default command starts native HTTP MCP on port 8181. Override CLI arguments for
indexing: `docker run ... IMAGE update`. Mount persistent data at `/data`; use UID
1000, readonly root, a writable tmpfs at `/tmp`, and runtime network policy as needed.
The image contains no documents, index, auth credentials or deployment-specific proxy.
OCI labels identify the source revision; deployments should pin the verified digest.

Image CI builds on this branch, tests native HTTP/search/indexing with a synthetic
fixture under nonroot/readonly/no-egress conditions, then publishes. Use container
release tags such as `v2.8.3-container.1`; npm publication is not part of this fork.
