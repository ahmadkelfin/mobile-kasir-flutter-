# Firebase Configuration Setup Guide

## Deskripsi
File `android/app/google-services.json` saat ini adalah template placeholder. Anda perlu mengganti dengan file asli dari Firebase Console untuk aplikasi berjalan dengan baik.

## Cara Mendapatkan File `google-services.json` Asli

### Langkah 1: Buka Firebase Console
1. Kunjungi [Firebase Console](https://console.firebase.google.com/)
2. Login dengan akun Google Anda

### Langkah 2: Pilih atau Buat Project
- Jika sudah punya project Firebase, pilih project tersebut
- Jika belum, klik **"Create a project"** dan ikuti langkah-langkahnya

### Langkah 3: Tambahkan Aplikasi Android
1. Di dashboard Firebase, klik icon Android (atau **"Add app"**)
2. Input **Android package name**: `com.example.mobile_kasir`
3. Klik **"Register app"**

### Langkah 4: Download `google-services.json`
1. Setelah register, Firebase akan menampilkan opsi download
2. Klik **"Download google-services.json"**
3. File akan terdownload ke komputer Anda

### Langkah 5: Letakkan File di Lokasi yang Benar
1. Buka folder project Flutter Anda: `/Users/ahmad/mobile kasir/`
2. Navigasi ke: `android/app/`
3. Hapus file `google-services.json` yang ada (template)
4. Copy file `google-services.json` yang baru dari download ke folder ini

### Langkah 6: Build Ulang Aplikasi
```bash
flutter clean
flutter pub get
flutter run
```

## Struktur File yang Benar
```
mobile kasir/
├── android/
│   ├── app/
│   │   ├── google-services.json  ← File harus di sini
│   │   ├── build.gradle.kts
│   │   └── src/
│   └── build.gradle.kts
├── lib/
├── ios/
└── ...
```

## Troubleshooting

### Jika masih error:
1. Pastikan **package name** di Firebase sama dengan di `android/app/build.gradle.kts`:
   ```
   applicationId = "com.example.mobile_kasir"
   ```
2. Jika ingin ganti package name, ubah di:
   - Firebase Console (hapus app lama, daftar ulang dengan package name baru)
   - `android/app/build.gradle.kts`
   - `android/AndroidManifest.xml`

3. Jalankan:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## File Sudah Benar?
Setelah download dan letakkan file asli, file `google-services.json` Anda akan terlihat seperti:
```json
{
  "project_info": {
    "project_number": "1234567890",
    "project_id": "your-firebase-project-id",
    ...
  },
  "client": [...]
}
```

Bukan template seperti sekarang.
