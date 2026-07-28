#!/bin/bash

SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"
REPO_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
AGENT_SRC_DIR="$REPO_DIR/.opencode/agent"

GLOBAL_OPENCODE_DIR="$HOME/.config/opencode"
GLOBAL_AGENTS_DIR="$GLOBAL_OPENCODE_DIR/agents"
GLOBAL_CONFIG="$GLOBAL_OPENCODE_DIR/opencode.jsonc"

echo "opencode-general-agent updater"
echo "================================"
echo ""

# Deteksi RC file
case "$SHELL" in
  */zsh)  RC_FILES="$HOME/.zshrc" ;;
  */bash) RC_FILES="$HOME/.bashrc" ;;
  *)      RC_FILES="$HOME/.zshrc $HOME/.bashrc" ;;
esac

# Cek apakah env vars sudah ada di salah satu RC file
ALREADY_CONFIGURED=0
for RC_FILE in $RC_FILES; do
  if grep -q "OPENCODE_9ROUTER_BASE_URL" "$RC_FILE" 2>/dev/null && \
     grep -q "OPENCODE_9ROUTER_API_KEY" "$RC_FILE" 2>/dev/null; then
    ALREADY_CONFIGURED=1
    break
  fi
done

if [ "$ALREADY_CONFIGURED" = "0" ]; then
  echo "Konfigurasi belum ditemukan. Jalankan install terlebih dahulu:"
  echo ""
  echo "  npx @rfazlur/fdnqa"
  echo ""
  exit 1
fi

# Copy agent files terbaru
echo "Memperbarui agent files ke $GLOBAL_AGENTS_DIR ..."
mkdir -p "$GLOBAL_AGENTS_DIR"
find "$AGENT_SRC_DIR" -name "*.md" | while read -r SRC_FILE; do
  REL_PATH="${SRC_FILE#$AGENT_SRC_DIR/}"
  DEST_FILE="$GLOBAL_AGENTS_DIR/$REL_PATH"
  DEST_DIR="$(dirname "$DEST_FILE")"
  mkdir -p "$DEST_DIR"
  cp "$SRC_FILE" "$DEST_FILE"
  echo "  [OK] agents/$REL_PATH"
done
echo ""

# Overwrite opencode.jsonc dengan versi terbaru
echo "Memperbarui provider config $GLOBAL_CONFIG ..."
if [ -f "$GLOBAL_CONFIG" ]; then
  cp "$GLOBAL_CONFIG" "${GLOBAL_CONFIG}.bak"
  echo "  [OK] Config lama dibackup ke: ${GLOBAL_CONFIG}.bak"
fi

cat > "$GLOBAL_CONFIG" << 'JSONEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "9router": {
      "name": "9router",
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "{env:OPENCODE_9ROUTER_BASE_URL}",
        "apiKey": "{env:OPENCODE_9ROUTER_API_KEY}"
      },
      "models": {
        "combo-model-opus": { "name": "combo-model-opus" },
        "combo-model-sonnet": { "name": "combo-model-sonnet" },
        "combo-model-gemini-pro": { "name": "combo-model-gemini-pro" },
        "combo-model-haiku": { "name": "combo-model-haiku" }
      }
    }
  }
}
JSONEOF
echo "  [OK] Provider config 9router diperbarui"
echo ""

echo "Update selesai. Env vars tidak diubah."
echo ""
echo "Jalankan perintah berikut untuk mengaktifkan perubahan (jika ada):"
echo ""
for RC_FILE in $RC_FILES; do
  echo "  source $RC_FILE"
done
echo ""
