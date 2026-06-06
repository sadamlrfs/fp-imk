# Planning: IMK Prototype — Translate Chat & Call App

## 1. Tujuan & Konteks

Prototype frontend untuk aplikasi chat & video call dengan fitur **realtime translate** (Bahasa Inggris ↔ Bahasa Indonesia). Dibangun untuk keperluan **usability testing IMK** dengan 10 skenario task. Tidak ada backend — semua data dummy dari JSON dan interaksi disimulasikan.

**Penting:** App tidak perlu benar-benar berjalan (tidak ada real translation, tidak ada real call). Yang penting **alur navigasi + tampilan terlihat realistis** supaya partisipan bisa menyelesaikan task.

---

## 2. Tech Stack

| Komponen | Pilihan | Alasan |
|---|---|---|
| Framework | **React + Vite** | Setup cepat, hot reload, mudah deploy |
| Styling | **Tailwind CSS** | Cepat untuk replikasi desain mobile |
| Routing | **React Router v6** | Navigasi antar screen |
| Data | **JSON files** (di `public/data/`) | Dummy, mudah diedit |
| State | **React Context + useState** | Cukup untuk prototype, tidak perlu Redux |
| Persistence | **localStorage** | Untuk pesan terkirim oleh user agar terlihat persisten |
| Mobile Frame | **Container max-w-[430px]** | Simulasi tampilan mobile di browser desktop |

**Catatan:** Akan dijalankan di browser desktop dengan tampilan mobile-frame (seperti DevTools mobile view). Tidak perlu build native.

---

## 3. Struktur Folder

```
imk-prototype/
├── public/
│   ├── data/
│   │   ├── users.json          # daftar user/kontak
│   │   ├── chats.json          # daftar chat (personal & group)
│   │   ├── messages.json       # pesan per-chat (text/voice/video)
│   │   └── translations.json   # dummy text EN/ID
│   └── media/
│       ├── avatars/            # foto profil dummy
│       ├── voice/              # 1-2 file mp3 dummy untuk voice note
│       └── video/              # 1 file mp4 dummy untuk attachment
├── src/
│   ├── components/
│   │   ├── MobileFrame.jsx          # wrapper mobile (status bar + safe area)
│   │   ├── BottomNav.jsx            # nav bar bawah (Home, dll)
│   │   ├── ChatBubble.jsx           # bubble teks dengan terjemahan
│   │   ├── VoiceBubble.jsx          # bubble voice note + waveform + transkrip
│   │   ├── VideoAttachmentBubble.jsx
│   │   ├── ChatInput.jsx            # input bar bawah (emoji, attach, mic)
│   │   ├── VoiceRecorder.jsx        # UI rekam (trash/mic/send)
│   │   ├── PageIndicator.jsx        # dot indicator onboarding
│   │   └── TranslateOverlay.jsx     # box realtime translate di video call
│   ├── pages/
│   │   ├── Launch1.jsx              # onboarding 1
│   │   ├── Launch2.jsx              # onboarding 2
│   │   ├── Launch3.jsx              # onboarding 3
│   │   ├── Home.jsx                 # daftar chat
│   │   ├── ChatRoom.jsx             # room chat personal
│   │   ├── GroupChatRoom.jsx        # room chat group
│   │   ├── VideoCall.jsx            # video call 1-on-1
│   │   ├── GroupVideoCall.jsx       # video call group 4 orang
│   │   └── VideoTranslateModal.jsx  # pop-up video translate
│   ├── context/
│   │   └── AppContext.jsx           # state global (current user, sent messages)
│   ├── hooks/
│   │   └── useChatData.js           # load JSON + merge dengan localStorage
│   ├── App.jsx
│   ├── main.jsx
│   └── index.css
├── index.html
├── package.json
├── tailwind.config.js
└── vite.config.js
```

---

## 4. Data Model (JSON)

### `users.json`
```json
[
  { "id": "u1", "name": "Rizal Hafiyyan", "avatar": "/media/avatars/rizal.png", "lang": "en" },
  { "id": "u2", "name": "Erika", "avatar": "/media/avatars/erika.png", "lang": "en" },
  { "id": "me", "name": "Sadam", "avatar": "/media/avatars/sadam.png", "lang": "id" }
]
```

