# Dokumentasi Arsitektur & Alur BradPOS

## 🚀 Tech Stack (Teknologi)
- **Frontend**: Flutter (Lintas Platform)
- **State Management**: Flutter BLoC (Event-driven)
- **Local Database**: SQFlite (SQLite untuk Flutter)
- **Cloud Database**: Supabase (PostgreSQL + Auth + Storage)
- **Dependency Injection**: GetIt (Service Locator)

---

## 📂 Struktur Proyek (Clean Architecture)

```text
lib/
├── core/                  # Design system, tema, helper database, service sinkronisasi
├── data/                  # Model API, implementasi database, sumber data
│   ├── data_sources/      # Provider Lokal (SQFlite) & Remote (Supabase)
│   ├── models/            # Objek yang bisa diserialisasi JSON/Map
│   └── repositories/      # Implementasi repositori domain
├── domain/                # Lapisan logika bisnis (Agnostik UI)
│   ├── entities/          # Objek bisnis murni
│   └── repositories/      # Definisi interface
├── presentation/          # Lapisan UI
│   ├── blocs/             # Komponen Logika Bisnis (Kontrol State)
│   ├── screens/           # Halaman penuh (Kasir, Inventaris, Pembayaran, dll.)
│   └── widgets/           # Komponen UI yang bisa dipakai ulang
└── injection_container.dart # Konfigurasi Dependency Injection
```

---

## 🔄 Alur Kerja Utama (Workflows)

### 1. Alur Data Offline-First
BradPOS mengutamakan operasi lokal agar kasir tetap bisa bekerja tanpa internet.

1.  **Aksi Pengguna**: Pengguna menambah produk atau memproses penjualan.
2.  **Simpan Lokal**: Data langsung disimpan ke **SQFlite** dengan `sync_status` (contoh: `'created'`).
3.  **Update UI**: BLoC memancarkan state baru berdasarkan data lokal. UI terasa instan.
4.  **Sinkronisasi Latar Belakang**: `SyncService` mendeteksi perubahan yang tertunda:
    - **Online**: Mengirim data lokal ke **Supabase** dan mengambil perubahan terbaru dari cloud.
    - **Offline**: Menunggu detak jantung (heartbeat) sinkronisasi berikutnya.
5.  **Selesai**: Setelah sinkron, `sync_status` diperbarui menjadi `'synced'`.

### 2. Mode Guest (Tamu) & Migrasi
Memungkinkan pengguna mencoba aplikasi tanpa akun.

-   **Akses Guest**: Menggunakan ID tetap `offline_guest`. Semua data disimpan di SQFlite lokal dengan ID ini.
-   **Migrasi ke Cloud**: Saat Guest masuk (Login) dengan Google:
    1.  Aplikasi mendapatkan `UUID` asli dari Supabase.
    2.  Fungsi `migrateOfflineData()` dijalankan di database lokal.
    3.  Semua baris dengan `owner_id = 'offline_guest'` diperbarui menjadi `UUID` baru.
    4.  `SyncService` dipicu untuk mengunggah data yang baru dipindahkan ke cloud.

### 3. Penanganan Gambar (Image Handling)
Dioptimalkan untuk menghemat kuota dan ketersediaan offline.

-   **Gambar Online**: Menggunakan `CachedNetworkImage`. Setelah diunduh, gambar disimpan di cache perangkat. Pemuatan berikutnya menggunakan 0 kuota.
-   **Gambar Lokal**: Gambar yang diambil dari galeri disalin ke direktori dokumen aplikasi. Path file disimpan di database.
-   **Fallback**: Jika gambar gagal dimuat atau path hilang, UI menampilkan fallback bersih dengan ikon generik dan inisial nama produk.

### 4. Alur Pembayaran
Didesain untuk kecepatan transaksi di kasir.

-   **Tunai (Cash)**: Input manual jumlah uang; aplikasi menghitung kembalian.
-   **QRIS**: Memilih QRIS otomatis mengisi `amountReceived` sesuai total belanja, melewati input manual.
-   **Transaksi**: Disimpan lokal sebagai entitas `Transaction`, lalu dikirim ke cloud untuk laporan.

### 5. Manajemen Profil & Autentikasi Role-Based
Memisahkan identitas bisnis dan identitas personal.

-   **Owner vs Karyawan**: 
    -   **Owner**: Mengelola profil bisnis (Nama Toko, Alamat, ID Toko) dan profil pribadi.
    -   **Karyawan**: Hanya mengelola profil pribadi. Login menggunakan `Shop ID` + Nama + PIN.
-   **Sinkronisasi Data Profil**:
    -   Aplikasi memprioritaskan tabel `profiles` lokal/remote daripada metadata OAuth (Google/Supabase).
    -   Mencegah data (seperti Nama Toko) kembali ke default Google saat refresh sesi.
    -   **Shop ID**: Dihasilkan otomatis saat pergantian nama toko untuk memastikan keunikan identitas login staf.

### 6. Sistem Struk (Receipt)
Komponen UI untuk bukti transaksi yang efisien.

-   **Dialog Struk**: Menampilkan rincian item, informasi kasir, tanggal, dan data pelanggan.
-   **Thermal Look**: Desain layout disesuaikan untuk kemudahan baca pada printer thermal (informasi ringkas, font kontras).
-   **Integrasi Hardware**: Menyediakan hook untuk trigger fungsi print ke perangkat keras (Bluetooth/USB).

---

## 🛠 Pemeliharaan (Maintenance)
- **Skema DB Lokal**: Dikelola di `lib/core/database/database_helper.dart` (Migrasi versi).
- **Skema DB Remote**: Dikelola di Supabase (SQL migrations).
- **Environment**: Konfigurasi di `lib/injection_container.dart`.
