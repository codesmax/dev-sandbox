FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Core utilities + build essentials for native npm/python packages
# Docker CLI only (no daemon — we talk to the socket proxy)
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    jq \
    unzip \
    xz-utils \
    build-essential \
    ca-certificates \
    libssl-dev \
    libffi-dev \
    ripgrep \
    docker.io \
    docker-compose \
    # Python (for projects that need it at the system level, mise handles versioned installs)
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# mise — installed to /usr/local/bin so it's on PATH for any user
# Data dir set to /opt/mise so tool installs are world-readable
ENV MISE_DATA_DIR=/opt/mise
ENV MISE_CONFIG_DIR=/etc/mise
RUN curl https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise bash

# Activate mise for all bash sessions
RUN echo 'eval "$(mise activate bash)"' >> /etc/bash.bashrc

# Install a default Node LTS via mise so claude-code/codex are available immediately
# without needing a .mise.toml in the project
RUN mise use --global node@lts && mise install

# Other AI agent CLIs
# Claude Code is installed at runtime by entrypoint.sh into the persistent home
# volume so that auto-updates survive container restarts.
RUN mise exec -- npm install -g @openai/codex \
    && chmod -R a+rX /opt/mise

# Entrypoint handles runtime home-volume initialisation (skills, plugins, MCP config)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Any UID can run in this container — no fixed sandbox user needed
WORKDIR /workspace

ENV PATH="/opt/mise/shims:$PATH"

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
