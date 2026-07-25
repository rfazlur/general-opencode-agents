# General-Purpose OpenCode Agent Config

Konfigurasi multi-agent yang bisa dipakai untuk project apa pun — coding, konten, riset, atau QA — tanpa perlu menulis ulang system prompt tiap kali jenis project berganti.

## Instalasi Global (sekali, berlaku di semua project)

```bash
# 1. Clone repo ini ke lokasi manapun di mesin kamu
git clone <repo-url> ~/opencode-agents

# 2. Jalankan installer
cd ~/opencode-agents
./install.sh
```

Script akan mendeteksi shell kamu (zsh/bash), meminta baseURL server 9router secara interaktif, lalu menulis config ke `~/.zshrc` atau `~/.bashrc` secara otomatis. Aman dijalankan berkali-kali — tidak akan duplikasi entry yang sudah ada.

```
# Contoh output installer:
Masukkan baseURL server 9router kamu (contoh: http://100.97.237.10:20128/v1): http://xxx.xxx.x.x:20128/v1

Menulis ke /Users/kamu/.zshrc ...
  [OK]   OPENCODE_CONFIG_DIR=/path/to/repo/.opencode
  [OK]   OPENCODE_9ROUTER_BASE_URL=http://xxx.xxx.x.x:20128/v1

Selesai. Jalankan perintah berikut untuk mengaktifkan perubahan:

  source ~/.zshrc
```

**Update agent di kemudian hari:**
```bash
git -C ~/opencode-agents pull
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
