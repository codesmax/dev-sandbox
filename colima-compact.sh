#!/usr/bin/env bash
# Compact a Colima VM's disk by trimming free space inside the VM.
# On macOS with APFS, the raw datadisk is a sparse file — fstrim causes
# the kernel to punch holes and reclaim host disk space automatically.
# No qemu-img conversion needed.
#
# Usage: colima-compact.sh [-i INSTANCE] [-h]

set -euo pipefail

# Extend PATH with common Homebrew locations so that colima is found even when
# the script is invoked from a launcher that doesn't inherit the interactive
# shell PATH (e.g. a cron job, a GUI app, or a non-login shell).
export PATH="/usr/homebrew/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

INSTANCE="colima"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-i INSTANCE] [-h]

Compact a Colima VM disk to reclaim host disk space.

Steps performed:
  1. Report current disk usage (host sparse file size)
  2. fstrim inside the VM (punches holes in the APFS sparse file)
  3. Report space reclaimed

OPTIONS:
  -i INSTANCE   Colima instance name (default: $INSTANCE)
  -h            Display this help and exit
EOF
}

while getopts "hi:" OPTION; do
  case $OPTION in
    i) INSTANCE=$OPTARG ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# ── Preflight ─────────────────────────────────────────────────────────────────

DISK="$HOME/.colima/_lima/_disks/$INSTANCE/datadisk"

if [[ ! -f "$DISK" ]]; then
  echo "error: disk image not found at $DISK" >&2
  exit 1
fi

if ! colima status "$INSTANCE" &>/dev/null; then
  echo "error: Colima instance '$INSTANCE' is not running" >&2
  exit 1
fi

# ── Step 1: Baseline ──────────────────────────────────────────────────────────

SIZE_BEFORE=$(du -sh "$DISK" | cut -f1)
echo "==> Disk usage before: $SIZE_BEFORE  ($DISK)"

# ── Step 2: Trim free space inside the VM ─────────────────────────────────────

echo "==> Trimming free space inside VM '$INSTANCE'..."
colima ssh "$INSTANCE" -- sudo fstrim -av

# ── Step 3: Report ────────────────────────────────────────────────────────────

SIZE_AFTER=$(du -sh "$DISK" | cut -f1)
echo ""
echo "==> Done."
echo "    Before: $SIZE_BEFORE"
echo "    After:  $SIZE_AFTER"
