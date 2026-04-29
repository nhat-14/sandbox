# Stage 1: Get Docker binary and compose plugin from official image
FROM docker:28.3.3-cli AS docker-source

# Stage 2: Runtime
FROM alpine:3.18

ARG AGENT_BINARY
ARG AGENT_CONFIG

# 1. Install CA certs and LIBC compatibility for the Docker binary
RUN apk update && apk add --no-cache \
    ca-certificates \
    tzdata \
    gcompat \
    bash

WORKDIR /app

# 2. Copy the agent binary and default config from the build context
COPY --from=bin_dir device-agent /app/device-agent
COPY --from=config_dir . /app/config

# 3. Bring in the Docker CLI
COPY --from=docker-source /usr/local/bin/docker /usr/bin/docker

# 4. Handle the Compose Plugin
# Note: Path is usually /usr/local/lib/... in the official 28.x images
RUN mkdir -p /usr/local/lib/docker/cli-plugins
COPY --from=docker-source /usr/local/libexec/docker/cli-plugins/docker-compose /usr/local/libexec/docker/cli-plugins/docker-compose

# Make the plugin executable
RUN chmod +x /usr/local/libexec/docker/cli-plugins/docker-compose

# Create volume for runtime config overrides
VOLUME ["/app/config", "/app/certs", "/app/data"]

# Use ENTRYPOINT so flags can be passed to the agent easily
ENTRYPOINT ["/app/device-agent"]
# Points to the config inside the /app directory
CMD ["-config", "/app/config/config.yaml"]