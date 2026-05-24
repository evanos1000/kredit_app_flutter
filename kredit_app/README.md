# KreditKu - Aplikasi Dokumentasi Kredit Uang

Aplikasi Android offline untuk mencatat dan mendokumentasikan pinjaman uang pribadi.

## Fitur Utama
- ✅ Tambah/edit/hapus peminjam
- ✅ Buat pinjaman dengan bunga flat 25% (bisa diubah: 10%, 15%, 20%, 25%, 30%)
- ✅ Pilihan durasi: Harian, Mingguan, Bulanan
- ✅ Catat pembayaran (ada tombol cepat nominal umum)
- ✅ Tombol "Lunaskan" untuk langsung lunas sekaligus
- ✅ Riwayat pembayaran per pinjaman
- ✅ Pinjaman berikutnya hanya bisa dibuat setelah pinjaman aktif lunas
- ✅ Dashboard statistik total piutang, terkumpul, dan lunas
- ✅ Progress bar visual per peminjam
- ✅ 100% offline (SQLite)

## Cara Setup

### 1. Install Flutter
- Download Flutter SDK dari: https://flutter.dev/docs/get-started/install
- Extract dan tambahkan ke PATH sistem
- Install Android Studio dari: https://developer.android.com/studio

### 2. Jalankan flutter doctor
```bash
flutter doctor
```
Pastikan semua centang hijau (khususnya Android toolchain).

### 3. Copy project ini
Letakkan folder `kredit_app` di direktori kerja kamu.

### 4. Install dependencies
```bash
cd kredit_app
flutter pub get
```

### 5. Jalankan
```bash
# Di emulator atau HP Android (aktifkan USB Debugging)
flutter run
```

### 6. Build APK
```bash
flutter build apk --release
```
File APK ada di: `build/app/outputs/flutter-apk/app-release.apk`

## Struktur Folder
```
lib/
├── main.dart                  # Entry point
├── models/
│   ├── peminjam.dart          # Model data peminjam
│   ├── pinjaman.dart          # Model data pinjaman
│   └── pembayaran.dart        # Model data pembayaran
├── database/
│   └── database_helper.dart   # SQLite helper (semua query)
├── screens/
│   ├── home_screen.dart           # Halaman utama daftar peminjam
│   ├── form_peminjam_screen.dart  # Form tambah/edit peminjam
│   ├── detail_peminjam_screen.dart# Detail peminjam + list pinjaman
│   ├── form_pinjaman_screen.dart  # Form buat pinjaman baru
│   └── detail_pinjaman_screen.dart# Detail pinjaman + catat bayar
└── utils/
    ├── app_theme.dart         # Tema warna dan style
    └── currency_formatter.dart# Format Rupiah dan tanggal
```

## Logika Bisnis
- **Bunga flat**: dihitung sekali dari pokok. Contoh: Rp500.000 × 25% = Rp125.000
- **Total wajib bayar**: Rp500.000 + Rp125.000 = **Rp625.000**
- Peminjam membayar berapa saja, kapan saja (harian/mingguan/bulanan sesuai kesepakatan)
- Setelah lunas → boleh ajukan pinjaman baru
- Tidak ada denda atau jatuh tempo paksa

## Dependencies
- `sqflite: ^2.3.2` - Database SQLite lokal
- `path: ^1.9.0` - Path helper untuk database
- `intl: ^0.19.0` - Format Rupiah dan tanggal Bahasa Indonesia
- `google_fonts: ^6.2.1` - Font Plus Jakarta Sans
