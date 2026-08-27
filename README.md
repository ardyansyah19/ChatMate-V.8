# ChatMate 💬

Aplikasi chat mirip WhatsApp dibuat dengan **Flutter (Dart)** dan **Firebase**
(Authentication, Cloud Firestore, Storage). Mendukung:

- ✅ Daftar akun (email, password, nickname) — data tersimpan di database (Firestore)
- ✅ Login hanya dengan email & password
- ✅ Chat real-time antar pengguna terdaftar (misal: Ahmad Riko ↔ Amelia Citra)
- ✅ Kirim pesan teks, **gambar**, dan **berkas** (PDF, DOCX, ZIP, dll — bisa diunduh & dibuka penerima)
- ✅ Halaman **Pengaturan**: ubah/tambah foto profil, ubah nickname & info
- ✅ Tampilan mirip WhatsApp (bubble chat, status online, centang terkirim/dibaca, dsb.)

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

## 3. Setup Firebase (WAJIB — aplikasi tidak akan berjalan tanpa ini)

Karena chat & login membutuhkan **database sungguhan** (bukan simulasi lokal),
Anda perlu menghubungkan proyek ke Firebase milik Anda sendiri:

### 3.1 Buat Project Firebase
1. Buka https://console.firebase.google.com/ → **Add project** → beri nama (mis. `chatmate-app`).
2. Tunggu sampai project selesai dibuat.

### 3.2 Aktifkan Authentication
1. Di sidebar, buka **Build → Authentication → Get started**.
2. Tab **Sign-in method** → aktifkan **Email/Password**.

### 3.3 Aktifkan Cloud Firestore
1. **Build → Firestore Database → Create database**.
2. Pilih mode **production** (aturan sudah disediakan di `firestore.rules`).
3. Setelah database dibuat, buka tab **Rules**, salin isi file `firestore.rules`
   dari proyek ini, tempel, lalu **Publish**.

### 3.4 Aktifkan Storage
1. **Build → Storage → Get started**.
2. Setelah aktif, buka tab **Rules**, salin isi `storage.rules`, tempel, **Publish**.
   (Dipakai untuk menyimpan foto profil, gambar, dan berkas chat.)

### 3.5 Hubungkan Flutter App ke Firebase (FlutterFire CLI)
Jalankan di terminal, dari folder root proyek `chatmate/`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

- Pilih project Firebase yang baru dibuat.
- Pilih platform (minimal **android**; tambahkan ios/web jika perlu).
- Perintah ini akan **menimpa/menggantikan** file `lib/firebase_options.dart`
  (yang saat ini masih placeholder berisi `REPLACE_ME`) dengan konfigurasi asli.
- Untuk Android, perintah ini juga otomatis membuat `android/app/google-services.json`.

> ⚠️ Jika Anda menjalankan `flutterfire configure` tanpa CLI (manual), unduh
> `google-services.json` dari **Project settings → General → Your apps → Android app**
> lalu letakkan di `android/app/google-services.json`.

---

## 4. Install Dependencies & Jalankan

```bash
cd chatmate
flutter pub get
flutter run
```

Pastikan ada device/emulator Android yang aktif (`flutter devices`).

---

## 5. Cara Menggunakan (sesuai contoh yang diminta)

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

## 6. Struktur Data di Firestore

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

## 7. Catatan Teknis

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
