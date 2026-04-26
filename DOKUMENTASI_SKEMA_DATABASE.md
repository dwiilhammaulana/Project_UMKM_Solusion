# Dokumentasi Skema Database Warung Kopi POS

Dokumen ini disusun dari schema SQLite aktif pada [lib/shared/database/app_database.dart](/D:/kulyah/smt%206/project%203/Warung%20Kopi/lib/shared/database/app_database.dart:17) dan enum pendukung pada [lib/shared/models/app_models.dart](/D:/kulyah/smt%206/project%203/Warung%20Kopi/lib/shared/models/app_models.dart:1).

## 1. Identitas Schema

| Komponen | Nilai |
|---|---|
| Database engine | SQLite |
| Nama file database | `warung_kopi_pos.db` |
| Schema version | `3` |
| Foreign key enforcement | Aktif melalui `PRAGMA foreign_keys = ON` |
| Sumber kebenaran utama | `lib/shared/database/app_database.dart` |

## 2. Daftar Tabel

### 2.1 `app_profile`

Fungsi: menyimpan identitas global toko yang dipakai di seluruh aplikasi.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik profil toko. Implementasi saat ini memakai nilai tetap `store-main`. |
| `store_name` | `TEXT` | `NOT NULL` | Nama toko. |
| `store_subtitle` | `TEXT` | `NOT NULL` | Subjudul atau deskripsi singkat toko. |
| `owner_name` | `TEXT` | `NULL` | Nama pemilik toko. |
| `photo_path` | `TEXT` | `NULL` | Path lokal foto atau logo toko. |

Relasi: tidak memiliki foreign key.

### 2.2 `categories`

Fungsi: menyimpan master kategori untuk pengelompokan produk.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik kategori. |
| `name` | `TEXT` | `NOT NULL` | Nama kategori produk. |
| `description` | `TEXT` | `NULL` | Deskripsi tambahan kategori. |

Relasi: menjadi parent untuk tabel `products`.

### 2.3 `products`

Fungsi: menyimpan data master produk yang dipakai pada kasir, inventori, dan stok.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik produk. |
| `category_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY` | Mengacu ke kategori produk pada `categories.id`. |
| `name` | `TEXT` | `NOT NULL` | Nama produk. |
| `sell_price` | `REAL` | `NOT NULL` | Harga jual produk. |
| `cost_price` | `REAL` | `NOT NULL` | Harga pokok atau modal produk. |
| `stock_qty` | `INTEGER` | `NOT NULL DEFAULT 0` | Jumlah stok saat ini. |
| `min_stock` | `INTEGER` | `NOT NULL DEFAULT 0` | Ambang minimum stok. |
| `unit` | `TEXT` | `NOT NULL` | Satuan produk, misalnya gelas atau pcs. |
| `rack_location` | `TEXT` | `NULL` | Lokasi rak atau penyimpanan produk. |
| `image_path` | `TEXT` | `NULL` | Path lokal gambar produk. |
| `is_active` | `INTEGER` | `NOT NULL DEFAULT 1` | Status aktif produk dengan representasi boolean semu `1` atau `0`. |

Relasi:
- `category_id -> categories.id` dengan `ON DELETE RESTRICT`

### 2.4 `customers`

Fungsi: menyimpan data pelanggan untuk transaksi BON dan pengelolaan pelanggan.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik pelanggan. |
| `name` | `TEXT` | `NOT NULL` | Nama pelanggan. |
| `phone` | `TEXT` | `NOT NULL` | Nomor telepon pelanggan. |
| `address` | `TEXT` | `NOT NULL` | Alamat pelanggan. |
| `notes` | `TEXT` | `NULL` | Catatan tambahan pelanggan. |
| `is_active` | `INTEGER` | `NOT NULL DEFAULT 1` | Status aktif pelanggan dengan representasi boolean semu `1` atau `0`. |
| `created_at` | `TEXT` | `NOT NULL` | Timestamp pembuatan data pelanggan dalam format ISO8601. |

Relasi: menjadi parent untuk `transactions`, `debts`, dan `debt_payments`.

### 2.5 `transactions`

Fungsi: menyimpan header transaksi kasir.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik transaksi. |
| `transaction_code` | `TEXT` | `NOT NULL UNIQUE` | Kode transaksi harian yang unik. |
| `customer_id` | `TEXT` | `NULL`, `FOREIGN KEY` | Referensi ke pelanggan jika transaksi terkait pelanggan tertentu. |
| `customer_name` | `TEXT` | `NOT NULL` | Snapshot nama pelanggan saat transaksi dibuat. Nilai ini disimpan langsung, bukan hasil join dinamis. |
| `total_amount` | `REAL` | `NOT NULL` | Total nilai transaksi. |
| `payment_method` | `TEXT` | `NOT NULL` | Metode pembayaran. Nilai valid: `cash`, `qris`, `transfer`, `card`, `bon`. |
| `amount_paid` | `REAL` | `NOT NULL DEFAULT 0` | Jumlah yang dibayar saat transaksi dibuat. |
| `change_amount` | `REAL` | `NOT NULL DEFAULT 0` | Nilai kembalian transaksi. |
| `notes` | `TEXT` | `NULL` | Catatan transaksi. |
| `created_at` | `TEXT` | `NOT NULL` | Timestamp transaksi dalam format ISO8601. |

