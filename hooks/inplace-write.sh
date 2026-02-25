#!/bin/bash
# After Claude's atomic write (temp file + rename), do an in-place rewrite of the
# same content to preserve the original inode that VSCode's file watcher tracks.
# Fixes file changes not being visible through bind-mounted workspaces.
# See: https://github.com/anthropics/claude-code/issues/25438

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

TMP=$(mktemp)
cp "$FILE_PATH" "$TMP"
cat "$TMP" > "$FILE_PATH" && logger "inplace-write: restored inode for $FILE_PATH"
rm -f "$TMP"
