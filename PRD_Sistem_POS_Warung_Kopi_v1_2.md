# PRD – Sistem POS Warung Kopi | ngodingpakeai | v1.2

## PRODUCT REQUIREMENTS DOCUMENT
### Sistem Point of Sale (POS)
**Warung Kopi Sederhana – Pertigaan Jati**

| Atribut | Detail |
|---|---|
| **Versi Dokumen** | 1.2 – Penambahan Fitur Pelanggan & Bon/Utang |
| **Tanggal** | 19 April 2026 |
| **Klien** | Warung Kopi – Pertigaan Jati |
| **Frontend** | Flutter (Android & iOS) |
| **Backend & Database** | Supabase BaaS (PostgreSQL) |
| **Deployment** | Fly.io |
| **Perubahan v1.2** | + Tabel Pelanggan, + Sistem Bon/Utang, + Wajib nama di transaksi |
| **Dibuat oleh** | ngodingpakeai |

---

## 1. Ringkasan Eksekutif

Dokumen ini merupakan Product Requirements Document (PRD) versi 1.2 yang memperbarui spesifikasi Sistem POS Warung Kopi dengan menambahkan dua fitur utama: (1) Manajemen Data Pelanggan dan (2) Sistem Pencatatan Bon/Utang. Kedua fitur ini merespons kebutuhan nyata di lapangan di mana warung kopi sering melayani pelanggan tetap yang terkadang membeli secara bon (kredit) dan membayar belakangan.

Dengan adanya fitur ini, setiap transaksi diwajibkan memilih nama pelanggan (atau *'Umum'* untuk pembeli biasa) sehingga riwayat transaksi per pelanggan dapat dilacak. Bon/utang yang belum dibayar akan tampil di dashboard dengan indikator usia utang untuk membantu penjual menagih tepat waktu.

---

## 2. Ringkasan Perubahan Versi 1.2

| No | Area | Perubahan | Dampak |
|---|---|---|---|
| 1 | **Tabel Master Baru** | Penambahan tabel `customers` (data pelanggan) | Riwayat pembelian & bon per pelanggan dapat dilacak |
| 2 | **Tabel Transaksi Baru** | Penambahan tabel `debts` (bon/utang) dan `debt_payments` (cicilan pembayaran) | Utang tercatat, dapat dicicil, dan ada riwayat pelunasan |
| 3 | **Update: transactions** | Kolom `customer_id` (FK) dan `payment_type` ditambahkan; 'BON' jadi metode pembayaran baru | Setiap transaksi terikat ke pelanggan, transaksi BON otomatis buat record utang |
| 4 | **Fitur Kasir** | Wajib pilih/input nama pelanggan sebelum selesaikan transaksi | Pelanggan baru bisa didaftarkan langsung dari halaman kasir |
| 5 | **Dashboard** | Panel 'Bon Belum Lunas' ditambahkan dengan daftar pelanggan berutang | Penjual langsung tahu siapa yang belum bayar tanpa perlu cek manual |
| 6 | **Visualisasi Analitik** | Halaman baru: Manajemen Utang dengan donut chart usia utang | Visual distribusi usia utang membantu prioritas penagihan |

---

## 3. Fitur Manajemen Pelanggan

### 3.1 Daftar & Profil Pelanggan

Pelanggan dibagi menjadi dua tipe: **Pelanggan Terdaftar** (punya akun di sistem) dan **Pembeli Umum** (tidak terdaftar). Untuk transaksi biasa tanpa bon, penjual cukup memilih opsi *'Umum / Tanpa Nama'*. Untuk transaksi BON, pelanggan **WAJIB** terdaftar di sistem.

- Tambah pelanggan baru: nama, nomor telepon, alamat tempat tinggal, dan catatan opsional
- Cari pelanggan berdasarkan nama atau nomor telepon saat transaksi
- Profil pelanggan menampilkan: total pembelian, total utang aktif, riwayat transaksi, dan riwayat pembayaran utang
- Edit dan nonaktifkan data pelanggan (tidak dihapus untuk menjaga integritas data)

### 3.2 Integrasi dengan Kasir

- Di halaman kasir, setelah produk dipilih, muncul langkah *'Pilih Pelanggan'* sebelum konfirmasi pembayaran
- Opsi pelanggan: (a) Umum/Tanpa Nama, (b) Cari pelanggan terdaftar, (c) Daftarkan pelanggan baru
- Jika metode pembayaran dipilih **'BON'**, maka step *'Pilih Pelanggan'* wajib diisi dengan pelanggan terdaftar – tidak bisa 'Umum'
- Nama pelanggan yang dipilih tampil di ringkasan transaksi dan di struk PDF

