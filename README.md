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

## UML Use Case Diagram

Diagram berikut diturunkan dari implementasi repo saat ini, terutama route, screen, state, dan repository yang benar-benar aktif di aplikasi. Jadi isi diagram ini mengikuti alur aplikasi yang berjalan sekarang, bukan alur lama di PRD atau README yang belum diperbarui.

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

Catatan penting:

- Diagram ini hanya memuat flow yang benar-benar aktif di repo saat ini.
- `raw_materials` tidak dimasukkan karena tidak ada tabel persist khususnya di schema SQLite sekarang.
- Backend cloud, Supabase, auth/login, notifikasi WhatsApp, dan export PDF final tidak dimasukkan karena belum menjadi flow implementasi aktif.
- Laporan saat ini masih berupa preview UI ringkas, sedangkan detail transaksi tetap dipusatkan di modul `Kasir > Riwayat`.

## Normalisasi Data (Inferensi dari Implementasi Repo)

Bagian ini merupakan dokumentasi normalisasi yang **diinferensikan dari implementasi repo saat ini**, khususnya schema SQLite di `lib/shared/database/app_database.dart` dan alur fitur aktif di aplikasi. Dokumen elisitasi asli tahap 1 sampai tahap 3 tidak tersedia di workspace, jadi tabel di bawah adalah rekonstruksi teknis yang diselaraskan dengan implementasi aktual.

### Elisitasi Tahap 1

Tahap ini memandang data sebagai satu himpunan besar yang masih bercampur antara informasi toko, produk, pelanggan, transaksi, BON, pembayaran BON, stok, dan biaya operasional.

| Nama Relasi Mentah | Atribut Campuran |
|---|---|
| `POS_WARUNG_KOPI_MENTAH` | `store_id`, `store_name`, `store_subtitle`, `owner_name`, `photo_path`, `category_id`, `category_name`, `category_description`, `product_id`, `product_name`, `product_category_id`, `sell_price`, `cost_price`, `stock_qty`, `min_stock`, `unit`, `rack_location`, `product_image_path`, `product_is_active`, `customer_id`, `customer_name`, `customer_phone`, `customer_address`, `customer_notes`, `customer_is_active`, `customer_created_at`, `transaction_id`, `transaction_code`, `transaction_customer_id`, `transaction_customer_name`, `transaction_total_amount`, `transaction_payment_method`, `transaction_amount_paid`, `transaction_change_amount`, `transaction_notes`, `transaction_created_at`, `transaction_item_id`, `transaction_item_product_id`, `transaction_item_product_name`, `transaction_item_quantity`, `transaction_item_sell_price`, `debt_id`, `debt_transaction_id`, `debt_customer_id`, `debt_customer_name`, `debt_original_amount`, `debt_paid_amount`, `debt_due_date`, `debt_notes`, `debt_created_at`, `debt_updated_at`, `debt_payment_id`, `debt_payment_debt_id`, `debt_payment_customer_id`, `debt_payment_amount`, `debt_payment_method`, `debt_payment_notes`, `debt_payment_paid_at`, `stock_movement_id`, `stock_movement_product_id`, `stock_movement_reference_name`, `stock_movement_quantity`, `stock_movement_type`, `stock_movement_notes`, `stock_movement_created_at`, `operational_cost_id`, `operational_cost_month_year`, `operational_cost_name`, `operational_cost_amount` |

### Elisitasi Tahap 2

Pada tahap ini atribut campuran mulai dipisah ke kandidat entitas agar ketergantungan data lebih jelas dan pengulangan atribut dapat dikurangi.

