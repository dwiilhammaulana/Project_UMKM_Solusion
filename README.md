# Warung Kopi POS

Aplikasi Point of Sale (POS) berbasis Flutter untuk warung kopi. Project ini berjalan sebagai aplikasi lokal dengan database SQLite di perangkat, fokus pada transaksi kasir, stok, pelanggan, BON, dan laporan ringkas.

## Gambaran Singkat

- Platform utama: Flutter Android-first
- Bahasa: Dart
- Backend: tidak memakai backend server atau cloud
- Penyimpanan data: SQLite lokal
- State management: Riverpod
- Routing: GoRouter
- Fokus UI: Material 3 dengan custom widget internal

## Stack dan Teknologi yang Dipakai

### Framework utama

- Flutter
- Dart SDK `^3.5.0`

### UI dan design system

- Material 3 dari Flutter
- Theme kustom di `lib/shared/theme/app_theme.dart`
- Komponen UI reusable di `lib/shared/widgets/common_widgets.dart`
- Shell layout dan bottom navigation di `lib/shared/widgets/app_shell.dart`
- Form sheet kustom untuk customer, produk, dan profil toko

Project ini **tidak** memakai Tailwind CSS, Bootstrap, atau framework web UI lain. Seluruh tampilan dibangun langsung dengan widget Flutter dan styling kustom internal.

### Font

- `Sora` untuk heading
- `Manrope` untuk body text
- Keduanya di-load lewat package `google_fonts`

## Package / Dependency

Berikut dependency utama yang dipakai oleh project ini:

- `flutter`
- `flutter_localizations`
- `flutter_riverpod`
- `go_router`
- `google_fonts`
- `intl`
- `sqflite`
- `sqflite_common_ffi`
- `fl_chart`
- `file_picker`
- `path`

### Fungsi masing-masing package

- `flutter_riverpod`: state management aplikasi
- `go_router`: routing antar halaman dan nested route
- `google_fonts`: load font `Sora` dan `Manrope`
- `intl`: format tanggal, waktu, dan mata uang Indonesia
- `flutter_localizations`: dukungan locale `id_ID`
- `sqflite`: database SQLite di Android/iOS
- `sqflite_common_ffi`: database SQLite untuk desktop/testing/dev environment
- `fl_chart`: komponen chart pada analitik dan distribusi BON
- `file_picker`: ambil file gambar dari perangkat
- `path`: bantu pengolahan path file/database

## Sumber Elemen UI

Elemen visual utama berasal dari:

- Widget bawaan Flutter Material seperti `Scaffold`, `NavigationBar`, `ListView`, `TabBar`, `FilledButton`, `OutlinedButton`, `TextField`, dan `SnackBar`
- Custom widget internal di `lib/shared/widgets/common_widgets.dart`, misalnya:
  - `AppPageScrollView`
  - `HeroPanel`
  - `AppSectionCard`
  - `KpiCard`
  - `StatusChip`
  - `SummaryRow`
  - `BottomSheetContainer`
  - `AppMediaPreview`
- Custom sheet internal:
  - `lib/shared/widgets/customer_form_sheet.dart`
  - `lib/shared/widgets/product_form_sheet.dart`
  - `lib/shared/widgets/store_profile_sheet.dart`

## Data, Backend, dan Penyimpanan

### Backend

Project ini memakai backend lokal, bukan REST API dan bukan Firebase.

- Database engine: SQLite
- Repository data: `lib/shared/database/pos_repository.dart`
- Inisialisasi database: `lib/shared/database/app_database.dart`
- Seed data awal: `lib/shared/database/database_seed.dart`
- Sumber seed object: `lib/shared/data/seed_data.dart`

### Nama database

- `warung_kopi_pos.db`

### Tabel utama

- `app_profile`
- `categories`
- `products`
- `customers`
- `transactions`
- `transaction_items`
- `debts`
- `debt_payments`
- `stock_movements`
- `operational_costs`

### Pola arsitektur data

- UI membaca state dari `PosAppState`
- `PosAppState` mengambil data lewat `PosRepository`
- `PosRepository` membaca/menulis ke SQLite
- Seed data dipakai untuk pertama kali pengisian database lokal

## Routing dan Struktur Fitur

Routing utama dikonfigurasi di `lib/app/routing/app_router.dart`.

Modul utama di folder `lib/features/`:

- `dashboard`
- `cashier`
- `products`
- `customers`
- `debts`
- `inventory`
- `reports`
- `analytics`
- `more`

Shell utama aplikasi:

- `lib/shared/widgets/app_shell.dart`

App bootstrap:

- `lib/main.dart`
- `lib/app/app.dart`

## Transaksi dan Histori

Data transaksi disimpan di:

- `transactions` untuk header transaksi
- `transaction_items` untuk detail item per transaksi

Histori dan detail transaksi sekarang difokuskan di modul Kasir:

- Tab `Transaksi Baru`
- Tab `Riwayat Transaksi`
- Detail transaksi melalui route `/cashier/transactions/:transactionId`

Metrik yang ditampilkan per transaksi:

- `qty total produk`
- `jumlah jenis item`

## Gambar dan Media

Pengelolaan gambar memakai:

- `file_picker` untuk memilih file gambar
- `AppMediaPreview` untuk render gambar

Sumber gambar yang didukung:

- path lokal hasil file picker
- URL remote `http://` atau `https://`

Implementasi picker:

- `lib/shared/utils/media_picker.dart`

## Chart dan Laporan

Chart dibuat dengan:

- `fl_chart`

Laporan saat ini masih berupa preview UI ringkas untuk:

- harian
- bulanan
- tahunan

Detail transaksi tidak diduplikasi di modul laporan supaya halaman laporan tetap fokus ke ringkasan periodik. Detail transaksi diakses dari `Kasir > Riwayat`.

## Menjalankan Project

```bash
flutter pub get
flutter run
```

## Perintah Penting

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Output Build APK

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Struktur Folder Ringkas

```text
lib/
  app/        -> bootstrap dan routing
  features/   -> modul fitur utama
  shared/     -> theme, state, model, database, widget reusable, utils

test/         -> widget test dan test database
android/      -> konfigurasi Android
```

## Catatan Tambahan

- Locale aplikasi diset ke Indonesia (`id_ID`)
- Format uang memakai `Rp`
- Project ini memakai database lokal, jadi data tersimpan di device/environment tempat aplikasi dijalankan
- Test menggunakan database in-memory agar aman dan cepat
