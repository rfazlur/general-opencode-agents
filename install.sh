#!/bin/sh

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_SRC_DIR="$REPO_DIR/.opencode/agent"
PROVIDER_SRC="$REPO_DIR/.opencode/opencode.json"

GLOBAL_OPENCODE_DIR="$HOME/.config/opencode"
GLOBAL_AGENTS_DIR="$GLOBAL_OPENCODE_DIR/agents"
GLOBAL_CONFIG="$GLOBAL_OPENCODE_DIR/opencode.jsonc"

echo "opencode-general-agent installer"
echo "================================="
echo ""

# Deteksi RC file berdasarkan shell aktif
case "$SHELL" in
  */zsh)  RC_FILES="$HOME/.zshrc" ;;
  */bash) RC_FILES="$HOME/.bashrc" ;;
  *)      RC_FILES="$HOME/.zshrc $HOME/.bashrc" ;;
esac

# Input interaktif baseURL
printf "Masukkan baseURL server 9router kamu (contoh: http://100.97.237.10:20128/v1): "
read -r BASE_URL

if [ -z "$BASE_URL" ]; then
  echo "[ERROR] baseURL tidak boleh kosong. Installer dibatalkan."
  exit 1
fi

echo ""

# Input interaktif API key
printf "Masukkan API key 9router kamu: "
read -r API_KEY

if [ -z "$API_KEY" ]; then
  echo "[ERROR] API key tidak boleh kosong. Installer dibatalkan."
  exit 1
fi

echo ""

# Buat direktori global jika belum ada
mkdir -p "$GLOBAL_AGENTS_DIR"

# Copy semua agent .md files ke ~/.config/opencode/agents/ (rekursif, pertahankan struktur)
echo "Menyalin agent files ke $GLOBAL_AGENTS_DIR ..."
find "$AGENT_SRC_DIR" -name "*.md" | while read -r SRC_FILE; do
  REL_PATH="${SRC_FILE#$AGENT_SRC_DIR/}"
  DEST_FILE="$GLOBAL_AGENTS_DIR/$REL_PATH"
  DEST_DIR="$(dirname "$DEST_FILE")"
  mkdir -p "$DEST_DIR"
  cp "$SRC_FILE" "$DEST_FILE"
  echo "  [OK] agents/$REL_PATH"
done
echo ""

# Tulis provider config ke ~/.config/opencode/opencode.jsonc
echo "Menulis provider config ke $GLOBAL_CONFIG ..."
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
echo "  [OK] Provider config 9router ditulis"
echo ""

# Tulis env vars ke RC file
for RC_FILE in $RC_FILES; do
  echo "Menulis env vars ke $RC_FILE ..."

  WROTE_ANYTHING=0

  # Cek dan tulis OPENCODE_9ROUTER_BASE_URL
  if grep -q "OPENCODE_9ROUTER_BASE_URL" "$RC_FILE" 2>/dev/null; then
    echo "  [SKIP] OPENCODE_9ROUTER_BASE_URL sudah ada di $RC_FILE"
  else
    if [ "$WROTE_ANYTHING" = "0" ]; then
      printf "\n# opencode-general-agent\n" >> "$RC_FILE"
      WROTE_ANYTHING=1
    fi
    printf "export OPENCODE_9ROUTER_BASE_URL=%s\n" "$BASE_URL" >> "$RC_FILE"
    echo "  [OK]   OPENCODE_9ROUTER_BASE_URL=$BASE_URL"
  fi

  # Cek dan tulis OPENCODE_9ROUTER_API_KEY
  if grep -q "OPENCODE_9ROUTER_API_KEY" "$RC_FILE" 2>/dev/null; then
    echo "  [SKIP] OPENCODE_9ROUTER_API_KEY sudah ada di $RC_FILE"
  else
    if [ "$WROTE_ANYTHING" = "0" ]; then
      printf "\n# opencode-general-agent\n" >> "$RC_FILE"
      WROTE_ANYTHING=1
    fi
    printf "export OPENCODE_9ROUTER_API_KEY=%s\n" "$API_KEY" >> "$RC_FILE"
    echo "  [OK]   OPENCODE_9ROUTER_API_KEY=***"
  fi

  echo ""
done

echo "Selesai. Jalankan perintah berikut untuk mengaktifkan perubahan:"
echo ""
for RC_FILE in $RC_FILES; do
  echo "  source $RC_FILE"
done
echo ""
echo "Catatan: Jika repo ini di-update (git pull), jalankan installer ini lagi"
echo "         untuk menyync agent terbaru ke ~/.config/opencode/agents/"
echo ""
