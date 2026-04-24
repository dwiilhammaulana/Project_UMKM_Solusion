# ☕ Warung Kopi POS

Aplikasi **Point of Sale (POS)** berbasis Flutter untuk warung kopi, dirancang untuk mempermudah transaksi, manajemen stok, serta pengelolaan hutang (BON).

---

## 🚀 Fitur Utama

- Transaksi penjualan (cash, QRIS, transfer, card)
- Sistem hutang (BON)
- Manajemen produk & kategori
- Manajemen pelanggan
- Tracking stok (stock in / stock out)
- Laporan transaksi & pendapatan
- Dashboard ringkasan bisnis

---

## 🧰 Teknologi

- Flutter
- SQLite (local database)
- Dart

---

## ▶️ Menjalankan Project

```bash
flutter pub get
flutter run
```

Database akan otomatis dibuat saat pertama kali menjalankan aplikasi:

```
warung_kopi_pos.db
```

---

## 📦 Build APK

```bash
flutter build apk --debug
```

Output:

```
build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📁 Struktur Folder

```
lib/
  app/        -> konfigurasi utama & routing
  features/   -> fitur utama (transaksi, produk, dll)
  shared/     -> database, model, state, widget

test/         -> testing
android/      -> konfigurasi android
```

---

## 🗄️ Database

Menggunakan SQLite dengan tabel utama:

- categories
- products
- customers
- transactions
- transaction_items
- debts
- debt_payments
- stock_movements
- operational_costs

---

## 🔗 Relasi Utama

- categories → products  
- customers → transactions  
- transactions → transaction_items  
- products → transaction_items  
- transactions → debts  
- debts → debt_payments  
- products → stock_movements  

---

## 📊 ERD (Entity Relationship Diagram)

```mermaid
erDiagram

    categories ||--o{ products : has

    customers ||--o{ transactions : makes
    transactions ||--o{ transaction_items : contains
    products ||--o{ transaction_items : included_in

    transactions ||--o{ debts : creates
    debts ||--o{ debt_payments : paid_by

    products ||--o{ stock_movements : tracked_in

    categories {
        TEXT id PK
        TEXT name
        TEXT description
    }

    products {
        TEXT id PK
        TEXT category_id FK
        TEXT name
        REAL sell_price
        REAL cost_price
        INTEGER stock_qty
        INTEGER min_stock
        TEXT unit
        TEXT rack_location
        INTEGER is_active
    }

    customers {
        TEXT id PK
        TEXT name
        TEXT phone
        TEXT address
        TEXT notes
        INTEGER is_active
        TEXT created_at
    }

    transactions {
        TEXT id PK
        TEXT transaction_code
        TEXT customer_id FK
        TEXT customer_name
        REAL total_amount
        TEXT payment_method
        REAL amount_paid
        REAL change_amount
        TEXT notes
        TEXT created_at
    }

    transaction_items {
        INTEGER id PK
        TEXT transaction_id FK
        TEXT product_id FK
        TEXT product_name
        INTEGER quantity
        REAL sell_price
    }

    debts {
        TEXT id PK
        TEXT transaction_id FK
        TEXT customer_id FK
        TEXT customer_name
        REAL original_amount
        REAL paid_amount
        TEXT due_date
        TEXT notes
        TEXT created_at
        TEXT updated_at
    }

    debt_payments {
        TEXT id PK
        TEXT debt_id FK
        TEXT customer_id FK
        REAL amount
        TEXT payment_method
        TEXT notes
        TEXT paid_at
    }

    stock_movements {
        TEXT id PK
        TEXT product_id FK
        TEXT reference_name
        REAL quantity
        TEXT type
        TEXT notes
        TEXT created_at
    }

    operational_costs {
        TEXT id PK
        TEXT month_year
        TEXT cost_name
        REAL amount
    }
```

---

## 🔄 UX Flow (User Flow POS)

### Alur Utama

```
Login → Dashboard → Pilih Produk → Keranjang → Checkout → Pembayaran → Selesai
```

---

### Transaksi Normal

1. Pilih produk  
2. Masukkan ke keranjang  
3. Checkout  
4. Pilih metode pembayaran  
5. Input jumlah bayar  
6. Transaksi selesai  
7. Cetak struk  

✔ Stok berkurang  
✔ Tidak masuk hutang  

---

### Transaksi BON (Hutang)

1. Pilih produk  
2. Checkout  
3. Pilih pelanggan (WAJIB)  
4. Pilih metode = BON  
5. Simpan transaksi  

✔ Stok berkurang  
✔ Data masuk ke `debts`  

---

### Pembayaran Hutang

1. Pilih data hutang  
2. Input pembayaran  
3. Simpan ke `debt_payments`  
4. Update status:
   - unpaid
   - partial
   - paid

---

### Dashboard & Laporan

- Pendapatan harian  
- Jumlah transaksi  
- Hutang aktif  
- Stok menipis  

---

## ⚡ Enum

**payment_method:**
- cash
- qris
- transfer
- card
- bon

**stock_movements.type:**
- stockIn
- stockOut

---

## 🛠️ Perintah Penting

```bash
flutter analyze
flutter test
flutter build apk --debug
```

---

## 📌 Catatan

- Transaksi normal langsung lunas  
- Transaksi BON akan membuat data hutang  
- Semua transaksi mempengaruhi stok & laporan  

---

## 📈 Pengembangan Selanjutnya

- Login multi user (admin / kasir)  
- Integrasi cloud database  
- Export laporan (PDF / Excel)  
- Integrasi printer thermal  