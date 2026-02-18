# dev-sandbox

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
mv sandbox ~/.sandbox
```

### 2. Add the bin directory to your PATH

```bash
# in ~/.zshrc or ~/.bashrc
export PATH="$HOME/.sandbox/bin:$PATH"
```

Then reload: `source ~/.zshrc`

### 3. Build the sandbox image (once)

```bash
sandbox --build bash
# ctrl-d to exit after it builds
```

### 4. Ensure Colima socket path is correct

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
sandbox claude              # Claude Code
sandbox codex               # OpenAI Codex
sandbox bash                # Interactive shell for debugging
sandbox npm run dev         # Any arbitrary command

# Options
sandbox --build claude      # Rebuild image first
sandbox --no-proxy claude   # Skip Docker access entirely
sandbox --image my-img bash # Use a custom image
```

## API keys

The launcher automatically forwards these env vars if set on the host:
- `ANTHROPIC_API_KEY`
- `OPENAI_API_KEY`
- `GITHUB_TOKEN`
- `NPM_TOKEN`

Set them in your shell profile as usual — no extra config needed.

## Rebuilding the image

If you add tools to the Dockerfile:

```bash
sandbox --build bash
```

Or manually:
```bash
docker build -t dev-sandbox:latest ~/.sandbox/
```

## Stopping the proxy

The proxy runs persistently (restarts on Colima restart automatically).
To stop it manually:

```bash
docker compose -f ~/.sandbox/docker-compose.yml down
```

## Customizing the Dockerfile

The included Dockerfile has Node.js (LTS), Python 3, Docker CLI, Claude Code,
and Codex. Add whatever your projects need — language runtimes, CLIs, etc.
The image is shared across all projects so keep it general-purpose.
