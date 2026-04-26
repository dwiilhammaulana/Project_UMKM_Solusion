# Warung Kopi POS

Aplikasi Point of Sale (POS) berbasis Flutter untuk warung kopi. Berjalan sepenuhnya secara lokal dengan database SQLite — fokus pada transaksi kasir, stok, pelanggan, BON, dan laporan ringkas.

---

## Gambaran Singkat

| | |
|---|---|
| **Platform** | Flutter, Android-first |
| **Bahasa** | Dart |
| **Backend** | Lokal (tanpa server/cloud) |
| **Database** | SQLite (lokal) |
| **State Management** | Riverpod |
| **Routing** | GoRouter |
| **UI** | Material 3 + custom widget internal |

---

## Stack & Teknologi

### Framework

- **Flutter** dengan **Dart SDK `^3.5.0`**

### UI & Design System

- Material 3 bawaan Flutter
- Theme kustom: `lib/shared/theme/app_theme.dart`
- Widget reusable: `lib/shared/widgets/common_widgets.dart`
- Shell & navigasi: `lib/shared/widgets/app_shell.dart`
- Form sheet kustom: customer, produk, profil toko

> Project ini tidak memakai Tailwind, Bootstrap, atau framework web UI lain. Seluruh tampilan dibangun dengan widget Flutter dan styling kustom internal.

### Font

| Font | Digunakan untuk |
|---|---|
| `Sora` | Heading |
| `Manrope` | Body text |

Keduanya di-load via package `google_fonts`.

---

## Dependencies

| Package | Fungsi |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Routing & nested route |
| `google_fonts` | Load font Sora & Manrope |
| `intl` | Format tanggal, waktu, dan mata uang Indonesia |
| `flutter_localizations` | Dukungan locale `id_ID` |
| `sqflite` | SQLite di Android/iOS |
| `sqflite_common_ffi` | SQLite untuk desktop/testing |
| `fl_chart` | Chart pada analitik & laporan BON |
| `file_picker` | Ambil file gambar dari perangkat |
| `path` | Pengolahan path file & database |

---

## Database & Penyimpanan

- **Engine:** SQLite lokal
- **Nama file:** `warung_kopi_pos.db`
- **Repository:** `lib/shared/database/pos_repository.dart`
- **Inisialisasi:** `lib/shared/database/app_database.dart`
- **Seed data:** `lib/shared/database/database_seed.dart` + `lib/shared/data/seed_data.dart`

### Tabel Utama

| Tabel | Keterangan |
|---|---|
| `app_profile` | Identitas & profil toko |
| `categories` | Kategori produk |
| `products` | Data produk (harga, stok, dll.) |
| `customers` | Data pelanggan |
| `transactions` | Header transaksi |
| `transaction_items` | Detail item per transaksi |
| `debts` | BON / piutang |
| `debt_payments` | Cicilan & pelunasan BON |
| `stock_movements` | Histori pergerakan stok |
| `operational_costs` | Biaya operasional per periode |

### Alur Data

```
UI → PosAppState → PosRepository → SQLite
```

---

## Arsitektur & Routing

### Struktur Folder

```
lib/
├── app/          # Bootstrap & routing
├── features/     # Modul fitur utama
└── shared/       # Theme, state, model, database, widget, utils

test/             # Widget test & database test
android/          # Konfigurasi Android
```

### Modul Fitur (`lib/features/`)

`dashboard` · `cashier` · `products` · `customers` · `debts` · `inventory` · `reports` · `analytics` · `more`

### File Kunci

| File | Peran |
|---|---|
| `lib/main.dart` | Entry point |
| `lib/app/app.dart` | Bootstrap aplikasi |
| `lib/app/routing/app_router.dart` | Konfigurasi routing |
| `lib/shared/widgets/app_shell.dart` | Shell & bottom navigation |

---

## Fitur Utama

### Transaksi & Kasir

- Tab **Transaksi Baru** dan **Riwayat Transaksi** di modul Kasir
- Detail transaksi via route `/cashier/transactions/:transactionId`
- Metrik per transaksi: total qty produk & jumlah jenis item
- Data disimpan di tabel `transactions` (header) dan `transaction_items` (detail)

### BON (Piutang)

- Dibuat otomatis saat checkout dengan metode `BON`
- Mendukung cicilan dan pelunasan bertahap via `debt_payments`
- Tracking per pelanggan

### Stok & Inventori

