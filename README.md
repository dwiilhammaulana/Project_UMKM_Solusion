# Warung Kopi POS

Aplikasi Point of Sale (POS) berbasis Flutter untuk warung kopi. Sistem saat ini sudah memakai Supabase sebagai backend utama untuk autentikasi, database PostgreSQL, dan isolasi data per pengguna melalui Row Level Security (RLS).

---

## Gambaran Singkat

| Komponen | Teknologi |
|---|---|
| Platform | Flutter, Android-first |
| Bahasa | Dart |
| Backend | Supabase BaaS |
| Database | Supabase PostgreSQL |
| Auth | Supabase Auth, email/password dan Google OAuth |
| Keamanan data | `owner_user_id` + RLS per user |
| State Management | Riverpod |
| Routing | GoRouter |
| UI | Material 3 + custom widget internal |

---

## Stack & Teknologi

### Framework

- **Flutter** dengan **Dart SDK `^3.5.0`**
- Target utama: Android, dengan struktur Flutter yang tetap dapat dikembangkan untuk platform lain.

### Backend & Database

- **Supabase Flutter** (`supabase_flutter`) sebagai client backend.
- **Supabase Auth** untuk login, signup, verifikasi email, Google OAuth, dan session.
- **Supabase PostgreSQL** sebagai database utama.
- **RLS** aktif pada tabel operasional agar data hanya dapat diakses oleh pemiliknya.
- File migration Supabase berada di `supabase/migrations/`.

### UI & Design System

- Material 3 bawaan Flutter.
- Theme kustom: `lib/shared/theme/app_theme.dart`.
- Widget reusable: `lib/shared/widgets/common_widgets.dart`.
- Shell & navigasi: `lib/shared/widgets/app_shell.dart`.
- Form sheet kustom: customer, produk, profil toko, dan biaya operasional.

Project ini tidak memakai Tailwind, Bootstrap, atau framework web UI lain. Seluruh tampilan dibangun dengan widget Flutter dan styling kustom internal.

### Font

| Font | Digunakan untuk |
|---|---|
| `Sora` | Heading |
| `Manrope` | Body text |

Keduanya di-load via package `google_fonts`.

---

## Dependencies Penting

| Package | Fungsi |
|---|---|
| `supabase_flutter` | Client Supabase, Auth, dan akses database |
| `flutter_dotenv` | Membaca `SUPABASE_URL` dan `SUPABASE_ANON_KEY` dari `.env` |
| `flutter_riverpod` | State management |
| `go_router` | Routing & nested route |
| `google_fonts` | Load font Sora & Manrope |
| `intl` | Format tanggal, waktu, dan mata uang Indonesia |
| `flutter_localizations` | Dukungan locale `id_ID` |
| `fl_chart` | Chart pada analitik & laporan BON |
| `file_picker` | Ambil file gambar dari perangkat |
| `url_launcher` | Membuka flow OAuth eksternal |
| `sqflite`, `sqflite_common_ffi`, `path` | Sisa dukungan repository SQLite lokal/testing; bukan backend aktif aplikasi |

---

## Konfigurasi Environment

Aplikasi membutuhkan konfigurasi Supabase sebelum dijalankan.

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
```

Konfigurasi dapat diberikan lewat:

- file `.env` yang dibuat dari `.env.example`, atau
- `--dart-define=SUPABASE_URL=...` dan `--dart-define=SUPABASE_ANON_KEY=...`.

File kunci:

| File | Peran |
|---|---|
| `lib/main.dart` | Inisialisasi Flutter, locale Indonesia, dan Supabase |
| `lib/shared/config/app_environment.dart` | Membaca dan memvalidasi environment Supabase |
| `lib/shared/supabase/supabase_providers.dart` | Provider `SupabaseClient` |
| `lib/shared/auth/auth_repository.dart` | Login, signup, Google OAuth, resend verification, sign out |
| `lib/shared/database/supabase_pos_repository.dart` | Repository data POS berbasis Supabase |
| `supabase/migrations/` | Schema, ownership, dan RLS Supabase |

---

## Database & Penyimpanan

- **Engine aktif:** Supabase PostgreSQL.
- **Repository aktif:** `lib/shared/database/supabase_pos_repository.dart`.
- **Interface repository:** `lib/shared/database/pos_repository.dart`.
- **Provider aktif:** `posRepositoryProvider` di `lib/shared/state/app_state.dart`.
- **Dokumentasi schema lengkap:** `DOKUMENTASI_SKEMA_DATABASE.md`.

### Tabel Utama

| Tabel | Keterangan |
|---|---|
| `profiles` | Profil akun Supabase Auth |
| `app_profile` | Identitas & profil toko per user |
| `categories` | Kategori produk |
| `products` | Data produk, harga, stok, dan gambar |
| `customers` | Data pelanggan |
| `transactions` | Header transaksi |
| `transaction_items` | Detail item per transaksi |
| `debts` | BON / piutang |
| `debt_payments` | Cicilan & pelunasan BON |
| `stock_movements` | Histori pergerakan stok |
| `operational_costs` | Biaya operasional per periode |

### Alur Data

```text
UI -> PosAppState -> PosRepository -> SupabasePosRepository -> Supabase PostgreSQL
```

SQLite masih ada sebagai implementasi repository lama/testing (`SqlitePosRepository` dan `AppDatabase`), tetapi aplikasi berjalan normal memakai `SupabasePosRepository`.

---

## Arsitektur & Routing

### Struktur Folder

```text
lib/
  app/          # Bootstrap & routing
  features/     # Modul fitur utama
  shared/       # Theme, state, model, auth, database, supabase, widget, utils