---

## 4. Fitur Sistem Bon / Utang

### 4.1 Alur Transaksi BON

Ketika penjual memilih metode pembayaran 'BON', sistem akan:

| Step | Aktor | Aksi |
|---|---|---|
| 1 | Penjual | Pilih produk yang dibeli pelanggan seperti biasa |
| 2 | Penjual | Pilih metode pembayaran → pilih 'BON' |
| 3 | Sistem | Wajib memilih pelanggan terdaftar (tidak bisa Umum). Jika belum ada, daftarkan dulu. |
| 4 | Penjual | Konfirmasi transaksi BON → sistem simpan transaksi + buat record utang baru di tabel `debts` |
| 5 | Sistem | Stok produk berkurang seperti transaksi normal. Struk menampilkan keterangan *'BON – Belum Lunas'*. |
| 6 | Penjual | Utang tampil di dashboard panel 'Bon Belum Lunas' dan di profil pelanggan bersangkutan |

### 4.2 Pembayaran / Pelunasan Bon

- Penjual dapat membuka profil pelanggan atau panel *'Bon Belum Lunas'* di dashboard
- Pilih bon yang akan dibayar → input nominal pembayaran (lunas penuh atau cicilan)
- Sistem catat pembayaran di tabel `debt_payments` dengan timestamp
- Jika total pembayaran = total utang, status bon otomatis berubah menjadi **'LUNAS'**
- Riwayat semua pembayaran bon dapat dilihat di profil pelanggan

### 4.3 Dashboard Panel Bon

- Daftar pelanggan dengan utang aktif, diurutkan berdasarkan usia utang (terlama di atas)
- Indikator warna: 🔴 merah = > 14 hari, 🟡 kuning = 4–14 hari, 🟢 hijau = 0–3 hari
- Donut chart distribusi usia utang untuk gambaran portofolio bon secara cepat
- Total nominal utang aktif ditampilkan sebagai kartu KPI di bagian atas
- Tombol cepat *'Tandai Lunas'* untuk pelunasan sekaligus

---

## 5. Visualisasi Dashboard – Manajemen Bon/Utang

Berikut adalah mockup tampilan halaman Manajemen Bon/Utang yang akan diimplementasikan menggunakan Flutter dengan `fl_chart` untuk komponen visualisasi grafisnya.

> *Gambar 5.1 – Mockup halaman Manajemen Bon/Utang: KPI cards, daftar pelanggan berutang dengan indikator usia, dan donut chart distribusi usia utang*

Halaman ini dapat diakses dari menu utama atau dari panel Low Stock / Bon di dashboard. Warna indikator pada daftar pelanggan (garis kiri merah/kuning/hijau) memberikan sinyal visual cepat tanpa perlu membaca tanggal satu per satu.

### 5.1 Komponen Visual Dashboard Utama (Update)

> *Gambar 5.2 – Dashboard Utama: panel 'Bon Belum Lunas' di bagian kanan atas menampilkan 3 pelanggan teratas dengan utang aktif*

### 5.2 Chart Analitik Finansial

> *Gambar 5.3 – Bar Chart: Pendapatan (oranye), Modal (biru), Net Profit (hijau) per 6 bulan – pendapatan dari transaksi BON masuk ke kolom Pendapatan saat lunas*

> *Gambar 5.4 – Donut Chart komposisi biaya operasional bulanan*

> *Gambar 5.5 – Line Chart tren net profit 12 bulan*

---

## 6. Desain Database (Supabase PostgreSQL)

Pembaruan v1.2 menambahkan 2 tabel master baru (`customers`) dan 2 tabel transaksi baru (`debts`, `debt_payments`), serta mengubah tabel `transactions` dengan menambahkan kolom `customer_id` dan metode pembayaran 'BON'.

> **🆕 BARU v1.2** – Tabel dan kolom yang ditandai adalah penambahan di versi ini.

### 6.1 Tabel Master

#### 6.1.1 `customers` ← BARU

Menyimpan data pelanggan terdaftar warung. Satu pelanggan dapat memiliki banyak transaksi dan banyak utang aktif.

| Kolom | Tipe Data | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK, DEFAULT uuid_generate_v4() | Primary key pelanggan |
| `name` | varchar(100) | NOT NULL | Nama lengkap pelanggan |
| `phone` | varchar(20) | NULLABLE | Nomor WhatsApp / telepon |
| `address` | text | NULLABLE | Alamat tempat tinggal (misal: Jl. Mawar No.3, RT 02) |
| `notes` | text | NULLABLE | Catatan tambahan (misal: 'pelanggan setia sejak 2023') |
| `is_active` | boolean | DEFAULT true | Nonaktifkan tanpa hapus data |
| `created_at` | timestamptz | DEFAULT now() | Waktu pendaftaran pelanggan |
| `updated_at` | timestamptz | DEFAULT now() | Waktu data terakhir diubah |

