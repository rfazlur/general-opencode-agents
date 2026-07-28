# General-Purpose OpenCode Agent Config

Konfigurasi multi-agent yang bisa dipakai untuk project apa pun — coding, konten, riset, atau QA — tanpa perlu menulis ulang system prompt tiap kali jenis project berganti.

## Instalasi Global (sekali, berlaku di semua project)

```bash
npx @rfazlur/fdnqa
```

Installer akan meminta **email** dan **shared passphrase** (tanyakan ke admin). Baseurl dan API key otomatis diambil dari database dan didecrypt — tidak perlu input manual.

```
# Contoh output installer:
Masukkan email kamu: nama@perusahaan.com

Mengambil data dari database...
  [OK] Data ditemukan untuk nama@perusahaan.com

Masukkan shared passphrase: ****
  [OK] API key berhasil didecrypt

Selesai. Jalankan perintah berikut untuk mengaktifkan perubahan:

  source ~/.zshrc
```

Jika ditemukan file `~/.config/opencode/opencode.jsonc` yang sudah ada, installer otomatis mebackup file tersebut ke `.bak`.

## Commands

| Command | Keterangan |
|---------|------------|
| `npx @rfazlur/fdnqa` | Install pertama kali — prompt email + passphrase |
| `npx @rfazlur/fdnqa update` | Update agent files ke versi terbaru tanpa re-auth |
| `npx @rfazlur/fdnqa uninstall` | Hapus semua agent files dan env vars |

## Setup User Baru (untuk Admin)

Sebelum anggota tim bisa install, admin perlu mendaftarkan email mereka di database (Google Sheets).

**Langkah 1: Encrypt apikey**

```bash
./scripts/encrypt-apikey.sh "sk-raw-apikey-disini"
# Masukkan shared passphrase saat diminta
# Output: ciphertext — copy hasilnya
```

**Langkah 2: Tambah row di Google Sheets**

Buka sheet database, tambah baris baru dengan kolom:

| baseurl | email | apikey |
|---------|-------|--------|
| `http://IP:PORT/v1` | `nama@perusahaan.com` | `(ciphertext dari langkah 1)` |

**Langkah 3: Share passphrase ke anggota tim**

Kirim shared passphrase via channel internal (bukan di repo, bukan di sheet).

Untuk switch kembali ke config lokal lama:
```bash
mv ~/.config/opencode/opencode.jsonc.bak ~/.config/opencode/opencode.jsonc
```

**Update agent di kemudian hari:**
```bash
npx @rfazlur/fdnqa update
```

## Cara pakai

1. **Buat brief** pakai template di `docs/PROJECT_BRIEF_TEMPLATE.md` — ini yang dibaca Orchestrator untuk menentukan track dan jadi acuan Reviewer.
2. **Mulai dari Orchestrator**. Dia akan:
   - Melengkapi brief kalau masih kurang (nanya balik, bukan menebak)
   - Memanggil Planner untuk menyusun langkah kerja
   - Menjalankan track yang sesuai (coding / content / research / qa / kombinasi)
   - Menutup dengan Reviewer → Final Approver sebelum hasil diserahkan

## Struktur

```
.opencode/agent/
  orchestrator.md        # primary agent, routing + koordinasi
  planner.md             # core role, dipakai semua track
  reviewer.md            # core role, read-only, dipakai semua track
  final-approver.md      # core role, read-only, gate terakhir
  coding/
    developer.md
    qa-engineer.md
    linter.md
    commit-message.md
  content/
    researcher.md
    copywriter.md
    visual-strategist.md
    optimizer.md
  research/
    researcher.md
    analyst.md
    synthesizer.md
  qa/
    prd-analyzer.md      # baca PRD + Figma, ekstrak requirements
    test-case-writer.md  # tulis test case manual dari requirements
    test-case-reviewer.md
docs/
  PROJECT_BRIEF_TEMPLATE.md
```

## Kenapa strukturnya begini

- **Core roles (Planner, Reviewer, Final Approver) generik** — perilakunya sama di semua domain, kriterianya datang dari brief, bukan dari system prompt yang ditulis ulang tiap project.
- **Track spesifik cuma beda di permission eksekusi** — coding punya akses `bash` dan edit code, content/research/qa tidak. Ini juga jadi lapisan keamanan: agent konten tidak pernah bisa menjalankan perintah sistem.
- **Tiered model assignment**: Opus untuk gate akhir (butuh judgment lintas-domain), Sonnet untuk eksekusi dan analisis mid-tier, Haiku untuk tugas mekanis (lint, commit message).
- **Project campuran** ditangani dengan Orchestrator menjalankan lebih dari satu track secara berurutan sesuai dependensi (misal: riset dulu, baru konten yang memakai hasil riset itu).

## Menambah track baru

Kalau nanti ada domain baru (misal: desain produk, edukasi/kursus), cukup:
1. Buat folder baru di `.opencode/agent/<nama-track>/`
2. Definisikan role eksekusi yang relevan dengan permission yang di-scope ke domain itu
3. Tambahkan mapping jenis project baru di bagian "Routing" pada `orchestrator.md`

Core roles (Planner, Reviewer, Final Approver) tidak perlu diubah — itu keuntungan utama dari desain ini.

## Catatan

- Provider `9router` didefinisikan di `.opencode/opencode.json` dan membaca `baseURL` dari env var `OPENCODE_9ROUTER_BASE_URL` — tidak perlu config provider manual di tiap mesin.
- Field `permission:` di frontmatter mengikuti skema OpenCode terbaru. Field `tools:` (format lama) sudah deprecated — repo ini sudah pakai format baru.