Relasi:
- `customer_id -> customers.id` dengan `ON DELETE SET NULL`

### 2.6 `transaction_items`

Fungsi: menyimpan detail item pada setiap transaksi.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Primary key numerik yang bertambah otomatis. |
| `transaction_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY` | Referensi ke header transaksi. |
| `product_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY` | Referensi ke produk yang dijual. |
| `product_name` | `TEXT` | `NOT NULL` | Snapshot nama produk saat transaksi dibuat. Nilai ini disimpan langsung, bukan hasil join dinamis. |
| `quantity` | `INTEGER` | `NOT NULL` | Jumlah unit produk pada baris transaksi. |
| `sell_price` | `REAL` | `NOT NULL` | Harga jual per unit saat transaksi dibuat. |

Relasi:
- `transaction_id -> transactions.id` dengan `ON DELETE CASCADE`
- `product_id -> products.id` dengan `ON DELETE RESTRICT`

### 2.7 `debts`

Fungsi: menyimpan data BON atau piutang yang berasal dari transaksi.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik BON atau piutang. |
| `transaction_id` | `TEXT` | `NOT NULL UNIQUE`, `FOREIGN KEY` | Referensi ke transaksi sumber. Sifat `UNIQUE` membuat relasi efektif `transactions 1..1 debts`. |
| `customer_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY` | Referensi ke pelanggan pemilik BON. |
| `customer_name` | `TEXT` | `NOT NULL` | Snapshot nama pelanggan saat BON dibuat. |
| `original_amount` | `REAL` | `NOT NULL` | Nilai awal utang. |
| `paid_amount` | `REAL` | `NOT NULL DEFAULT 0` | Total nominal yang sudah dibayar. |
| `due_date` | `TEXT` | `NULL` | Tanggal jatuh tempo dalam format ISO8601. |
| `notes` | `TEXT` | `NULL` | Catatan terkait BON. |
| `created_at` | `TEXT` | `NOT NULL` | Timestamp pembuatan BON dalam format ISO8601. |
| `updated_at` | `TEXT` | `NOT NULL` | Timestamp pembaruan BON dalam format ISO8601. |

Relasi:
- `transaction_id -> transactions.id` dengan `ON DELETE CASCADE`
- `customer_id -> customers.id` dengan `ON DELETE RESTRICT`

Catatan implementasi:
- Tabel ini hanya dibuat oleh aplikasi saat checkout menggunakan metode pembayaran `bon` dan `customer_id` tersedia.

### 2.8 `debt_payments`

Fungsi: menyimpan histori pembayaran cicilan atau pelunasan BON.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik pembayaran BON. |
| `debt_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY` | Referensi ke data BON yang dibayar. |
| `customer_id` | `TEXT` | `NOT NULL`, `FOREIGN KEY` | Referensi ke pelanggan yang melakukan pembayaran. |
| `amount` | `REAL` | `NOT NULL` | Nominal pembayaran BON. |
| `payment_method` | `TEXT` | `NOT NULL` | Metode pembayaran. Nilai valid: `cash`, `qris`, `transfer`, `card`, `bon`. |
| `notes` | `TEXT` | `NULL` | Catatan pembayaran. |
| `paid_at` | `TEXT` | `NOT NULL` | Timestamp pembayaran dalam format ISO8601. |

Relasi:
- `debt_id -> debts.id` dengan `ON DELETE CASCADE`
- `customer_id -> customers.id` dengan `ON DELETE RESTRICT`

### 2.9 `stock_movements`

Fungsi: menyimpan histori pergerakan stok produk.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik pergerakan stok. |
| `product_id` | `TEXT` | `NULL`, `FOREIGN KEY` | Referensi ke produk terkait. Dapat menjadi `NULL` jika produk terhapus dan foreign key menjalankan `SET NULL`. |
| `reference_name` | `TEXT` | `NOT NULL` | Nama referensi pergerakan, saat ini biasanya nama produk. |
| `quantity` | `REAL` | `NOT NULL` | Jumlah pergerakan stok. |
| `type` | `TEXT` | `NOT NULL` | Jenis pergerakan stok. Nilai valid: `stockIn`, `stockOut`. |
| `notes` | `TEXT` | `NULL` | Catatan pergerakan stok. |
| `created_at` | `TEXT` | `NOT NULL` | Timestamp pergerakan stok dalam format ISO8601. |

