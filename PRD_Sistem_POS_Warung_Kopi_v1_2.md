# PRD - Sistem POS Warung Kopi

## Product Requirements Document

**Sistem Point of Sale (POS)**  
**Warung Kopi Sederhana - Pertigaan Jati**

| Atribut | Detail |
|---|---|
| Versi Dokumen | 1.3 - Sinkronisasi dengan implementasi Supabase |
| Tanggal | 1 Mei 2026 |
| Klien | Warung Kopi - Pertigaan Jati |
| Frontend | Flutter |
| Backend | Supabase BaaS |
| Database | Supabase PostgreSQL |
| Auth | Supabase Auth |
| Status dokumen | Disesuaikan dengan sistem yang berjalan saat ini |

---

## 1. Ringkasan Eksekutif

Dokumen ini memperbarui PRD Sistem POS Warung Kopi agar sesuai dengan implementasi saat ini. Sistem tidak lagi diposisikan sebagai aplikasi lokal berbasis SQLite, melainkan aplikasi Flutter yang memakai Supabase untuk backend, autentikasi, database PostgreSQL, dan pembatasan data per pengguna melalui Row Level Security (RLS).

Fitur inti yang sudah menjadi bagian sistem adalah pengelolaan profil toko, produk, pelanggan, transaksi kasir, BON/piutang, pembayaran BON, stok, biaya operasional, laporan, analitik, serta auth pengguna.

---

## 2. Ringkasan Perubahan dari Dokumen Sebelumnya

| Area | Sebelumnya | Saat ini |
|---|---|---|
| Backend | Lokal / belum konsisten | Supabase BaaS |
| Database | SQLite lokal atau desain Supabase lama | Supabase PostgreSQL aktif |
| Auth | Belum dianggap flow aktif | Supabase Auth aktif |
| Ownership data | Belum jelas | `owner_user_id` per tabel operasional |
| Security | Belum spesifik | RLS aktif per user |
| Deployment | Fly.io disebut sebagai target utama | Tidak ada service Fly.io aktif di repo |
| Storage media | Belum final | Field media menyimpan path lokal atau URL; Supabase Storage belum aktif |
| PDF & WhatsApp | Disebut sebagai stack final | Belum menjadi implementasi aktif |
| Raw materials | Pernah disebut sebagai tabel | Tidak ada pada schema Supabase aktif |

---

## 3. Tujuan Produk

1. Membantu pemilik warung mencatat transaksi penjualan harian dengan cepat.
2. Mengelola katalog produk, harga, stok, dan kategori.
3. Mencatat pelanggan tetap beserta riwayat transaksi dan BON.
4. Mencatat pembayaran BON secara penuh atau cicilan.
5. Menyediakan dashboard, laporan, dan analitik sederhana untuk memantau penjualan, stok rendah, piutang, dan laba bersih.
6. Menyimpan data secara cloud melalui Supabase dengan isolasi data per akun.

---

## 4. Scope Implementasi Saat Ini

### In Scope

- Login, signup, verifikasi email, Google OAuth, dan sign out via Supabase Auth.
- Profil toko per user.
- CRUD produk dan kategori.
- CRUD pelanggan.
- Transaksi kasir dengan metode `cash`, `qris`, `transfer`, `card`, dan `bon`.
- Transaksi BON wajib memilih pelanggan.
- Pencatatan otomatis BON pada tabel `debts`.
- Pencatatan pembayaran BON pada tabel `debt_payments`.
- Pergerakan stok otomatis saat checkout.
- Biaya operasional.
- Dashboard, laporan ringkas, dan chart analitik via `fl_chart`.
- Database PostgreSQL Supabase dengan `owner_user_id` dan RLS.

### Out of Scope Saat Ini

- Backend custom di Fly.io.
- WhatsApp gateway atau notifikasi otomatis.
- Export PDF final untuk struk/laporan.
- Upload media ke Supabase Storage.
- Tabel bahan baku `raw_materials`.
- Realtime collaboration antar device.

---

## 5. User & Aktor

| Aktor | Deskripsi |
|---|---|
| Pemilik / Penjual | User utama yang login, mengelola toko, produk, pelanggan, transaksi, BON, dan laporan |
| Pembeli Umum | Pembeli tanpa data pelanggan terdaftar |
| Pelanggan Terdaftar | Pelanggan yang datanya tersimpan dan dapat melakukan transaksi BON |

---

## 6. Fitur Utama

### 6.1 Auth & Onboarding

Sistem memakai Supabase Auth.

Kebutuhan:

