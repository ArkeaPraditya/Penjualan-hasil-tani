# GreenCart — Dari Petani untuk Dapurmu

Aplikasi belanja sayur, buah, dan bahan pangan segar (Flutter, Android). Semua fitur inti berjalan
**offline** dengan SQLite lokal, tanpa API key atau layanan eksternal.

> **Status verifikasi:** kode ini ditulis di lingkungan tanpa Flutter/Dart, sehingga **belum pernah
> dikompilasi, dianalisis, maupun diuji**. Jalankan langkah di bawah dan perbaiki error kecil bila ada.

## Menjalankan
Butuh Flutter 3.27+ (Dart 3.6+).

```bash
flutter create . --platforms=android   # membuat folder android/ (kode lib/ tidak ditimpa)
flutter pub get
flutter analyze
dart format .
flutter test        # butuh pustaka sqlite3 di mesin host (mis. libsqlite3-dev)
flutter run
```

Akun demo (kata sandi `demo1234`): pembeli `arkea@greencart.demo`, penjual `budi@greencart.demo` / `siti@greencart.demo`.
Alur uji penjual-pembeli: pesan sebagai Arkea → keluar → masuk sebagai Budi → Profil → Dashboard Penjual → ubah status → masuk lagi sebagai Arkea.

## Struktur
```
lib/
├── main.dart
├── app/            app.dart (provider), main_shell.dart (5 tab), theme/
├── core/           constants, state (OwnerScopedNotifier), utils (validator, harga, status, filter), widgets
├── data/           database/ (skema, reset), models/, repositories/, seed/
└── features/       auth, home, categories, products, cart, checkout, orders, notifications, profile, seller
assets/images/      logo, banner, products/ (18 ilustrasi lokal)
test/               unit_logic_test.dart, data_flow_test.dart
```

## Dependency
| Paket | Fungsi |
|---|---|
| provider | state management (ChangeNotifier) |
| sqflite, path | database SQLite lokal |
| shared_preferences | sesi login/tamu dan area layanan |
| crypto | SHA-256 + salt untuk hash kata sandi demo |
| sqflite_common_ffi (dev) | SQLite di mesin host untuk pengujian |

## Keterbatasan
- Belum dikompilasi/diuji (lihat atas). Gambar produk adalah ilustrasi sederhana buatan skrip, bukan foto.
- Autentikasi lokal hanya demo (hash + salt, tanpa penyimpanan aman); tidak layak produksi.
- Pembayaran COD/transfer hanya simulasi. Tidak ada pelacakan GPS/kurir. Notifikasi hanya di dalam aplikasi.
- Mode penjual berbagi database di satu perangkat; tanpa sinkronisasi antarperangkat. Status pesanan bersifat per pesanan, bukan per penjual.
- Foto profil belum ada (memakai avatar inisial). Ikon kategori memakai Material Icons (kolom `icon_key`), bukan file aset.
- Layar onboarding terpisah tidak dibuat; splash langsung ke login (ada opsi tamu).
- Tidak ada widget test; pengujian mencakup logika dan alur data.
