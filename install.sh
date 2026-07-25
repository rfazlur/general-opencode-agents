#!/bin/sh

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_DIR="$REPO_DIR/.opencode"

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

# Cek konflik global opencode config
GLOBAL_OPENCODE_DIR="$HOME/.config/opencode"
CONFLICT_FILE=""
for FNAME in opencode.jsonc opencode.json; do
  if [ -f "$GLOBAL_OPENCODE_DIR/$FNAME" ]; then
    CONFLICT_FILE="$GLOBAL_OPENCODE_DIR/$FNAME"
    break
  fi
done

if [ -n "$CONFLICT_FILE" ]; then
  echo "[PERINGATAN] Ditemukan file config global opencode:"
  echo "  $CONFLICT_FILE"
  echo ""
  echo "File ini akan di-merge dengan config 9router dan bisa menyebabkan"
  echo "koneksi tidak mengarah ke 9router (terutama jika ada 'provider' atau"
  echo "'model' yang hardcoded di dalamnya)."
  echo ""
  mv "$CONFLICT_FILE" "${CONFLICT_FILE}.bak"
  echo "[OK] File dibackup ke: ${CONFLICT_FILE}.bak"
  echo "     Untuk restore: mv \"${CONFLICT_FILE}.bak\" \"$CONFLICT_FILE\""
  echo ""
fi

# Tulis ke setiap RC file
for RC_FILE in $RC_FILES; do
  echo "Menulis ke $RC_FILE ..."

  WROTE_ANYTHING=0

  # Cek dan tulis OPENCODE_CONFIG_DIR
  if grep -q "OPENCODE_CONFIG_DIR" "$RC_FILE" 2>/dev/null; then
    echo "  [SKIP] OPENCODE_CONFIG_DIR sudah ada di $RC_FILE"
  else
    if [ "$WROTE_ANYTHING" = "0" ]; then
      printf "\n# opencode-general-agent\n" >> "$RC_FILE"
      WROTE_ANYTHING=1
    fi
    printf "export OPENCODE_CONFIG_DIR=%s\n" "$OPENCODE_DIR" >> "$RC_FILE"
    echo "  [OK]   OPENCODE_CONFIG_DIR=$OPENCODE_DIR"
  fi

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