- User dapat membuat akun dengan email/password.
- User dapat login dengan email/password.
- User dapat login menggunakan Google OAuth.
- User dapat melakukan verifikasi email.
- User dapat logout.
- Aplikasi harus menampilkan flow onboarding/profil toko saat data toko belum lengkap.

### 6.2 Profil Toko

Profil toko disimpan pada tabel `app_profile` dan dimiliki oleh user aktif melalui `owner_user_id`.

Data:

- Nama toko.
- Subtitle/deskripsi toko.
- Nama pemilik.
- Foto/logo toko berupa path lokal atau URL.

### 6.3 Produk & Kategori

Produk digunakan untuk transaksi kasir dan inventori.

Data produk:

- Nama produk.
- Kategori.
- Harga jual.
- Harga modal.
- Stok saat ini.
- Minimum stok.
- Satuan.
- Lokasi rak.
- Gambar/path media.
- Status aktif.

### 6.4 Pelanggan

Pelanggan digunakan untuk transaksi yang perlu identitas pembeli, terutama BON.

Data pelanggan:

- Nama.
- Nomor telepon.
- Alamat.
- Catatan.
- Status aktif.

Kebutuhan:

- Penjual dapat menambah dan mengubah pelanggan.
- Pelanggan dapat dinonaktifkan tanpa menghapus histori.
- Profil pelanggan menampilkan riwayat transaksi, BON, dan pembayaran.

### 6.5 Transaksi Kasir

Kebutuhan:

- Penjual memilih produk ke keranjang.
- Sistem menjaga kuantitas tidak melebihi stok.
- Penjual dapat memilih pelanggan atau memakai pembeli umum.
- Penjual memilih metode pembayaran.
- Checkout membuat row `transactions` dan `transaction_items`.
- Stok produk berkurang dan dicatat di `stock_movements`.

Metode pembayaran aktif:

- `cash`
- `qris`
- `transfer`
- `card`
- `bon`

### 6.6 BON / Piutang

Ketika metode pembayaran `bon` dipilih:

1. Pelanggan terdaftar wajib dipilih.
2. Sistem membuat transaksi dengan `amount_paid = 0`.
3. Sistem membuat row `debts`.
4. Sisa utang dihitung dari `original_amount - paid_amount`.
5. BON tampil pada dashboard dan detail pelanggan.

Pembayaran BON:

- Penjual memilih BON.
- Penjual memasukkan nominal pembayaran.
- Sistem menyimpan row `debt_payments`.
- Sistem memperbarui `paid_amount` pada `debts`.
- Status BON dihitung aplikasi sebagai unpaid, partial, atau paid.

### 6.7 Inventori

Kebutuhan:

- Sistem menampilkan produk stok rendah.
- Setiap checkout mencatat `stock_movements` bertipe `stockOut`.
- Riwayat stok dapat dilihat per produk.

### 6.8 Laporan & Analitik

Kebutuhan:

- Ringkasan transaksi harian/bulanan/tahunan.
- Revenue dihitung dari transaksi non-BON yang sudah dibayar dan pembayaran BON.
- Piutang aktif ditampilkan terpisah.
- Biaya operasional mengurangi net profit.
- Chart menggunakan `fl_chart`.

---

## 7. Desain Database Aktif

Database aktif adalah Supabase PostgreSQL. Schema dan RLS berada di folder `supabase/migrations/`.

### 7.1 Tabel Auth

| Tabel | Fungsi |
|---|---|
| `auth.users` | Tabel user bawaan Supabase Auth |
| `profiles` | Profil tambahan user yang dibuat dari trigger auth |

### 7.2 Tabel Operasional

| Tabel | Fungsi |
|---|---|
| `app_profile` | Profil toko |
| `categories` | Master kategori |
| `products` | Master produk |
| `customers` | Master pelanggan |
| `transactions` | Header transaksi |
| `transaction_items` | Detail transaksi |
| `debts` | BON/piutang |
| `debt_payments` | Pembayaran BON |
| `stock_movements` | Histori stok |
| `operational_costs` | Biaya operasional |

Semua tabel operasional memiliki `owner_user_id` untuk membatasi data per akun.

### 7.3 Catatan Tipe Data

Untuk menjaga kompatibilitas dari migrasi lama:

- ID operasional masih memakai `text`.
- Timestamp masih disimpan sebagai `text` ISO8601.
- Enum masih disimpan sebagai `text`.
- Boolean lama masih memakai integer `0` / `1`.

Detail lengkap ada di `DOKUMENTASI_SKEMA_DATABASE.md`.

---

## 8. Relasi Utama