Relasi:
- `product_id -> products.id` dengan `ON DELETE SET NULL`

Catatan implementasi:
- Pada implementasi aktif, data `stock_movements` otomatis ditambahkan saat checkout untuk mencatat pengurangan stok.

### 2.10 `operational_costs`

Fungsi: menyimpan biaya operasional yang dipakai untuk laporan dan perhitungan laba bersih.

| Nama field | Tipe data | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `TEXT` | `PRIMARY KEY` | ID unik biaya operasional. |
| `month_year` | `TEXT` | `NOT NULL` | Periode bulan yang dinormalisasi ke tanggal awal bulan dalam format ISO8601. |
| `cost_name` | `TEXT` | `NOT NULL` | Nama komponen biaya operasional. |
| `amount` | `REAL` | `NOT NULL` | Nominal biaya operasional. |

Relasi: tidak memiliki foreign key.

## 3. Relasi Antar Tabel

| Relasi | Kardinalitas | Foreign key | Aksi `ON DELETE` | Keterangan |
|---|---|---|---|---|
| `categories -> products` | `1..*` | `products.category_id` | `RESTRICT` | Satu kategori dapat dipakai banyak produk. |
| `customers -> transactions` | `1..*` | `transactions.customer_id` | `SET NULL` | Pelanggan pada transaksi bersifat opsional. |
| `transactions -> transaction_items` | `1..*` | `transaction_items.transaction_id` | `CASCADE` | Detail item ikut terhapus saat transaksi dihapus. |
| `products -> transaction_items` | `1..*` | `transaction_items.product_id` | `RESTRICT` | Produk yang sudah pernah dipakai transaksi tidak boleh dihapus lewat foreign key. |
| `transactions -> debts` | `1..1` | `debts.transaction_id` | `CASCADE` | Dibatasi `UNIQUE`, sehingga satu transaksi hanya dapat memiliki satu BON. |
| `customers -> debts` | `1..*` | `debts.customer_id` | `RESTRICT` | Satu pelanggan dapat memiliki banyak BON. |
| `debts -> debt_payments` | `1..*` | `debt_payments.debt_id` | `CASCADE` | Riwayat pembayaran ikut terhapus saat BON dihapus. |
| `customers -> debt_payments` | `1..*` | `debt_payments.customer_id` | `RESTRICT` | Setiap pembayaran BON terkait pelanggan tertentu. |
| `products -> stock_movements` | `1..*` | `stock_movements.product_id` | `SET NULL` | Riwayat stok tetap dipertahankan walau produk terhapus. |

## 4. Catatan Implementasi

- Semua field tanggal dan waktu disimpan sebagai `TEXT` dalam format ISO8601, misalnya `created_at`, `updated_at`, `paid_at`, `due_date`, dan `month_year`.
- Field enum disimpan sebagai `TEXT`.
- Nilai enum `payment_method`: `cash`, `qris`, `transfer`, `card`, `bon`.
- Nilai enum `stock_movements.type`: `stockIn`, `stockOut`.
- Field boolean semu disimpan sebagai `INTEGER` dengan pola `1` untuk aktif atau benar dan `0` untuk nonaktif atau salah.
- `transactions.customer_name` disimpan sebagai snapshot nama pelanggan saat transaksi dibuat.
- `transaction_items.product_name` disimpan sebagai snapshot nama produk saat transaksi dibuat.
- Tabel `raw_materials` tidak termasuk karena tidak ada pada schema SQLite aktif.

## 5. Catatan Indeks

Schema aktif juga membuat beberapa indeks untuk optimasi query:

| Nama indeks | Tabel | Kolom |
|---|---|---|
| `idx_transactions_created_at` | `transactions` | `created_at` |
| `idx_transactions_customer_id` | `transactions` | `customer_id` |
| `idx_transaction_items_transaction_id` | `transaction_items` | `transaction_id` |
| `idx_debts_customer_id` | `debts` | `customer_id` |
| `idx_debts_updated_at` | `debts` | `updated_at` |
| `idx_debt_payments_debt_id` | `debt_payments` | `debt_id` |
| `idx_stock_movements_product_created_at` | `stock_movements` | `product_id`, `created_at` |

## 6. Kesimpulan Singkat

Schema database Warung Kopi POS terdiri dari 10 tabel utama yang mencakup profil toko, master data, transaksi, BON, histori pembayaran, pergerakan stok, dan biaya operasional. Struktur relasinya sudah mendukung kebutuhan kasir lokal berbasis SQLite dengan pemisahan yang jelas antara data master, header transaksi, detail transaksi, dan data turunan seperti BON serta histori stok.
