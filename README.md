# ChatMate V.8
By Ahmad Riko Dyansyah

Aplikasi chat mirip WhatsApp dibuat dengan **Flutter (Dart)** dan **Firebase**
(Authentication, Cloud Firestore, Storage). Mendukung:

---

## 1. Struktur Proyek

```
chatmate/
├── lib/
│   ├── main.dart                     # entry point + AuthGate (cek login/logout)
│   ├── firebase_options.dart         # ⚠️ PLACEHOLDER — wajib di-generate ulang
│   ├── theme.dart                    # warna & tema mirip WhatsApp
│   ├── models/                       # User, Message, Chat model
│   ├── services/                     # AuthService, ChatService, StorageService
│   ├── screens/
│   │   ├── auth/                     # login_screen.dart, register_screen.dart
│   │   ├── chat/                     # chat_home, new_chat, chat_detail
│   │   └── settings/                 # settings_screen.dart (profil & foto)
│   └── widgets/                      # user_avatar.dart, message_bubble.dart
├── android/                          # konfigurasi project Android
├── firestore.rules                   # security rules Firestore
├── storage.rules                     # security rules Storage
└── pubspec.yaml
```

---

## 2. Prasyarat

- Flutter SDK terpasang (`flutter doctor` tanpa error) — gunakan Flutter 3.19+.
- Akun Google untuk membuat project di [Firebase Console](https://console.firebase.google.com/).
- Node.js (untuk `firebase-tools`) — opsional tapi memudahkan.


---

## 5. Install Dependencies & Jalankan

```bash
cd chatmate
flutter pub get
flutter run
```

Pastikan ada device/emulator Android yang aktif (`flutter devices`).

---

## 6. Cara Menggunakan (sesuai contoh yang diminta)

1. Buka aplikasi → tekan **"Belum punya akun? Daftar di sini"**.
2. Daftar akun pertama:
   - Nickname: `Ahmad Riko`
   - Email: `ahmadriko@gmail.com`
   - Password: `Admin12345`
3. Logout (Pengaturan → Keluar), lalu daftar akun kedua di device/emulator lain
   (atau logout-login bergantian):
   - Nickname: `Amelia Citra`
   - Email: `ameliacitra@gmail.com`
   - Password: `Admin12345`
4. Login sebagai salah satu akun → tombol chat bulat (kanan bawah) →
   pilih kontak lawan bicara → mulai kirim pesan teks, gambar, atau berkas.
5. Buka **Pengaturan** (ikon foto profil di kanan atas) untuk mengganti foto
   profil, nickname, atau info.

💡 Tip untuk testing dua akun sekaligus: jalankan di **dua emulator** atau
1 emulator + 1 HP fisik, lalu login masing-masing dengan akun berbeda —
pesan akan muncul real-time di kedua sisi.

---

## 7. Struktur Data di Firestore

```
users/{uid}
  ├─ email, nickname, photoUrl, about
  ├─ isOnline, lastSeen
  └─ nicknameLower, emailLower (untuk pencarian, opsional)

chats/{chatId}                 # chatId = uidA_uidB (terurut)
  ├─ participants: [uidA, uidB]
  ├─ lastMessage, lastMessageTime, lastSenderId
  ├─ unreadCount: { uidA: 0, uidB: 2 }
  └─ messages/{messageId}
        ├─ senderId, receiverId
        ├─ type: text | image | file | video
        ├─ text / mediaUrl / fileName / fileSize
        └─ sentAt, isRead, isDelivered
```

Gambar & berkas disimpan di Firebase **Storage**:
```
profile_photos/{uid}.jpg
chat_media/{chatId}/images/{id}.jpg
chat_media/{chatId}/files/{id}_namafile.pdf
```

---

## 8. Catatan Teknis

- Semua fitur (login, chat, kirim gambar/berkas, ganti foto profil) **terhubung
  ke Firebase sungguhan** — bukan simulasi/mock lokal — sehingga pesan benar-benar
  terkirim antar device dan file benar-benar bisa diunduh & dibuka penerima.
- Saat pertama kali membuka daftar chat, Firestore mungkin menampilkan error
  berisi link "create index" di console/log — ini normal untuk query gabungan
  `where` + `orderBy`. Klik link tersebut (muncul di terminal `flutter run`)
  untuk membuat composite index secara otomatis, tunggu beberapa menit, lalu
  jalankan ulang aplikasi.
- Jika mengalami error `MissingPluginException` atau Firebase belum terhubung,
  pastikan langkah **3.5 (flutterfire configure)** sudah dijalankan dan
  `google-services.json` sudah ada di `android/app/`.
- Package `open_filex` dipakai untuk membuka berkas yang diunduh (PDF, dll)
  langsung dari dalam chat.
- Untuk publish ke Play Store, ganti `applicationId` di
  `android/app/build.gradle` dan atur signing config release Anda sendiri.

Selamat mencoba! 🚀
