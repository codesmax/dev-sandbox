# boxout

Isolated container environment for development.
Designed for use with AI coding agents, e.g. Claude Code, Codex.
Agents get full access to your project directory and outbound network,
with Docker/Compose access via a filtered socket proxy — and nothing else.

## What's isolated

| Access | Agent sees |
|--------|-----------|
| Filesystem | Current project dir only (`/workspace`) |
| Network | Full outbound internet |
| Docker | Compose up/down/build/logs/exec (no delete/prune) |
| Host filesystem | ✗ Not visible |
| Other projects | ✗ Not visible |
| Docker daemon | Via proxy only (destructive ops blocked) |

## Setup

### 1. Clone / place this directory

```bash
# e.g. keep it in your home dir
mv boxout ~/.boxout
```

### 2. Add to your PATH

```bash
# in ~/.zshrc or ~/.bashrc
export PATH="$HOME/.boxout:$PATH"
```

Then reload: `source ~/.zshrc`

### 3. Build the boxout image (once)

```bash
boxout --build bash
# ctrl-d to exit after it builds
```

### 4. Ensure Docker socket path is correct

The proxy mounts `/var/run/docker.sock`. On Colima this is usually symlinked
correctly, but verify:

```bash
ls -la /var/run/docker.sock
# should point to ~/.colima/default/docker.sock or exist directly
```

If not symlinked, either add the symlink or edit `docker-compose.yml` to use
the full Colima socket path:
```yaml
volumes:
  - ~/.colima/default/docker.sock:/var/run/docker.sock:ro
```

## Usage

```bash
# From any project directory:
boxout claude              # Claude Code
boxout codex               # OpenAI Codex
boxout bash                # Interactive shell for debugging
boxout npm run dev         # Any arbitrary command

# Options
boxout --build claude      # Rebuild image first
boxout --no-proxy claude   # Skip Docker access entirely
boxout --image my-img bash # Use a custom image

# Lifecycle
boxout stop               # Stop the socket proxy
boxout clean              # Stop the proxy and remove all volumes
```

## API keys

The launcher automatically forwards these env vars if set on the host:
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `GITHUB_TOKEN`
- `NPM_TOKEN`

Set them in your shell profile as usual — no extra config needed.

## Config persistence

Agent config (auth tokens, settings) and any other files written to `$HOME`
(`/home/boxout`) inside the container are stored in a named Docker volume
(`boxout-home`) rather than bind-mounted from the host. This means:

- Config persists across boxout runs — authenticate once per volume
- Agents cannot read or modify your host home directory
- The container home is fully isolated from your host environment

To reset the container home (e.g. to force re-auth):
```bash
boxout clean
```

Or to remove just the home volume without stopping the proxy:
```bash
docker volume rm boxout-home
```

## Rebuilding the image

If you update the Dockerfile:

```bash
boxout --build bash
```

Or manually:
```bash
docker build -t boxout:latest ~/.boxout/
```

## Stopping the proxy

The proxy runs persistently in the background (restarts automatically on
Docker/Colima restart). To manage it:

```bash
boxout stop               # stop the proxy, keep volumes
boxout clean              # stop the proxy and remove all volumes
```

## Customizing the Dockerfile

The included Dockerfile provides:
- **Node.js LTS** (via mise) + Claude Code + Codex CLI
- **Python 3** (system), with per-project versions managed by mise
- **Docker CLI + Compose** (Debian-packaged)
- **ripgrep**, jq, git, curl, and standard build tools

Add whatever your projects need — language runtimes, CLIs, etc.
The image is shared across all projects so keep it general-purpose.
Runtime versions (Node, Python, Go, etc.) are better handled per-project
via a `.mise.toml` file, which boxout picks up automatically.