#### 6.1.2 `products` (tidak berubah)

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key produk |
| `name` | varchar(100) | NOT NULL | Nama produk |
| `category_id` | uuid | FK → categories.id | Referensi kategori |
| `sell_price` | numeric(12,2) | NOT NULL | Harga jual |
| `cost_price` | numeric(12,2) | NOT NULL | Harga modal |
| `stock_qty` | integer | NOT NULL, DEFAULT 0 | Stok saat ini |
| `min_stock` | integer | NOT NULL, DEFAULT 5 | Batas minimum stok alert |
| `unit` | varchar(20) | NOT NULL | Satuan: pcs, bungkus, kg, liter |
| `rack_location` | varchar(50) | NULLABLE | Lokasi rak |
| `is_active` | boolean | DEFAULT true | Status aktif produk |
| `created_at` | timestamptz | DEFAULT now() | Waktu dibuat |

#### 6.1.3 `categories` (tidak berubah)

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key kategori |
| `name` | varchar(50) | NOT NULL, UNIQUE | Minuman, Makanan, Jajanan, Bahan Baku |
| `description` | text | NULLABLE | Deskripsi kategori |
| `created_at` | timestamptz | DEFAULT now() | Waktu dibuat |

#### 6.1.4 `raw_materials` (tidak berubah)

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key bahan baku |
| `name` | varchar(100) | NOT NULL | Nama bahan baku |
| `stock_qty` | numeric(10,2) | NOT NULL, DEFAULT 0 | Stok saat ini |
| `min_stock` | numeric(10,2) | NOT NULL, DEFAULT 1 | Batas minimum alert |
| `unit` | varchar(20) | NOT NULL | Satuan |
| `rack_location` | varchar(50) | NULLABLE | Lokasi rak |
| `batch_number` | varchar(50) | NULLABLE | Nomor batch pembelian terakhir |
| `last_purchase_price` | numeric(12,2) | NULLABLE | Harga beli terakhir |
| `created_at` | timestamptz | DEFAULT now() | Waktu dibuat |

### 6.2 Tabel Transaksi

#### 6.2.1 `transactions` ← UPDATE: tambah `customer_id` & metode BON

Tabel ini diperbarui dengan menambahkan kolom `customer_id` (FK ke `customers`) dan menambahkan nilai `'BON'` pada kolom `payment_method`.

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key transaksi |
| `transaction_code` | varchar(20) | NOT NULL, UNIQUE | TRX-YYYYMMDD-XXX |
| `customer_id` | uuid | FK → customers.id, NULLABLE | **BARU**: NULL = pembeli umum, berisi UUID = pelanggan terdaftar |
| `total_amount` | numeric(12,2) | NOT NULL | Total nilai transaksi |
| `payment_method` | varchar(20) | NOT NULL | **UPDATE**: Tunai / QRIS / Transfer / Kartu / BON |
| `amount_paid` | numeric(12,2) | DEFAULT 0 | 0 jika BON (belum bayar), terisi jika tunai/non-tunai |
| `change_amount` | numeric(12,2) | DEFAULT 0 | Kembalian (0 jika BON) |
| `notes` | text | NULLABLE | Catatan tambahan |
| `created_at` | timestamptz | DEFAULT now() | Waktu transaksi |

#### 6.2.2 `transaction_items` (tidak berubah)

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key item |
| `transaction_id` | uuid | FK → transactions.id | Referensi transaksi induk |
| `product_id` | uuid | FK → products.id | Produk yang dijual |
| `quantity` | integer | NOT NULL, > 0 | Jumlah item |
| `sell_price` | numeric(12,2) | NOT NULL | Harga saat transaksi (snapshot) |
| `subtotal` | numeric(12,2) | NOT NULL | quantity × sell_price |

#### 6.2.3 `debts` ← BARU