| Entitas | Atribut | Kunci | Catatan |
|---|---|---|---|
| `AppProfile` | `id`, `store_name`, `store_subtitle`, `owner_name`, `photo_path` | `id` | Identitas toko dipisah dari transaksi dan produk karena sifatnya global untuk aplikasi. |
| `Category` | `id`, `name`, `description` | `id` | Kategori dipisah agar satu kategori dapat dipakai banyak produk. |
| `Product` | `id`, `category_id`, `name`, `sell_price`, `cost_price`, `stock_qty`, `min_stock`, `unit`, `rack_location`, `image_path`, `is_active` | `id`, `category_id` | Data produk dipisah dari transaksi, tetapi sebagian snapshot nama dan harga tetap disalin ke item transaksi saat checkout. |
| `Customer` | `id`, `name`, `phone`, `address`, `notes`, `is_active`, `created_at` | `id` | Pelanggan dipisah agar histori transaksi dan BON bisa dilacak lintas transaksi. |
| `Transaction` | `id`, `transaction_code`, `customer_id`, `customer_name`, `total_amount`, `payment_method`, `amount_paid`, `change_amount`, `notes`, `created_at` | `id`, `customer_id` | Header transaksi dipisah dari detail item. `customer_name` disimpan sebagai snapshot tampilan transaksi. |
| `TransactionItem` | `id`, `transaction_id`, `product_id`, `product_name`, `quantity`, `sell_price` | `id`, `transaction_id`, `product_id` | Setiap transaksi dapat memiliki banyak baris item. `product_name` ikut disimpan sebagai snapshot. |
| `Debt` | `id`, `transaction_id`, `customer_id`, `customer_name`, `original_amount`, `paid_amount`, `due_date`, `notes`, `created_at`, `updated_at` | `id`, `transaction_id`, `customer_id` | Entitas ini hanya muncul bila checkout memakai metode `BON`. |
| `DebtPayment` | `id`, `debt_id`, `customer_id`, `amount`, `payment_method`, `notes`, `paid_at` | `id`, `debt_id`, `customer_id` | Satu BON dapat memiliki banyak pembayaran cicilan atau pelunasan. |
| `StockMovement` | `id`, `product_id`, `reference_name`, `quantity`, `type`, `notes`, `created_at` | `id`, `product_id` | Pergerakan stok dipisah agar histori stok keluar saat transaksi bisa ditelusuri. |
| `OperationalCost` | `id`, `month_year`, `cost_name`, `amount` | `id` | Biaya operasional dipisah untuk perhitungan laporan dan net profit per periode. |

### Elisitasi Tahap 3 / Hasil Normalisasi

Tahap akhir berikut disejajarkan langsung dengan schema SQLite yang dipakai aplikasi saat ini.

| Tabel | Primary Key | Foreign Key | Atribut Utama | Kesesuaian dengan Implementasi |
|---|---|---|---|---|
| `app_profile` | `id` | - | `store_name`, `store_subtitle`, `owner_name`, `photo_path` | Sesuai schema SQLite. Dipakai untuk profil toko di dashboard dan modul lainnya. |
| `categories` | `id` | - | `name`, `description` | Sesuai schema SQLite. Menjadi master kategori produk. |
| `products` | `id` | `category_id -> categories.id` | `name`, `sell_price`, `cost_price`, `stock_qty`, `min_stock`, `unit`, `rack_location`, `image_path`, `is_active` | Sesuai schema SQLite dan dipakai di katalog, kasir, dan inventory. |
| `customers` | `id` | - | `name`, `phone`, `address`, `notes`, `is_active`, `created_at` | Sesuai schema SQLite. Dipakai untuk transaksi BON dan profil pelanggan. |
| `transactions` | `id` | `customer_id -> customers.id` | `transaction_code`, `customer_name`, `total_amount`, `payment_method`, `amount_paid`, `change_amount`, `notes`, `created_at` | Sesuai schema SQLite. Menyimpan header transaksi kasir. |
| `transaction_items` | `id` | `transaction_id -> transactions.id`, `product_id -> products.id` | `product_name`, `quantity`, `sell_price` | Sesuai schema SQLite. Menyimpan detail item per transaksi. |
| `debts` | `id` | `transaction_id -> transactions.id`, `customer_id -> customers.id` | `customer_name`, `original_amount`, `paid_amount`, `due_date`, `notes`, `created_at`, `updated_at` | Sesuai schema SQLite. Dibuat otomatis ketika transaksi memakai metode `BON`. |
| `debt_payments` | `id` | `debt_id -> debts.id`, `customer_id -> customers.id` | `amount`, `payment_method`, `notes`, `paid_at` | Sesuai schema SQLite. Dipakai untuk cicilan dan pelunasan BON. |
| `stock_movements` | `id` | `product_id -> products.id` | `reference_name`, `quantity`, `type`, `notes`, `created_at` | Sesuai schema SQLite. Saat checkout, stok keluar dicatat ke tabel ini. |
| `operational_costs` | `id` | - | `month_year`, `cost_name`, `amount` | Sesuai schema SQLite. Dipakai dalam laporan bulanan dan perhitungan net profit. |

Catatan pembatasan:

- Tabel normalisasi di atas tidak memasukkan `raw_materials` karena tabel persist tersebut belum ada di schema SQLite aktif.
- Dokumentasi ini tidak memasukkan backend cloud atau Supabase karena implementasi sekarang berjalan lokal dengan SQLite.
- Export PDF final, auth/login, dan fitur server-side lain tidak dijadikan entitas karena belum tercermin sebagai flow atau schema aktif di repo saat ini.

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
