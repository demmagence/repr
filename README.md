# Repr

Repr adalah aplikasi pencatat latihan gym pribadi untuk Android. Seluruh data
disimpan secara lokal di SQLite; tidak ada akun, backend, analytics, iklan, atau
koneksi jaringan.

## Fitur

- Library 80 exercise dan exercise custom
- Routine dengan tiga set awal per exercise
- Workout kosong, dari routine, atau mengulangi riwayat
- Weight, reps, RPE, working/warm-up/drop/failure set
- Previous performance dan draft workout yang tersimpan otomatis
- Rest timer dengan notifikasi Android
- Riwayat, volume, max weight, estimated 1RM, dan grafik progres
- Backup dan restore JSON transaksional

## Menjalankan project

Persyaratan: Flutter 3.44+, Dart 3.12+, Android SDK 36, Java 17+, serta
perangkat Android 7.0/API 24 atau lebih baru.

```sh
flutter pub get
dart run build_runner build
flutter run
```

Quality gate:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

APK debug berada di `build/app/outputs/flutter-apk/app-debug.apk`.

## Backup

1. Pastikan tidak ada workout aktif.
2. Buka **Pengaturan → Ekspor backup** dan pilih lokasi file JSON.
3. Untuk memulihkan, pilih **Impor backup**, periksa ringkasan jumlah data, lalu
   konfirmasi. Restore mengganti seluruh data lokal dalam satu transaksi.

Format backup diawali dengan `format: "repr-backup"` dan `schemaVersion: 1`.
Backup dengan format rusak atau versi yang tidak didukung akan ditolak tanpa
mengubah database.

## Statistik

- Volume: jumlah `weight × reps`, tidak termasuk warm-up atau set belum selesai.
- Estimated 1RM: rumus Epley untuk set berbobot dengan 1–12 reps.
- Bodyweight dapat dicatat sebagai 0 kg, tetapi tidak menghasilkan estimated 1RM.
