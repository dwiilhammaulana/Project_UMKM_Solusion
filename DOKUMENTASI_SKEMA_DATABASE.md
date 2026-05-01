# Dokumentasi Skema Database Warung Kopi POS

Dokumen ini menjelaskan schema database aktif setelah migrasi ke Supabase. Sumber kebenaran utama adalah migration SQL di `supabase/migrations/` dan repository aktif di `lib/shared/database/supabase_pos_repository.dart`.

---

## 1. Identitas Schema

| Komponen | Nilai |
|---|---|
| Database engine | Supabase PostgreSQL |
| Backend client | `supabase_flutter` |
| Auth | Supabase Auth |
| Sumber schema | `supabase/migrations/20260426_000001_initial_schema.sql` |
| Ownership & RLS | `supabase/migrations/20260429_000003_repair_auth_ownership_rls.sql` |
| Repository aktif | `lib/shared/database/supabase_pos_repository.dart` |
| Provider aktif | `posRepositoryProvider` di `lib/shared/state/app_state.dart` |

Migration awal mempertahankan banyak tipe dari SQLite lama untuk mengurangi risiko migrasi data:

- ID operasional masih `text`.
- Timestamp masih `text` ISO8601.
- Enum disimpan sebagai `text`.
- Boolean lama masih memakai integer `0` / `1`.

---

## 2. Auth, Ownership, dan RLS

Supabase Auth menjadi sumber identitas user. Migration ownership menambahkan tabel `profiles` dan kolom `owner_user_id` ke semua tabel operasional.

### 2.1 `profiles`

Fungsi: menyimpan profil akun yang terhubung ke `auth.users`.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `uuid` | PK, FK ke `auth.users(id)` | ID user Supabase |
| `email` | `text` | NOT NULL | Email akun |
| `full_name` | `text` | NULL | Nama lengkap dari metadata auth |
| `avatar_url` | `text` | NULL | Avatar dari metadata auth |
| `created_at` | `text` | default waktu UTC | Timestamp pembuatan |
| `updated_at` | `text` | default waktu UTC | Timestamp update |

Trigger `on_auth_user_created` membuat atau memperbarui row `profiles` saat user dibuat.

### 2.2 Pola Ownership

Tabel operasional berikut memiliki `owner_user_id uuid references auth.users(id) on delete cascade`:

`app_profile`, `categories`, `products`, `customers`, `transactions`, `transaction_items`, `debts`, `debt_payments`, `stock_movements`, dan `operational_costs`.

RLS aktif dengan policy `*_owner_all`, sehingga operasi data hanya diizinkan ketika:

```sql
owner_user_id = auth.uid()
```

Repository Supabase juga selalu memfilter query dengan `owner_user_id` milik user aktif.

---

## 3. Daftar Tabel Operasional

### 3.1 `app_profile`

Fungsi: menyimpan identitas toko milik user.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID profil toko |
| `store_name` | `text` | NOT NULL | Nama toko |
| `store_subtitle` | `text` | NOT NULL | Subjudul toko |
| `owner_name` | `text` | NULL | Nama pemilik toko |
| `photo_path` | `text` | NULL | Path lokal atau URL foto/logo |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

### 3.2 `categories`

Fungsi: master kategori produk.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID kategori |
| `name` | `text` | NOT NULL | Nama kategori |
| `description` | `text` | NULL | Deskripsi kategori |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

### 3.3 `products`

Fungsi: master produk untuk kasir, inventori, dan laporan.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID produk |
| `category_id` | `text` | NOT NULL, FK | Mengacu ke `categories.id` |
| `name` | `text` | NOT NULL | Nama produk |
| `sell_price` | `double precision` | NOT NULL | Harga jual |
| `cost_price` | `double precision` | NOT NULL | Harga modal |
| `stock_qty` | `integer` | NOT NULL default `0` | Stok saat ini |
| `min_stock` | `integer` | NOT NULL default `0` | Batas stok rendah |
| `unit` | `text` | NOT NULL | Satuan |
| `rack_location` | `text` | NULL | Lokasi rak |
| `image_path` | `text` | NULL | Path lokal atau URL gambar |
| `is_active` | `integer` | NOT NULL default `1`, check `0/1` | Status aktif |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

Relasi: `category_id -> categories.id` dengan `ON DELETE RESTRICT`.

