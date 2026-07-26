#!/bin/bash

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"
REPO_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
AGENT_SRC_DIR="$REPO_DIR/.opencode/agent"

GLOBAL_OPENCODE_DIR="$HOME/.config/opencode"
GLOBAL_AGENTS_DIR="$GLOBAL_OPENCODE_DIR/agents"
GLOBAL_CONFIG="$GLOBAL_OPENCODE_DIR/opencode.jsonc"

case "$SHELL" in
  */zsh)  RC_FILES="$HOME/.zshrc" ;;
  */bash) RC_FILES="$HOME/.bashrc" ;;
  *)      RC_FILES="$HOME/.zshrc $HOME/.bashrc" ;;
esac

echo "opencode-general-agent uninstaller"
echo "==================================="
echo ""
echo "Berikut yang akan dihapus:"
echo "  - Agent files di $GLOBAL_AGENTS_DIR"
echo "  - Provider config $GLOBAL_CONFIG"
echo "  - Env vars OPENCODE_9ROUTER_* dari RC file"
echo ""
printf "Lanjutkan uninstall? [y/N] "
read -r CONFIRM
echo ""

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Uninstall dibatalkan."
  exit 0
fi

# Hapus agent files yang matching dengan source repo
echo "Menghapus agent files dari $GLOBAL_AGENTS_DIR ..."
find "$AGENT_SRC_DIR" -name "*.md" | while read -r SRC_FILE; do
  REL_PATH="${SRC_FILE#$AGENT_SRC_DIR/}"
  DEST_FILE="$GLOBAL_AGENTS_DIR/$REL_PATH"
  if [ -f "$DEST_FILE" ]; then
    rm -f "$DEST_FILE"
    echo "  [OK] Dihapus: agents/$REL_PATH"
  fi
done

# Hapus subdirektori kosong di agents dir
find "$GLOBAL_AGENTS_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null
echo ""

# Hapus opencode.jsonc
echo "Menghapus provider config $GLOBAL_CONFIG ..."
if [ -f "$GLOBAL_CONFIG" ]; then
  rm -f "$GLOBAL_CONFIG"
  echo "  [OK] $GLOBAL_CONFIG dihapus"
  if [ -f "${GLOBAL_CONFIG}.bak" ]; then
    mv "${GLOBAL_CONFIG}.bak" "$GLOBAL_CONFIG"
    echo "  [OK] ${GLOBAL_CONFIG}.bak direstore ke $GLOBAL_CONFIG"
  fi
else
  echo "  [SKIP] File tidak ditemukan"
fi
echo ""

# Strip env vars dari RC files
for RC_FILE in $RC_FILES; do
  if [ ! -f "$RC_FILE" ]; then
    continue
  fi
  echo "Membersihkan env vars dari $RC_FILE ..."
  cp "$RC_FILE" "${RC_FILE}.bak"
  sed -i.tmp \
    -e '/# opencode-general-agent/d' \
    -e '/export OPENCODE_9ROUTER_BASE_URL=/d' \
    -e '/export OPENCODE_9ROUTER_API_KEY=/d' \
    "$RC_FILE"
  rm -f "${RC_FILE}.tmp"
  echo "  [OK] Env vars dihapus (backup: ${RC_FILE}.bak)"
  echo ""
done

echo "Selesai. Jalankan perintah berikut untuk mengaktifkan perubahan:"
echo ""
for RC_FILE in $RC_FILES; do
  echo "  source $RC_FILE"
done
echo ""
