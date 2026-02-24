#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${HOME:-}" ]]; then
  mkdir -p "$HOME/.claude"

  # ─── Claude Code native binary ───────────────────────────────────────────────
  # Installed into the persistent home volume so the binary survives container
  # restarts and auto-updates (which write back to the same path) actually stick.
  # The installer puts the binary at ~/.claude/local/claude and appends a PATH
  # export to ~/.bashrc — both of which live on the home volume.
  if [[ ! -x "$HOME/.claude/local/claude" ]]; then
    curl -fsSL https://claude.ai/install.sh | bash || true
  fi
  # Put the home-volume binary on PATH now so subsequent claude calls below work.
  export PATH="$HOME/.claude/local:$PATH"

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
