# Warung Kopi POS

Project Flutter POS Warung Kopi dengan struktur yang mudah dikembangkan kembali.

## Kebutuhan

- Flutter SDK yang aktif di mesin Anda
- Android SDK
- Perangkat Android atau emulator

## Menjalankan Project

```bash
flutter pub get
flutter run
```

Project ini tidak memakai Node.js atau `npm install`. Dependency yang dipakai dikelola oleh Flutter melalui `pubspec.yaml`.

Saat aplikasi pertama kali dijalankan, database lokal SQLite `warung_kopi_pos.db` akan dibuat otomatis dan langsung diisi seed data awal.

## Build APK Debug

```bash
flutter build apk --debug
```

Hasil APK debug ada di:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Struktur Folder

```text
lib/
  app/        -> bootstrap app, router, konfigurasi utama
  features/   -> layar dan fitur per domain
  shared/     -> model, state, database, theme, widget umum, formatter
test/         -> widget test dan flow test utama
android/      -> konfigurasi Android
```

## Struktur Database

Database lokal memakai SQLite dengan nama `warung_kopi_pos.db`.

### Tabel

#### `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `name` | `TEXT NOT NULL` | Nama kategori |
| `description` | `TEXT` | Deskripsi kategori |

#### `products`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `category_id` | `TEXT NOT NULL` | FK ke `categories.id` |
| `name` | `TEXT NOT NULL` | Nama produk |
| `sell_price` | `REAL NOT NULL` | Harga jual |
| `cost_price` | `REAL NOT NULL` | Harga modal |
| `stock_qty` | `INTEGER NOT NULL DEFAULT 0` | Stok saat ini |
| `min_stock` | `INTEGER NOT NULL DEFAULT 0` | Batas minimum stok |
| `unit` | `TEXT NOT NULL` | Satuan |
| `rack_location` | `TEXT` | Lokasi rak |
| `is_active` | `INTEGER NOT NULL DEFAULT 1` | Status aktif produk |

#### `customers`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `name` | `TEXT NOT NULL` | Nama pelanggan |
| `phone` | `TEXT NOT NULL` | Nomor telepon |
| `address` | `TEXT NOT NULL` | Alamat |
| `notes` | `TEXT` | Catatan pelanggan |
| `is_active` | `INTEGER NOT NULL DEFAULT 1` | Status aktif pelanggan |
| `created_at` | `TEXT NOT NULL` | Waktu dibuat |

#### `transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `transaction_code` | `TEXT NOT NULL UNIQUE` | Kode transaksi |
| `customer_id` | `TEXT` | FK ke `customers.id`, boleh `NULL` untuk pembeli umum |
| `customer_name` | `TEXT NOT NULL` | Nama pelanggan saat transaksi |
| `total_amount` | `REAL NOT NULL` | Total transaksi |
| `payment_method` | `TEXT NOT NULL` | Metode pembayaran |
| `amount_paid` | `REAL NOT NULL DEFAULT 0` | Nominal dibayar |
| `change_amount` | `REAL NOT NULL DEFAULT 0` | Kembalian |
| `notes` | `TEXT` | Catatan transaksi |
| `created_at` | `TEXT NOT NULL` | Waktu transaksi |

#### `transaction_items`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `INTEGER` | Primary key autoincrement |
| `transaction_id` | `TEXT NOT NULL` | FK ke `transactions.id` |
| `product_id` | `TEXT NOT NULL` | FK ke `products.id` |
| `product_name` | `TEXT NOT NULL` | Snapshot nama produk |
| `quantity` | `INTEGER NOT NULL` | Jumlah item |
| `sell_price` | `REAL NOT NULL` | Harga jual saat transaksi |

#### `debts`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `transaction_id` | `TEXT NOT NULL UNIQUE` | FK ke `transactions.id` |
| `customer_id` | `TEXT NOT NULL` | FK ke `customers.id` |
| `customer_name` | `TEXT NOT NULL` | Nama pelanggan saat bon dibuat |
| `original_amount` | `REAL NOT NULL` | Nominal utang awal |
| `paid_amount` | `REAL NOT NULL DEFAULT 0` | Total yang sudah dibayar |
| `due_date` | `TEXT` | Tanggal jatuh tempo |
| `notes` | `TEXT` | Catatan utang |
| `created_at` | `TEXT NOT NULL` | Waktu dibuat |
| `updated_at` | `TEXT NOT NULL` | Waktu terakhir diperbarui |

#### `debt_payments`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `debt_id` | `TEXT NOT NULL` | FK ke `debts.id` |
| `customer_id` | `TEXT NOT NULL` | FK ke `customers.id` |
| `amount` | `REAL NOT NULL` | Nominal pembayaran |
| `payment_method` | `TEXT NOT NULL` | Metode pembayaran cicilan |
| `notes` | `TEXT` | Catatan pembayaran |
| `paid_at` | `TEXT NOT NULL` | Waktu pembayaran |

