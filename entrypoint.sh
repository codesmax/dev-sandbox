#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${HOME:-}" ]]; then
  # ─── Claude Code native binary ───────────────────────────────────────────────
  # Installed into the persistent home volume so the binary survives container
  # restarts and auto-updates (which write back to the same path) actually stick.
  if [[ ! -x "$HOME/.local/bin/claude" ]]; then
    curl -fsSL https://claude.ai/install.sh | bash || true
  fi

  # Update PATH to include ~/.local/bin where the claude binary is installed
  export PATH="$HOME/.local/bin:$PATH"

  [[ ! -d "$HOME/.claude" ]] && mkdir -p "$HOME/.claude"

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
fi

exec "$@"