supabase/
  migrations/   # Migration SQL Supabase

test/           # Widget test & repository/test support
android/        # Konfigurasi Android
```

### Modul Fitur (`lib/features/`)

`auth` - `onboarding` - `dashboard` - `cashier` - `products` - `customers` - `debts` - `inventory` - `reports` - `analytics` - `more`

### File Kunci

| File | Peran |
|---|---|
| `lib/main.dart` | Entry point dan inisialisasi Supabase |
| `lib/app/app.dart` | Bootstrap aplikasi |
| `lib/app/routing/app_router.dart` | Konfigurasi routing dan gate auth |
| `lib/shared/widgets/app_shell.dart` | Shell & bottom navigation |

---

## Fitur Utama

### Auth & Onboarding

- Login email/password.
- Signup email/password dengan verifikasi email.
- Login Google OAuth.
- Session dan auth state memakai Supabase Auth.
- Profil toko disimpan per user.

### Transaksi & Kasir

- Tab **Transaksi Baru** dan **Riwayat Transaksi** di modul Kasir.
- Detail transaksi via route `/cashier/transactions/:transactionId`.
- Metrik per transaksi: total qty produk & jumlah jenis item.
- Data disimpan di tabel `transactions` dan `transaction_items`.

### BON (Piutang)

- Dibuat otomatis saat checkout dengan metode `bon`.
- Transaksi BON wajib memilih pelanggan terdaftar.
- Mendukung cicilan dan pelunasan bertahap via `debt_payments`.
- Tracking per pelanggan.

### Stok & Inventori

- Pergerakan stok otomatis tercatat ke `stock_movements` saat checkout.
- Histori stok bisa ditelusuri per produk.

### Laporan & Analitik

- Chart dibuat dengan `fl_chart`.
- Laporan ringkas: harian, bulanan, tahunan.
- Kalkulasi net profit menggunakan data `operational_costs`.
- Pembayaran BON masuk ke revenue saat pembayaran dicatat.

### Gambar & Media

- Picker: `lib/shared/utils/media_picker.dart` via `file_picker`.
- Render: widget `AppMediaPreview`.
- Saat ini menyimpan path lokal atau URL remote (`http://` / `https://`) pada field `photo_path` / `image_path`.
- Supabase Storage belum menjadi bagian implementasi aktif untuk upload media.

---

## Menjalankan Project

```bash
flutter pub get
flutter run
```

Jika tidak memakai `.env`, jalankan dengan `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key
```

### Perintah Lain

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Output APK: `build/app/outputs/flutter-apk/app-debug.apk`

---

## Catatan Implementasi

- Locale aplikasi: Indonesia (`id_ID`).
- Format mata uang: Rp.
- Backend aktif sudah cloud via Supabase, bukan lagi SQLite lokal.
- Setiap tabel operasional memakai `owner_user_id` untuk membatasi data per akun.
- Migration Supabase terakhir memperbaiki ownership dan RLS agar aman dipakai multi-user.
- Fitur PDF final, WhatsApp gateway, Fly.io service tambahan, dan Supabase Storage belum menjadi implementasi aktif di repo ini.