Setiap transaksi BON otomatis membuat satu record di tabel ini. Satu pelanggan bisa punya banyak record utang dari transaksi berbeda.

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK, DEFAULT uuid_generate_v4() | Primary key record utang |
| `transaction_id` | uuid | FK → transactions.id, NOT NULL | Transaksi asal yang menimbulkan utang |
| `customer_id` | uuid | FK → customers.id, NOT NULL | Pelanggan yang berutang |
| `original_amount` | numeric(12,2) | NOT NULL | Nominal utang awal (total transaksi BON) |
| `paid_amount` | numeric(12,2) | NOT NULL, DEFAULT 0 | Total yang sudah dibayar (akumulasi debt_payments) |
| `remaining_amount` | numeric(12,2) GENERATED | ALWAYS AS (original_amount - paid_amount) | Sisa utang (computed column) |
| `status` | varchar(10) | NOT NULL, DEFAULT 'UNPAID' | 'UNPAID' / 'PARTIAL' / 'PAID' |
| `due_date` | date | NULLABLE | Batas waktu pelunasan (opsional, diisi penjual) |
| `notes` | text | NULLABLE | Catatan khusus bon ini |
| `created_at` | timestamptz | DEFAULT now() | Waktu bon dibuat |
| `updated_at` | timestamptz | DEFAULT now() | Waktu status terakhir diperbarui |

#### 6.2.4 `debt_payments` ← BARU

Mencatat setiap cicilan atau pelunasan yang dilakukan pelanggan terhadap bon mereka. Mendukung pembayaran bertahap (cicilan).

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key pembayaran |
| `debt_id` | uuid | FK → debts.id, NOT NULL | Utang yang sedang dibayar |
| `customer_id` | uuid | FK → customers.id, NOT NULL | Pelanggan yang membayar (redundan untuk query cepat) |
| `amount` | numeric(12,2) | NOT NULL, > 0 | Nominal yang dibayarkan |
| `payment_method` | varchar(20) | NOT NULL | Metode bayar cicilan: Tunai / Transfer / QRIS |
| `notes` | text | NULLABLE | Keterangan tambahan |
| `paid_at` | timestamptz | DEFAULT now() | Waktu pembayaran dicatat |

#### 6.2.5 `stock_movements` (tidak berubah)

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key |
| `product_id` | uuid | FK NULLABLE | Produk (jika berlaku) |
| `raw_material_id` | uuid | FK NULLABLE | Bahan baku (jika berlaku) |
| `movement_type` | varchar(10) | NOT NULL | 'IN' atau 'OUT' |
| `quantity` | numeric(10,2) | NOT NULL | Jumlah pergerakan |
| `batch_number` | varchar(50) | NULLABLE | Nomor batch (stok masuk) |
| `reference_id` | uuid | NULLABLE | ID transaksi terkait |
| `created_at` | timestamptz | DEFAULT now() | Waktu pencatatan |

#### 6.2.6 `operational_costs` (tidak berubah)

| Kolom | Tipe | Constraint | Keterangan |
|---|---|---|---|
| `id` | uuid | PK | Primary key |
| `month_year` | date | NOT NULL | Format YYYY-MM-01 |
| `cost_name` | varchar(100) | NOT NULL | Listrik, Air, Gas, dll. |
| `amount` | numeric(12,2) | NOT NULL, >= 0 | Jumlah biaya (Rupiah) |
| `created_at` | timestamptz | DEFAULT now() | Waktu dibuat |

---

## 7. Relasi Antar Tabel (Entity Relationship)

Berikut adalah diagram relasi antar tabel dalam bentuk deskriptif. Relasi utama yang ditambahkan di v1.2 ditandai dengan **[BARU]**:

| Tabel Asal | | Tabel Tujuan | Keterangan Relasi |
|---|---|---|---|
| `transactions` | → | `customers` | **BARU**: 1 customer memiliki banyak transaksi |
| `transactions` | → | `transaction_items` | 1 transaksi memiliki banyak item |
| `transactions` | → | `debts` | **BARU**: 1 transaksi BON menghasilkan 1 debt record |
| `debts` | → | `debt_payments` | **BARU**: 1 debt bisa memiliki banyak pembayaran cicilan |
| `customers` | → | `debts` | **BARU**: 1 customer bisa memiliki banyak utang aktif |
| `transaction_items` | → | `products` | Banyak item merujuk ke 1 produk |
| `products` | → | `categories` | Banyak produk dalam 1 kategori |
| `stock_movements` | → | `products` / `raw_materials` | 1 gerakan stok merujuk ke 1 produk atau bahan baku |

---

## 8. User Stories (Tambahan v1.2)

