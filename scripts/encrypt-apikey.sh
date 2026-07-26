#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: ./scripts/encrypt-apikey.sh \"sk-your-raw-apikey\""
  echo ""
  echo "Output: ciphertext yang siap dipaste ke kolom apikey di Google Sheets"
  exit 1
fi

RAW_APIKEY="$1"

printf "Masukkan shared passphrase: "
read -rs PASSPHRASE
echo ""

if [ -z "$PASSPHRASE" ]; then
  echo "[ERROR] Passphrase tidak boleh kosong."
  exit 1
fi

CIPHER=$(printf '%s' "$RAW_APIKEY" | openssl enc -aes-256-cbc -pbkdf2 -a -pass pass:"$PASSPHRASE" 2>/dev/null)

if [ -z "$CIPHER" ]; then
  echo "[ERROR] Enkripsi gagal. Pastikan openssl tersedia."
  exit 1
fi

echo ""
echo "Ciphertext (paste ke kolom apikey di Google Sheets):"
echo ""
echo "$CIPHER"
echo ""