### `chats.json`
```json
[
  { "id": "c1", "type": "personal", "participantIds": ["u1"], "lastMessage": "Hello! How are you today?", "time": "09.41" },
  { "id": "g1", "type": "group", "name": "Group IMK", "participantIds": ["u1","u2","u3","u4","u5"], "lastMessage": "...", "time": "09.41" }
]
```

### `messages.json`
```json
{
  "c1": [
    {
      "id": "m1", "senderId": "u1", "type": "voice",
      "audio": "/media/voice/sample1.mp3", "duration": 12,
      "textEn": "Lorem ipsum is simply...", "textId": "Lorem ipsum hanyalah...",
      "time": "14.12"
    },
    {
      "id": "m2", "senderId": "me", "type": "text",
      "textId": "Lorem ipsum hanyalah...", "textEn": "Lorem ipsum is simply...",
      "time": "14.12"
    }
  ],
  "g1": [ ... ]
}
```

### `translations.json` (untuk realtime translate overlay)
```json
{
  "videoCallScripts": [
    { "speakerId": "u2", "textEn": "...", "textId": "..." },
    { "speakerId": "u1", "textEn": "...", "textId": "..." }
  ]
}
```

---

## 5. Routing Map

| Path | Screen | Task terkait |
|---|---|---|
| `/` | Launch1 | Task 1 |
| `/launch2` | Launch2 | Task 1 |
| `/launch3` | Launch3 | Task 1 |
| `/home` | Home (chat list) | Task 1, 2, 5 |
| `/chat/:chatId` | ChatRoom (personal) | Task 2, 3, 4, 7, 10 |
| `/group/:chatId` | GroupChatRoom | Task 5, 8 |
| `/call/:chatId` | VideoCall (1-on-1) | Task 6 |
| `/group-call/:chatId` | GroupVideoCall | Task 9 |
| `/video-translate/:messageId` | VideoTranslateModal | Task 10 |

**Flag onboarding:** simpan `localStorage.setItem('onboarded', 'true')` setelah Launch3 → tombol "Mulai Sekarang". Saat reload, kalau sudah onboarded, langsung redirect ke `/home`. Untuk demo testing, sediakan tombol reset di pojok (misal long-press logo) untuk hapus flag — supaya bisa diuji berulang.

---

## 6. Pemetaan Task ke Implementasi

| # | Task | Implementasi |
|---|---|---|
| 1 | Onboarding → Home | 3 screen launch + tombol Lanjut/Sebelumnya/Mulai. Total 3 tap ke Home. |
| 2 | Buka chat personal, baca voice note translated | Klik item di Home → ChatRoom. VoiceBubble menampilkan transkrip EN + ID langsung tanpa harus diputar. |
| 3 | Kirim pesan teks balasan | Ketik di ChatInput → Enter/Send → bubble baru muncul dengan teks ID (asli) + EN (terjemahan). Disimpan ke localStorage. |
| 4 | Rekam & kirim voice note | Tap mic icon → masuk mode VoiceRecorder (trash/mic/send). Tap send → muncul voice bubble dummy dengan transkrip pre-defined. |
| 5 | Buka group chat | Klik group dari Home → GroupChatRoom dengan beberapa anggota & bahasa berbeda. |
| 6 | Video call 1-on-1 | Tap header chat (atau ikon call) → VideoCall screen. TranslateOverlay men-cycle script dummy tiap ~3 detik. |
| 7 | Kirim attachment video | Tap attach (paperclip) → simulasi picker (modal sederhana pilih 1 dummy video) → muncul VideoAttachmentBubble dengan label translate. |
| 8 | Voice note panjang di group | VoiceBubble di group dengan transkrip multi-segmen (array of segments) yang ditampilkan inline. |
| 9 | Group video call 4 orang, tap speaker | GroupVideoCall: 4 tile peserta. Tap tile → border hijau aktif + TranslateOverlay update ke speaker tsb. |
| 10 | Buka video translate dari pesan video | Tap VideoAttachmentBubble → buka VideoTranslateModal full-screen dengan box EN + ID. |