| Relasi | Keterangan |
|---|---|
| `auth.users -> profiles` | Satu user memiliki satu profil |
| `auth.users -> tabel operasional` | Satu user memiliki banyak data toko/POS |
| `categories -> products` | Satu kategori memiliki banyak produk |
| `customers -> transactions` | Satu pelanggan dapat memiliki banyak transaksi |
| `transactions -> transaction_items` | Satu transaksi memiliki banyak item |
| `transactions -> debts` | Satu transaksi BON menghasilkan satu BON |
| `debts -> debt_payments` | Satu BON dapat memiliki banyak pembayaran |
| `products -> stock_movements` | Satu produk dapat memiliki banyak histori stok |

---

## 9. Stack Teknologi Saat Ini

| Layer | Teknologi | Status |
|---|---|---|
| Frontend | Flutter | Aktif |
| Bahasa | Dart | Aktif |
| Backend | Supabase BaaS | Aktif |
| Database | Supabase PostgreSQL | Aktif |
| Auth | Supabase Auth | Aktif |
| Security | Supabase RLS + `owner_user_id` | Aktif |
| State Management | Riverpod | Aktif |
| Routing | GoRouter | Aktif |
| Chart | `fl_chart` | Aktif |
| Environment | `.env` / `--dart-define` via `flutter_dotenv` | Aktif |
| Media picker | `file_picker` | Aktif |
| OAuth browser | `url_launcher` | Aktif |
| SQLite | `sqflite`, `sqflite_common_ffi` | Legacy/testing, bukan backend aktif |
| PDF | `pdf` package | Belum ada di dependency aktif |
| WhatsApp Gateway | Fonnte / WA Cloud | Belum aktif |
| Fly.io | Custom API hosting | Belum aktif |
| Supabase Storage | File upload cloud | Belum aktif |

---

## 10. User Stories Utama

| ID | Modul | User Story | Kriteria Penerimaan |
|---|---|---|---|
| US-01 | Auth | Sebagai penjual, saya ingin login agar data toko saya aman | User bisa login dan hanya melihat datanya sendiri |
| US-02 | Profil Toko | Sebagai penjual, saya ingin mengatur profil toko | Profil tersimpan di `app_profile` milik user aktif |
| US-03 | Produk | Sebagai penjual, saya ingin mengelola produk | Produk dapat ditambah, diubah, dinonaktifkan/dihapus sesuai aturan |
| US-04 | Kasir | Sebagai penjual, saya ingin membuat transaksi | Checkout menyimpan transaksi, item, dan mengurangi stok |
| US-05 | Pelanggan | Sebagai penjual, saya ingin mendaftarkan pelanggan | Pelanggan tersimpan dan bisa dipilih saat kasir |
| US-06 | BON | Sebagai penjual, saya ingin mencatat transaksi sebagai BON | Metode `bon` membuat row `debts` dan wajib pelanggan |
| US-07 | Pembayaran BON | Sebagai penjual, saya ingin mencatat cicilan | Row `debt_payments` tersimpan dan `paid_amount` terupdate |
| US-08 | Inventori | Sebagai penjual, saya ingin melihat stok rendah | Produk dengan stok <= minimum tampil sebagai alert |
| US-09 | Laporan | Sebagai penjual, saya ingin melihat ringkasan keuangan | Revenue, biaya, piutang, dan net profit dapat dilihat |

---

## 11. Roadmap Realistis

| Fase | Fokus | Status |
|---|---|---|
| Fase 1 | Flutter UI, routing, dashboard, kasir dasar | Sudah ada |
| Fase 2 | Produk, pelanggan, BON, stok, laporan | Sudah ada |
| Fase 3 | Migrasi Supabase PostgreSQL | Sudah ada |
| Fase 4 | Supabase Auth, ownership, dan RLS | Sudah ada |
| Fase 5 | Hardening test & validasi multi-user | Berikutnya |
| Fase 6 | Supabase Storage untuk media produk/profil | Rencana |
| Fase 7 | Export PDF struk/laporan | Rencana |
| Fase 8 | Notifikasi WhatsApp stok rendah / penagihan BON | Rencana |

---

## 12. Glosarium

| Istilah | Definisi |
|---|---|
| BON | Metode pembayaran kredit/utang |
| Pelanggan Terdaftar | Pelanggan yang tersimpan di tabel `customers` |
| Pembeli Umum | Pembeli tanpa data pelanggan |
| RLS | Row Level Security di PostgreSQL/Supabase |
| `owner_user_id` | Kolom pemilik data yang mengarah ke `auth.users.id` |
| Supabase | Backend-as-a-Service untuk auth, database PostgreSQL, API, dan fitur backend lain |
| POS | Point of Sale, sistem kasir untuk transaksi penjualan |
| Net Profit | Keuntungan bersih setelah biaya operasional |
