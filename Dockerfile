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
    docker.io \
    docker-compose \
    # Python (for projects that need it at the system level, mise handles versioned installs)
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Non-root user (UID/GID overridden at runtime via --user, but we need the home dir)
RUN useradd -m -s /bin/bash -u 1000 sandbox

# mise — handles Node, Python, Ruby, Go, Rust, Java, etc. per project via .mise.toml
# Installed as root so it's available system-wide, but runs as the sandbox user
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:/home/sandbox/.local/bin:$PATH"

# Activate mise for all bash sessions
RUN echo 'eval "$(/root/.local/bin/mise activate bash)"' >> /etc/bash.bashrc

# Install a default Node LTS via mise so claude-code/codex are available immediately
# without needing a .mise.toml in the project
RUN mise use --global node@lts && mise install

# AI agent CLIs — installed after mise sets up Node
RUN mise exec -- npm install -g @anthropic-ai/claude-code @openai/codex

USER sandbox
WORKDIR /workspace

# Ensure mise shims are on PATH for the sandbox user too
ENV PATH="/home/sandbox/.local/share/mise/shims:/root/.local/share/mise/shims:$PATH"