- Pergerakan stok otomatis tercatat ke `stock_movements` saat checkout
- Histori stok bisa ditelusuri per produk

### Laporan & Analitik

- Chart dibuat dengan `fl_chart`
- Laporan ringkas: harian, bulanan, tahunan
- Kalkulasi net profit menggunakan data `operational_costs`
- Detail transaksi tetap terpusat di **Kasir > Riwayat** (tidak diduplikasi di laporan)

### Gambar & Media

- Picker: `lib/shared/utils/media_picker.dart` via `file_picker`
- Render: widget `AppMediaPreview`
- Mendukung path lokal dan URL remote (`http://` / `https://`)

---

## Normalisasi Data

> Diturunkan dari implementasi schema SQLite aktif di `lib/shared/database/app_database.dart`.

### Skema Final (Tahap 3)

| Tabel | Primary Key | Foreign Key | Catatan |
|---|---|---|---|
| `app_profile` | `id` | — | Profil global toko |
| `categories` | `id` | — | Master kategori produk |
| `products` | `id` | `category_id → categories.id` | Katalog, kasir, inventori |
| `customers` | `id` | — | Transaksi BON & profil pelanggan |
| `transactions` | `id` | `customer_id → customers.id` | Header transaksi; `customer_name` disimpan sebagai snapshot |
| `transaction_items` | `id` | `transaction_id → transactions.id`, `product_id → products.id` | Detail item; `product_name` disimpan sebagai snapshot |
| `debts` | `id` | `transaction_id → transactions.id`, `customer_id → customers.id` | Hanya dibuat untuk transaksi metode `BON` |
| `debt_payments` | `id` | `debt_id → debts.id`, `customer_id → customers.id` | Cicilan & pelunasan BON |
| `stock_movements` | `id` | `product_id → products.id` | Tercatat otomatis saat checkout |
| `operational_costs` | `id` | — | Laporan bulanan & kalkulasi net profit |

> **Catatan:** Tabel `raw_materials` tidak ada di schema SQLite aktif sehingga tidak dimasukkan ke normalisasi ini.

---

## Use Case Diagram

```mermaid
usecaseDiagram
  actor Kasir as "Kasir / Penjual"

  rectangle "Warung Kopi POS" {
    (Lihat Dashboard) as UC1
    (Kelola Profil Toko) as UC2
    (Kelola Produk) as UC3
    (Buat Transaksi Baru) as UC4
    (Pilih Produk ke Keranjang) as UC5
    (Pilih / Tambah Pelanggan) as UC6
    (Checkout Transaksi Non-BON) as UC7
    (Checkout Transaksi BON) as UC8
    (Lihat Riwayat & Detail Transaksi) as UC9
    (Kelola Pelanggan) as UC10
    (Pantau & Kelola BON) as UC11
    (Catat Cicilan / Tandai Lunas) as UC12
    (Pantau Stok & Pergerakan) as UC13
    (Kelola Biaya Operasional) as UC14
    (Lihat Laporan Ringkas) as UC15
    (Lihat Analitik) as UC16
  }

  Kasir --> UC1
  Kasir --> UC2
  Kasir --> UC3
  Kasir --> UC4
  Kasir --> UC7
  Kasir --> UC8
  Kasir --> UC9
  Kasir --> UC10
  Kasir --> UC11
  Kasir --> UC12
  Kasir --> UC13
  Kasir --> UC14
  Kasir --> UC15
  Kasir --> UC16

  UC4 .> UC5 : <<include>>
  UC8 .> UC6 : <<include>>
  UC11 .> UC12 : <<include>>
```

> Diagram ini hanya memuat flow yang aktif di repo saat ini. Auth/login, notifikasi WhatsApp, export PDF final, dan backend cloud belum termasuk karena belum menjadi implementasi aktif.

---

## Menjalankan Project

```bash
# Install dependencies
flutter pub get

# Jalankan aplikasi
flutter run
```

### Perintah Lain

```bash
flutter analyze          # Cek kode
flutter test             # Jalankan test
flutter build apk --debug  # Build APK debug
```

**Output APK:** `build/app/outputs/flutter-apk/app-debug.apk`

---

## Catatan

- Locale aplikasi: **Indonesia (`id_ID`)**
- Format mata uang: **Rp**
- Data tersimpan sepenuhnya di perangkat (lokal, tanpa sinkronisasi cloud)
- Test memakai **database in-memory** agar aman dan cepat