---

## 7. Komponen Reusable Penting

- **ChatBubble**: props `{ side: 'left'|'right', textId, textEn, time }` — left bubble blue, right white (sesuai mockup).
- **VoiceBubble**: props `{ side, audioUrl, durationLabel, textEn, textId, senderName?, senderAvatar? }` — play button + waveform statis (SVG/gambar) + transkrip.
- **MobileFrame**: max-width 430px, center, status bar palsu (9:41 + ikon signal/wifi/battery) untuk semua screen kecuali launch.

---

## 8. Aset yang Dibutuhkan

- **Avatars**: 5-6 foto dummy (pakai placeholder seperti randomuser.me atau download free stock). Bisa pakai 1 foto dipakai berulang untuk MVP.
- **Voice samples**: 1-2 file mp3 pendek (5-15 detik). Bisa dari freesound atau generate dengan TTS.
- **Video sample**: 1 file mp4 pendek untuk attachment & video translate.
- **Waveform**: SVG/PNG statis (tidak perlu real waveform dari audio).
- **Background pattern**: pattern doodle biru di chat bg (bisa SVG sederhana atau bg blue solid + overlay opacity rendah).

---

## 9. Step-by-Step Execution Plan

1. **Setup project** — `npm create vite@latest . -- --template react`, install Tailwind & React Router.
2. **Buat data JSON** di `public/data/` — users, chats, messages, translations.
3. **Siapkan media dummy** — 1-2 voice mp3, 1 video mp4, beberapa avatar.
4. **Bangun MobileFrame + routing skeleton** — semua route punya placeholder page dulu.
5. **Launch screens (1, 2, 3)** — pakai gambar asset existing (`launch-1.png` dll) atau replikasi UI dengan Tailwind.
6. **Home / chat list** — render dari `chats.json`.
7. **ChatRoom personal** — render bubbles dari `messages.json[chatId]`, implement send text & voice.
8. **GroupChatRoom** — render bubbles dengan nama+avatar sender.
9. **VideoCall 1-on-1** — layout video + TranslateOverlay dengan setInterval cycle script.
10. **GroupVideoCall** — grid 2x2, tap-to-switch active speaker.
11. **VideoTranslateModal** — full screen dengan video player + box translate.
12. **Polish** — animasi transisi sederhana, pastikan 10 task bisa diselesaikan end-to-end.
13. **Test manual** — jalankan tiap task sesuai tabel (max time/tap) untuk verifikasi alur.

---

## 10. Asumsi & Batasan

- **Tidak ada real translate** — semua teks EN dan ID sudah hardcoded di JSON sebagai pasangan.
- **Tidak ada real audio/video processing** — voice note play hanya memutar file mp3 statis, video call menampilkan gambar/video loop dummy.
- **Tidak ada autentikasi** — current user di-hardcode sebagai `"me"` (Sadam).
- **Tidak ada real-time** — "realtime translate" overlay di video call simulasi via setInterval rotasi script dummy.
- **Browser desktop saja** — testing di Chrome/Edge dengan responsive mode set ke iPhone (atau resize manual). Tidak diuji di Safari iOS native.
- **Permission prompts** (kamera, mikrofon, galeri) — disimulasikan dengan modal konfirmasi saja, tidak request real permission.

---

## 11. Pertanyaan Sebelum Eksekusi

1. **Tech stack OK?** React+Vite+Tailwind, atau preferensi lain (Next.js / Flutter Web / HTML+CSS murni)?
2. **Tampilan target** — fix di browser desktop dengan mobile frame, atau perlu deploy untuk dibuka via HP partisipan langsung (mis. via Vercel)?
3. **Aset gambar/audio** — saya pakai placeholder (dummy generic), atau ada aset spesifik yang sudah disiapkan?
4. **Bahasa UI** — Indonesia (sesuai mockup) — confirm?
5. **Reset flow** — perlu tombol reset (untuk hapus state antar partisipan testing) di mana? Pojok home / di settings / shortcut tertentu?

Setelah pertanyaan di atas dijawab, lanjut ke step 1 (setup project).
