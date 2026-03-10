#!/usr/bin/env sh
# Railway sets the PORT environment variable; map it to SearXNG's BIND_ADDRESS.
# SearXNG's image honours BIND_ADDRESS (default: [::]:8080).
# We always listen on 0.0.0.0 so the Railway router can reach the container.
export BIND_ADDRESS="0.0.0.0:${PORT:-8080}"
exec /sbin/tini -- /usr/local/searxng/searxng-run
