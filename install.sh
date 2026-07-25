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

  echo ""
done

echo "Selesai. Jalankan perintah berikut untuk mengaktifkan perubahan:"
echo ""
for RC_FILE in $RC_FILES; do
  echo "  source $RC_FILE"
done
echo ""
