#!/usr/bin/env bash
set -euo pipefail
image="${1:?image required}"
work=$(mktemp -d)
name="qmd-image-smoke-${RANDOM}"
trap 'docker rm -f "$name" >/dev/null 2>&1 || true; rm -rf "$work"' EXIT
mkdir -p "$work/library" "$work/config/qmd" "$work/cache" "$work/home"
printf '# Container fixture\n\nDeterministic blueberry retrieval.\n' > "$work/library/fixture.md"
cat > "$work/config/qmd/index.yml" <<'CONFIG'
collections:
  fixture:
    path: /data/library
    pattern: "**/*.md"
CONFIG
chmod -R a+rwX "$work"
docker run --rm --network none --read-only --tmpfs /tmp:rw,size=64m \
  -v "$work:/data" "$image" update
docker run --rm --network none --read-only --tmpfs /tmp:rw,size=64m \
  -v "$work:/data" "$image" search blueberry --json > "$work/result.json"
python3 - "$work/result.json" <<'CHECK'
import json,sys
assert json.load(open(sys.argv[1])), 'Empty fixture search'
CHECK
docker run -d --name "$name" --network none --read-only --tmpfs /tmp:rw,size=64m \
  -v "$work:/data" "$image"
for attempt in $(seq 1 30); do
  if docker exec "$name" bun -e 'const r=await fetch("http://127.0.0.1:8181/health");if(!r.ok)process.exit(1)' >/dev/null 2>&1; then break; fi
  sleep 1
done
docker exec "$name" bun -e 'if(process.getuid()!==1000)throw Error("uid");const r=await fetch("http://127.0.0.1:8181/health");if(!r.ok)throw Error("health");console.log("Native nonroot HTTP and fixture search passed")'
