# Repr

Repr adalah aplikasi pencatat latihan gym pribadi untuk Android. Seluruh data
disimpan secara lokal di SQLite; tidak ada akun, backend, analytics, iklan, atau
koneksi jaringan.

## Fitur

- Library 80 exercise dan exercise custom
- Routine dengan catatan, urutan exercise, jenis/jumlah set, dan rest timer
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

## Quality Gate & Continuous Integration

Repositori menggunakan GitHub Actions workflow (`.github/workflows/quality_gate.yml`) yang berjalan otomatis pada setiap **Pull Request** dan **Push** ke branch `main`.

Workflow CI menjalankan tahap-tahap berikut pada runner Windows (`windows-latest`):
1. **Format check**: `dart format --output=none --set-exit-if-changed .`
2. **Static analysis**: `flutter analyze`
3. **Unit, Widget, & Golden tests**: `flutter test`
4. **Debug APK build**: `flutter build apk --debug` (tidak memerlukan secret release signing)

> [!NOTE]
> Runner Windows digunakan pada CI agar baseline rasterisasi font dan layout pada **Golden Tests** konsisten dengan lingkungan pengujian.

### Mereproduksi dan Memperbaiki Kegagalan Secara Lokal

Jika quality gate gagal di CI, jalankan perintah berikut secara bertahap di lingkungan lokal:

1. **Format kode:**
   ```sh
   dart format .
   ```
2. **Analisis lint:**
   ```sh
   flutter analyze
   ```
3. **Pengujian unit, widget, dan golden:**
   ```sh
   flutter test
   ```
   Jika perubahan tampilan UI disengaja dan baseline golden perlu diperbarui (di OS Windows):
   ```sh
   flutter test --update-goldens
   ```
4. **Build APK debug:**
   ```sh
   flutter build apk --debug
   ```
   APK debug akan dihasilkan di `build/app/outputs/flutter-apk/app-debug.apk`.

Dengan emulator atau perangkat Android terhubung, jalankan integration test:

```sh
flutter test integration_test/backup_restore_test.dart
```

## Signing APK release

Build release tidak pernah memakai debug key. Buat keystore pribadi, misalnya:

```sh
keytool -genkeypair -v -keystore repr-release.jks -alias repr -keyalg RSA -keysize 2048 -validity 10000
```

Salin `android/key.properties.example` menjadi `android/key.properties`, lalu isi
lokasi keystore dan kredensialnya. File tersebut serta `*.jks`/`*.keystore`
dikecualikan dari Git. Alternatifnya, sediakan empat environment variable:
`REPR_STORE_FILE`, `REPR_STORE_PASSWORD`, `REPR_KEY_ALIAS`, dan
`REPR_KEY_PASSWORD`.

Setelah signing tersedia, jalankan:

```sh
flutter build apk --release
```

Tanpa kredensial tersebut, build release sengaja dihentikan dengan pesan yang
jelas; `flutter build apk --debug` tetap dapat digunakan tanpa secret.

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