### 3.4 `customers`

Fungsi: menyimpan pelanggan untuk transaksi dan BON.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID pelanggan |
| `name` | `text` | NOT NULL | Nama pelanggan |
| `phone` | `text` | NOT NULL | Nomor telepon |
| `address` | `text` | NOT NULL | Alamat |
| `notes` | `text` | NULL | Catatan |
| `is_active` | `integer` | NOT NULL default `1`, check `0/1` | Status aktif |
| `created_at` | `text` | NOT NULL | Timestamp ISO8601 |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

### 3.5 `transactions`

Fungsi: header transaksi kasir.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID transaksi |
| `transaction_code` | `text` | NOT NULL UNIQUE | Kode transaksi |
| `customer_id` | `text` | NULL, FK | Referensi pelanggan |
| `customer_name` | `text` | NOT NULL | Snapshot nama pelanggan |
| `total_amount` | `double precision` | NOT NULL | Total transaksi |
| `payment_method` | `text` | NOT NULL, check enum | `cash`, `qris`, `transfer`, `card`, `bon` |
| `amount_paid` | `double precision` | NOT NULL default `0` | Dibayar saat transaksi |
| `change_amount` | `double precision` | NOT NULL default `0` | Kembalian |
| `notes` | `text` | NULL | Catatan |
| `created_at` | `text` | NOT NULL | Timestamp ISO8601 |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

Relasi: `customer_id -> customers.id` dengan `ON DELETE SET NULL`.

### 3.6 `transaction_items`

Fungsi: detail item pada transaksi.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `bigint` | identity PK | Primary key item |
| `transaction_id` | `text` | NOT NULL, FK | Referensi transaksi |
| `product_id` | `text` | NOT NULL, FK | Referensi produk |
| `product_name` | `text` | NOT NULL | Snapshot nama produk |
| `quantity` | `integer` | NOT NULL, check `> 0` | Jumlah item |
| `sell_price` | `double precision` | NOT NULL | Harga saat transaksi |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

Relasi:

- `transaction_id -> transactions.id` dengan `ON DELETE CASCADE`.
- `product_id -> products.id` dengan `ON DELETE RESTRICT`.

### 3.7 `debts`

Fungsi: menyimpan BON/piutang yang berasal dari transaksi metode `bon`.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID BON |
| `transaction_id` | `text` | NOT NULL UNIQUE, FK | Transaksi sumber |
| `customer_id` | `text` | NOT NULL, FK | Pelanggan yang berutang |
| `customer_name` | `text` | NOT NULL | Snapshot nama pelanggan |
| `original_amount` | `double precision` | NOT NULL | Nilai awal utang |
| `paid_amount` | `double precision` | NOT NULL default `0` | Total sudah dibayar |
| `due_date` | `text` | NULL | Tanggal jatuh tempo |
| `notes` | `text` | NULL | Catatan |
| `created_at` | `text` | NOT NULL | Timestamp dibuat |
| `updated_at` | `text` | NOT NULL | Timestamp update |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

Relasi:

- `transaction_id -> transactions.id` dengan `ON DELETE CASCADE`.
- `customer_id -> customers.id` dengan `ON DELETE RESTRICT`.

Status BON dihitung di aplikasi dari `original_amount` dan `paid_amount`, bukan dari kolom `status`.

### 3.8 `debt_payments`

Fungsi: histori cicilan atau pelunasan BON.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID pembayaran |
| `debt_id` | `text` | NOT NULL, FK | BON yang dibayar |
| `customer_id` | `text` | NOT NULL, FK | Pelanggan pembayar |
| `amount` | `double precision` | NOT NULL, check `> 0` | Nominal pembayaran |
| `payment_method` | `text` | NOT NULL, check enum | `cash`, `qris`, `transfer`, `card`, `bon` |
| `notes` | `text` | NULL | Catatan |
| `paid_at` | `text` | NOT NULL | Timestamp pembayaran |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

Relasi:

- `debt_id -> debts.id` dengan `ON DELETE CASCADE`.
- `customer_id -> customers.id` dengan `ON DELETE RESTRICT`.

### 3.9 `stock_movements`