| ID | Modul | User Story | Kriteria Penerimaan |
|---|---|---|---|
| **US-11** | Pelanggan | Sebagai penjual, saya ingin mendaftarkan pelanggan baru langsung dari halaman kasir | Form nama, telepon, alamat muncul; setelah simpan langsung terpilih di kasir |
| **US-12** | Kasir | Sebagai penjual, saya ingin memilih pelanggan terdaftar sebelum menyelesaikan transaksi | Step 'Pilih Pelanggan' wajib muncul; bisa cari by nama/telepon |
| **US-13** | Kasir | Sebagai penjual, saya ingin mencatat transaksi sebagai BON untuk pelanggan yang bayar nanti | Metode BON tersedia; stok berkurang; record utang terbuat otomatis |
| **US-14** | Utang | Sebagai penjual, saya ingin melihat daftar semua pelanggan yang masih punya utang aktif | Dashboard panel bon menampilkan nama, alamat, nominal, dan usia utang |
| **US-15** | Utang | Sebagai penjual, saya ingin mencatat pelunasan bon pelanggan baik penuh maupun cicilan | Input nominal; sisa utang ter-update; status berubah PAID jika lunas |
| **US-16** | Pelanggan | Sebagai penjual, saya ingin melihat riwayat lengkap pembelian dan bon satu pelanggan | Profil pelanggan menampilkan semua transaksi + riwayat utang |
| **US-17** | Laporan | Sebagai penjual, saya ingin laporan bulanan mencantumkan total piutang aktif | Laporan PDF bulanan ada bagian 'Total Bon Belum Lunas' |

---

## 9. Stack Teknologi Final

| Layer | Teknologi | Versi/Tier | Keterangan |
|---|---|---|---|
| **Frontend** | Flutter | Flutter 3.x (Dart) | Mobile Android & iOS dari satu codebase |
| **Backend** | Supabase BaaS | Free / Pro Tier | REST API, Realtime, Auth, Storage |
| **Database** | Supabase (PostgreSQL) | PostgreSQL 15+ | RLS untuk keamanan data per user |
| **Deployment** | Fly.io | Pay-as-you-go | Hosting API tambahan jika diperlukan |
| **Chart** | fl_chart | Flutter package | Bar, pie, line chart native performatif |
| **PDF** | pdf (Flutter) | v3.x | Struk & laporan PDF langsung di device |
| **Notifikasi** | WhatsApp Gateway | Fonnte / WA Cloud | Alert stok rendah ke WhatsApp penjual |

---

## 10. Roadmap Pengembangan (Update v1.2)

| Fase | Durasi | Deliverable | Status |
|---|---|---|---|
| **Fase 1 – MVP** | 3 Minggu | Setup Flutter + Supabase, Dashboard dasar, Kasir, Produk | Direncanakan |
| **Fase 2 – Pelanggan** | 1 Minggu | Tabel customers, pilih pelanggan di kasir, profil pelanggan | Direncanakan |
| **Fase 3 – Bon/Utang** | 1 Minggu | Tabel debts & debt_payments, metode BON, panel dashboard bon | Direncanakan |
| **Fase 4 – Stok** | 1 Minggu | Bahan baku, riwayat stok, batch number | Direncanakan |
| **Fase 5 – Laporan** | 2 Minggu | Laporan harian, bulanan, tahunan + export PDF + biaya ops | Direncanakan |
| **Fase 6 – Analitik** | 1 Minggu | Bar chart, donut chart, line chart, dashboard bon visual | Direncanakan |
| **Fase 7 – Deploy** | 1 Minggu | Deploy Fly.io, testing, WhatsApp alert, onboarding penjual | Direncanakan |

---

## 11. Glosarium

| Istilah | Definisi |
|---|---|
| **BON** | Metode pembayaran kredit/utang; pelanggan mengambil barang sekarang dan membayar di kemudian hari |
| **Pelanggan Terdaftar** | Pelanggan yang datanya tersimpan di tabel `customers`; wajib untuk transaksi BON |
| **Pembeli Umum** | Pembeli tanpa data terdaftar; hanya bisa bayar tunai/QRIS/Transfer/Kartu, tidak bisa BON |
| **debt** | Record utang yang terbuat otomatis setiap kali ada transaksi dengan metode BON |
| **debt_payment** | Record cicilan atau pelunasan utang; satu debt bisa punya banyak debt_payment |
| **remaining_amount** | Sisa utang yang belum dibayar = original_amount – paid_amount |
| **POS** | Point of Sale – sistem kasir untuk mencatat transaksi penjualan |
| **Flutter** | Framework UI Google untuk mobile Android & iOS dari satu codebase Dart |
| **Supabase** | Backend-as-a-Service: database PostgreSQL + auth + storage + realtime |
| **RLS** | Row Level Security – keamanan data level baris di PostgreSQL |
| **Net Profit** | Keuntungan bersih = Gross Profit – Biaya Operasional (tidak termasuk piutang BON yang belum lunas) |

---

*Dokumen versi 1.2 – Penambahan Fitur Pelanggan & Bon/Utang*

**ngodingpakeai · 19 April 2026**
