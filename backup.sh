#!/usr/bin/env bash
set -euo pipefail

EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
DCONF_PATH="/org/gnome/shell/extensions"

usage() {
  cat <<EOF
Usage:
  $0 backup  [backup_dir]      # Create a backup
  $0 restore <backup_dir>      # Restore from backup
  $0 delete                    # Delete all extensions and configs
  $0 prune | delete-old        # Remove configs of uninstalled extensions
  $0 help

Example:
  $0 backup /mnt/hdd
  $0 restore /mnt/hdd/gnome-ext-backup_2025-07-25_23-45-12
EOF
}

require_cmd() {
  for c in dconf tar date; do
    command -v "$c" >/dev/null 2>&1 || { echo "Error: '$c' command not found."; exit 1; }
  done
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Warning: 'sudo' not found. You might not be able to write to system directories."
  fi
}

backup() {
  local TARGET_DIR="${1:-$PWD/gnome-ext-backup_$(date +%F_%H-%M-%S)}"
  mkdir -p "$TARGET_DIR"

  echo "[1/3] Exporting extension settings from dconf..."
  dconf dump "$DCONF_PATH"/ > "$TARGET_DIR/gnome-extensions.conf" || true

  echo "[2/3] Archiving extension directory..."
  if [ -d "$EXT_DIR" ]; then
    tar -czf "$TARGET_DIR/extensions.tar.gz" -C "$EXT_DIR" .
  else
    echo "Warning: $EXT_DIR not found, only settings will be backed up."
  fi

  echo "[3/3] Writing manifest..."
  cat > "$TARGET_DIR/manifest.txt" <<MAN
date=$(date -Iseconds)
user=$USER
ext_dir=$EXT_DIR
dconf_path=$DCONF_PATH
MAN

  echo "✔ Backup complete: $TARGET_DIR"
}

restore() {
  local SRC_DIR="${1:-}"
  if [ -z "$SRC_DIR" ]; then
    echo "Error: You must specify a backup directory for restore."
    usage; exit 1
  fi
  if [ ! -d "$SRC_DIR" ]; then
    echo "Error: '$SRC_DIR' directory not found."
    exit 1
  fi

  mkdir -p "$EXT_DIR"

  echo "[1/2] Restoring extensions..."
  if [ -f "$SRC_DIR/extensions.tar.gz" ]; then
    tar -xzf "$SRC_DIR/extensions.tar.gz" -C "$EXT_DIR"
  else
    echo "  -> extensions.tar.gz not found (skipping)."
  fi

  echo "[2/2] Loading dconf settings..."
  if [ -f "$SRC_DIR/gnome-extensions.conf" ]; then
    dconf load "$DCONF_PATH"/ < "$SRC_DIR/gnome-extensions.conf"
  else
    echo "  -> gnome-extensions.conf not found (skipping)."
  fi

  echo "Done. Don't forget to restart GNOME Shell."
}

delete_all() {
  echo "⚠ This will delete ALL extensions and configuration settings! Are you sure? (y/N)"
  read -r ans
  if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
    echo "[1/2] Clearing extension directory: $EXT_DIR"
    rm -rf "$EXT_DIR"/* || true
    echo "[2/2] Resetting dconf settings..."
    dconf reset -f "$DCONF_PATH"/ || true
    echo "✔ All extensions and settings deleted."
  else
    echo "Operation cancelled."
  fi
}

prune_old_configs() {
  echo "[*] Cleaning dconf configs for uninstalled extensions..."
  local removed=0 kept=0
  local list
  list=$(dconf list "$DCONF_PATH"/ 2>/dev/null || true)

  if [ -z "$list" ]; then
    echo "No config found."
    return 0
  fi

  if [ ! -d "$EXT_DIR" ]; then
    for key in $list; do
      key="${key%/}"
      echo "🗑 Removing (extensions folder missing): $key"
      dconf reset -f "$DCONF_PATH/$key/" || true
      removed=$((removed+1))
    done
    echo "Summary: $removed removed, $kept kept."
    return 0
  fi

  for key in $list; do
    key="${key%/}"
    if ls "$EXT_DIR" | grep -F -q -- "$key"; then
      echo "✔ Keeping: $key"
      kept=$((kept+1))
    else
      echo "🗑 Removing: $key"
      dconf reset -f "$DCONF_PATH/$key/" || true
      removed=$((removed+1))
    fi
  done

  echo "Summary: $removed removed, $kept kept."
  echo "For a fresh backup, you can now run: $0 backup"
}

main() {
  require_cmd
  case "${1:-}" in
    backup)              shift; backup "${1:-}" ;;
    restore)             shift; restore "${1:-}" ;;
    delete)              delete_all ;;
    prune|delete-old)    prune_old_configs ;;
    help|"")             usage ;;
    *)                   echo "Invalid argument: $1"; usage; exit 1 ;;
  esac
}

main "$@"