#### `stock_movements`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `product_id` | `TEXT` | FK ke `products.id`, boleh `NULL` |
| `reference_name` | `TEXT NOT NULL` | Nama referensi produk/pergerakan |
| `quantity` | `REAL NOT NULL` | Jumlah stok masuk/keluar |
| `type` | `TEXT NOT NULL` | Jenis pergerakan stok |
| `notes` | `TEXT` | Catatan |
| `created_at` | `TEXT NOT NULL` | Waktu pergerakan |

#### `operational_costs`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | `TEXT` | Primary key |
| `month_year` | `TEXT NOT NULL` | Bulan biaya |
| `cost_name` | `TEXT NOT NULL` | Nama biaya |
| `amount` | `REAL NOT NULL` | Nominal biaya |

### Relasi

- `categories` 1 -> N `products`
- `customers` 1 -> N `transactions`
- `transactions` 1 -> N `transaction_items`
- `products` 1 -> N `transaction_items`
- `transactions` 1 -> 0..1 `debts`
- `customers` 1 -> N `debts`
- `debts` 1 -> N `debt_payments`
- `customers` 1 -> N `debt_payments`
- `products` 1 -> N `stock_movements`

### Enum yang Disimpan sebagai TEXT

- `payment_method`: `cash`, `qris`, `transfer`, `card`, `bon`
- `stock_movements.type`: `stockIn`, `stockOut`

### Index

- `transactions(created_at)`
- `transactions(customer_id)`
- `transaction_items(transaction_id)`
- `debts(customer_id)`
- `debts(updated_at)`
- `debt_payments(debt_id)`
- `stock_movements(product_id, created_at)`

## Alur Transaksi

### 1. Transaksi Tunai / Non-BON

1. Kasir memilih produk dan menambahkannya ke keranjang.
2. Sistem menghitung total belanja dari isi `cart`.
3. Kasir bisa memilih pelanggan terdaftar atau membiarkan sebagai `Umum / Tanpa Nama`.
4. Kasir memilih metode pembayaran: `cash`, `qris`, `transfer`, atau `card`.
5. Saat checkout:
   - sistem membuat 1 record di tabel `transactions`
   - sistem membuat beberapa record di tabel `transaction_items`
   - sistem mengurangi `products.stock_qty`
   - sistem mencatat pergerakan stok keluar ke tabel `stock_movements` dengan tipe `stockOut`
6. Karena transaksi langsung dibayar, `amount_paid` akan sama dengan `total_amount`.
7. Tidak ada record baru di tabel `debts`.

### 2. Transaksi BON

1. Kasir memilih produk dan menambahkannya ke keranjang.
2. Kasir wajib memilih pelanggan terdaftar.
3. Kasir memilih metode pembayaran `bon`.
4. Saat checkout:
   - sistem membuat 1 record di tabel `transactions`
   - `amount_paid` diisi `0`
   - sistem membuat record item di `transaction_items`
   - sistem mengurangi `products.stock_qty`
   - sistem mencatat `stock_movements` bertipe `stockOut`
   - sistem membuat 1 record baru di tabel `debts`
5. Record `debts` menyimpan:
   - transaksi asal
   - pelanggan yang berutang
   - nominal utang awal di `original_amount`
   - total pembayaran saat ini di `paid_amount`
   - tanggal jatuh tempo dan catatan bila ada

### 3. Pembayaran Cicilan / Pelunasan BON

1. Kasir membuka halaman bon/utang lalu memilih utang pelanggan.
2. Kasir memasukkan nominal pembayaran.
3. Sistem membatasi nominal agar tidak melebihi sisa utang.
4. Saat pembayaran disimpan:
   - sistem membuat 1 record di tabel `debt_payments`
   - sistem menambahkan nominal tersebut ke `debts.paid_amount`
   - sistem memperbarui `debts.updated_at`
5. Status utang dihitung dari model aplikasi:
   - `unpaid` jika belum ada pembayaran
   - `partial` jika sudah ada pembayaran tapi belum lunas
   - `paid` jika `paid_amount >= original_amount`

### 4. Dampak ke Dashboard dan Laporan

- `Transaksi Hari Ini` dihitung dari tabel `transactions`
- `Pendapatan Tercatat` dihitung dari:
  - `transactions.amount_paid`
  - ditambah semua `debt_payments.amount`
- `Bon Aktif` dihitung dari total `original_amount - paid_amount` pada tabel `debts`
- `Stok Menipis` dihitung dari produk dengan `stock_qty <= min_stock`
- grafik laporan bulanan/tahunan tidak disimpan sebagai tabel khusus, tetapi dihitung dari data transaksi, pembayaran bon, dan biaya operasional

### Ringkasan Alur Data

```text
Kasir pilih produk
-> cart
-> checkout
-> transactions
-> transaction_items
-> products.stock_qty berkurang
-> stock_movements tercatat

Jika metode = BON
-> debts dibuat

Jika ada pembayaran bon
-> debt_payments dibuat
-> debts.paid_amount di-update
```

## Perintah Penting

```bash
flutter analyze
flutter test
flutter build apk --debug
```
#   P r o j e c t _ U M K M _ S o l u s i o n  
 