Fungsi: histori pergerakan stok produk.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID pergerakan stok |
| `product_id` | `text` | NULL, FK | Produk terkait |
| `reference_name` | `text` | NOT NULL | Nama referensi |
| `quantity` | `double precision` | NOT NULL | Jumlah pergerakan |
| `type` | `text` | NOT NULL, check enum | `stockIn`, `stockOut` |
| `notes` | `text` | NULL | Catatan |
| `created_at` | `text` | NOT NULL | Timestamp |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

Relasi: `product_id -> products.id` dengan `ON DELETE SET NULL`.

### 3.10 `operational_costs`

Fungsi: menyimpan biaya operasional untuk laporan dan perhitungan laba bersih.

| Field | Tipe | Constraint / Default | Keterangan |
|---|---|---|---|
| `id` | `text` | PK | ID biaya |
| `month_year` | `text` | NOT NULL | Periode bulan ISO8601 |
| `cost_name` | `text` | NOT NULL | Nama biaya |
| `amount` | `double precision` | NOT NULL | Nominal biaya |
| `owner_user_id` | `uuid` | FK ke `auth.users(id)` | Pemilik data |

---

## 4. Relasi Antar Tabel

| Relasi | Kardinalitas | Foreign key | Aksi `ON DELETE` |
|---|---|---|---|
| `auth.users -> profiles` | `1..1` | `profiles.id` | `CASCADE` |
| `auth.users -> tabel operasional` | `1..*` | `owner_user_id` | `CASCADE` |
| `categories -> products` | `1..*` | `products.category_id` | `RESTRICT` |
| `customers -> transactions` | `1..*` | `transactions.customer_id` | `SET NULL` |
| `transactions -> transaction_items` | `1..*` | `transaction_items.transaction_id` | `CASCADE` |
| `products -> transaction_items` | `1..*` | `transaction_items.product_id` | `RESTRICT` |
| `transactions -> debts` | `1..1` | `debts.transaction_id` | `CASCADE` |
| `customers -> debts` | `1..*` | `debts.customer_id` | `RESTRICT` |
| `debts -> debt_payments` | `1..*` | `debt_payments.debt_id` | `CASCADE` |
| `customers -> debt_payments` | `1..*` | `debt_payments.customer_id` | `RESTRICT` |
| `products -> stock_movements` | `1..*` | `stock_movements.product_id` | `SET NULL` |

---

## 5. Indeks

Schema aktif membuat indeks berikut:

| Nama indeks | Tabel | Kolom |
|---|---|---|
| `idx_transactions_created_at` | `transactions` | `created_at` |
| `idx_transactions_customer_id` | `transactions` | `customer_id` |
| `idx_transaction_items_transaction_id` | `transaction_items` | `transaction_id` |
| `idx_debts_customer_id` | `debts` | `customer_id` |
| `idx_debts_updated_at` | `debts` | `updated_at` |
| `idx_debt_payments_debt_id` | `debt_payments` | `debt_id` |
| `idx_stock_movements_product_created_at` | `stock_movements` | `product_id`, `created_at` |
| `idx_*_owner_user_id` | Semua tabel operasional | `owner_user_id` |

---

## 6. Catatan Implementasi

- Backend aktif adalah Supabase PostgreSQL.
- SQLite lama masih ada di kode sebagai repository alternatif/testing, tetapi bukan jalur data utama aplikasi.
- Field tanggal dan waktu masih disimpan sebagai `text` ISO8601 untuk kompatibilitas migrasi.
- Nilai enum `payment_method`: `cash`, `qris`, `transfer`, `card`, `bon`.
- Nilai enum `stock_movements.type`: `stockIn`, `stockOut`.
- Field boolean lama disimpan sebagai integer `1`/`0`.
- `transactions.customer_name` dan `transaction_items.product_name` disimpan sebagai snapshot.
- Tabel `raw_materials` tidak ada pada schema Supabase aktif.
- Upload media ke Supabase Storage belum diimplementasikan; field media masih berupa path lokal atau URL.

---

## 7. Kesimpulan Singkat

Schema Warung Kopi POS sekarang berjalan di Supabase PostgreSQL dengan Supabase Auth, ownership per user, dan RLS. Struktur tabel tetap mengikuti model POS yang sudah ada: profil toko, kategori, produk, pelanggan, transaksi, BON, pembayaran BON, stok, dan biaya operasional.
