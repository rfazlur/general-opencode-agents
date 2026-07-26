#!/bin/sh

SHEET_CSV_URL="https://docs.google.com/spreadsheets/d/1QxaBo3MF6fYAJoR-9Pv3XDMfHGK2_8HDIaN65kERLvg/export?format=csv&gid=0"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_SRC_DIR="$REPO_DIR/.opencode/agent"
PROVIDER_SRC="$REPO_DIR/.opencode/opencode.json"

GLOBAL_OPENCODE_DIR="$HOME/.config/opencode"
GLOBAL_AGENTS_DIR="$GLOBAL_OPENCODE_DIR/agents"
GLOBAL_CONFIG="$GLOBAL_OPENCODE_DIR/opencode.jsonc"

echo "opencode-general-agent installer"
echo "================================="
echo ""

# Cek dependency
if ! command -v curl >/dev/null 2>&1; then
  echo "[ERROR] curl tidak ditemukan. Install curl terlebih dahulu."
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "[ERROR] openssl tidak ditemukan. Install openssl terlebih dahulu."
  exit 1
fi

# Deteksi RC file berdasarkan shell aktif
case "$SHELL" in
  */zsh)  RC_FILES="$HOME/.zshrc" ;;
  */bash) RC_FILES="$HOME/.bashrc" ;;
  *)      RC_FILES="$HOME/.zshrc $HOME/.bashrc" ;;
esac

# Input email
printf "Masukkan email kamu: "
read -r USER_EMAIL

if [ -z "$USER_EMAIL" ]; then
  echo "[ERROR] Email tidak boleh kosong. Installer dibatalkan."
  exit 1
fi

echo ""
echo "Mengambil data dari database..."

# Fetch CSV dari Google Sheets
CSV_DATA=$(curl -sL "$SHEET_CSV_URL" 2>/dev/null)

if [ -z "$CSV_DATA" ]; then
  echo "[ERROR] Gagal mengambil data. Periksa koneksi internet."
  exit 1
fi

# Lookup row by email (kolom 2 = email)
ROW=$(echo "$CSV_DATA" | awk -F',' -v email="$USER_EMAIL" 'NR>1 && $2 == email {print}')

if [ -z "$ROW" ]; then
  echo "[ERROR] Email '$USER_EMAIL' tidak ditemukan. Hubungi admin untuk didaftarkan."
  exit 1
fi

BASE_URL=$(echo "$ROW" | cut -d',' -f1)
APIKEY_CIPHER=$(echo "$ROW" | cut -d',' -f3 | tr -d '\r')

echo "  [OK] Data ditemukan untuk $USER_EMAIL"
echo ""

# Input passphrase untuk decrypt apikey
printf "Masukkan shared passphrase: "
read -rs PASSPHRASE
echo ""

if [ -z "$PASSPHRASE" ]; then
  echo "[ERROR] Passphrase tidak boleh kosong. Installer dibatalkan."
  exit 1
fi

# Decrypt apikey
API_KEY=$(printf '%s' "$APIKEY_CIPHER" | openssl enc -aes-256-cbc -pbkdf2 -a -d -pass pass:"$PASSPHRASE" 2>/dev/null)

if [ -z "$API_KEY" ]; then
  echo "[ERROR] Passphrase salah atau data rusak. Installer dibatalkan."
  exit 1
fi

echo "  [OK] API key berhasil didecrypt"
echo ""

# Buat direktori global jika belum ada
mkdir -p "$GLOBAL_AGENTS_DIR"

# Copy semua agent .md files ke ~/.config/opencode/agents/
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

  if grep -q "OPENCODE_9ROUTER_BASE_URL" "$RC_FILE" 2>/dev/null; then
    sed -i.bak "s|export OPENCODE_9ROUTER_BASE_URL=.*|export OPENCODE_9ROUTER_BASE_URL=$BASE_URL|" "$RC_FILE"
    echo "  [UPDATE] OPENCODE_9ROUTER_BASE_URL diperbarui"
  else
    if [ "$WROTE_ANYTHING" = "0" ]; then
      printf "\n# opencode-general-agent\n" >> "$RC_FILE"
      WROTE_ANYTHING=1
    fi
    printf "export OPENCODE_9ROUTER_BASE_URL=%s\n" "$BASE_URL" >> "$RC_FILE"
    echo "  [OK]   OPENCODE_9ROUTER_BASE_URL=$BASE_URL"
  fi

  if grep -q "OPENCODE_9ROUTER_API_KEY" "$RC_FILE" 2>/dev/null; then
    sed -i.bak "s|export OPENCODE_9ROUTER_API_KEY=.*|export OPENCODE_9ROUTER_API_KEY=$API_KEY|" "$RC_FILE"
    echo "  [UPDATE] OPENCODE_9ROUTER_API_KEY diperbarui"
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
