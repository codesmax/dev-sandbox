#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${HOME:-}" ]]; then
  mkdir -p "$HOME/.claude"

  # ─── Anthropic skills ────────────────────────────────────────────────────────
  # Clone on first start, pull on subsequent starts to keep skills up to date.
  # Symlinked to ~/.claude/skills so Claude Code picks them up automatically.
  if [[ -d "$HOME/.claude/anthropic-skills/.git" ]]; then
    git -C "$HOME/.claude/anthropic-skills" pull --ff-only --quiet || true
  else
    git clone --depth=1 --quiet \
      https://github.com/anthropics/skills.git \
      "$HOME/.claude/anthropic-skills" || true
  fi

  if [[ ! -e "$HOME/.claude/skills" && -d "$HOME/.claude/anthropic-skills/skills" ]]; then
    ln -s "$HOME/.claude/anthropic-skills/skills" "$HOME/.claude/skills"
  fi

  # ─── VoiceMode plugin ────────────────────────────────────────────────────────
  # Install once into the home volume; persists across container restarts.
  # -y assumes yes to any prompts; || true so a failure doesn't abort startup.
  if ! claude plugin list 2>/dev/null | grep -q voicemode; then
    claude plugin marketplace add mbailey/voicemode || true
    claude plugin install voicemode@voicemode || true
  fi

  # ─── VoiceMode MCP config ────────────────────────────────────────────────────
  # Point Claude Code at VoiceMode running on the host over HTTP. Audio stays on
  # the host where it has direct hardware access; the container just talks to it
  # over the network. host.docker.internal resolves to the host on Mac
  # automatically and on Linux via --add-host in the sandbox run args.
  # Only adds the entry if not already present, to preserve any user edits.
  if ! claude mcp list 2>/dev/null | grep -q voicemode; then
    claude mcp add --scope user --transport http voicemode \
      http://host.docker.internal:8765/mcp || true
  fi
fi

exec "$@"
