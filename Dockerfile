# Railway Deployment — use searxng/searxng as the base image because it already
# bundles uwsgi, tini, and all Python dependencies needed to run SearXNG.
# The official image's default entrypoint is:
#   /sbin/tini -- /usr/local/searxng/searxng-run
# We wrap it with start.sh so that Railway's $PORT variable is translated to
# SearXNG's BIND_ADDRESS before the process starts.
# Using :latest keeps parity with docker-compose.yaml; pin to a date-tag
# (e.g. searxng/searxng:2024.11.2-1) for fully reproducible production builds.
FROM searxng/searxng:latest

# Copy your custom SearXNG configuration into the container.
# This mirrors the docker-compose volume mount: ./searxng:/etc/searxng
COPY ./searxng /etc/searxng

# Copy the Railway startup wrapper script.
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Railway dynamically assigns a port via $PORT (default 8080).
ENV PORT=8080
EXPOSE 8080

# Use the wrapper so $PORT is picked up before the app starts.
CMD ["/start.sh"]
