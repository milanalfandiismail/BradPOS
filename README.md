# BradPOS — Point of Sale Offline-First

**BradPOS** adalah sistem **Point of Sale (POS)** berbasis **Flutter** yang dirancang untuk operasi **offline-first**. Cocok untuk UMKM, toko retail, dan kasir yang butuh sistem tetap jalan walau tanpa internet — data tetap aman di SQLite lokal dan otomatis sinkron ke **Supabase** cloud saat online.

Dibangun dengan **Clean Architecture** (3-layer), **BLoC** untuk state management, dan **GetIt** untuk dependency injection.

---

## Daftar Isi

- [Fitur Utama](#fitur-utama)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Architecture](#architecture)
- [Environment Variables](#environment-variables)
- [Available Scripts](#available-scripts)
- [Testing](#testing)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

---

## Fitur Utama

- **Offline-First** — Semua operasi (tambah produk, transaksi, kelola stok) tetap jalan tanpa internet. Data disimpan di SQLite lokal.
- **Sinkronisasi Otomatis** — Saat online, `SyncService` secara otomatis push data lokal ke Supabase dan pull perubahan dari cloud.
- **Dua Mode Login:**
  - **Owner** — Login via Supabase Auth (email/password atau Google OAuth)
  - **Karyawan** — Login via Shop ID + Nama + PIN (kustom, tanpa email)
  - **Guest** — Mode offline tanpa akun, data bisa dimigrasi saat login nanti
- **Role-Based Access** — Owner punya akses penuh; Karyawan akses terbatas.
- **Manajemen Inventaris** — CRUD produk, kategori, barcode, upload gambar, stok unlimited (-1).
- **Kasir Cepat** — Keranjang, numpad, metode bayar (Tunai/QRIS), hitung kembalian otomatis.
- **Riwayat Transaksi** — Filter tanggal, detail per transaksi.
- **Dashboard Statistik** — Total penjualan, grafik harian, notifikasi stok menipis.
- **Cetak Struk (Under Development)** — Printer thermal Bluetooth/USB.
- **Cross-Platform** — Android, iOS, Web, Windows, macOS, Linux.

---

## Tech Stack

| Kategori | Teknologi |
|----------|-----------|
| **Bahasa** | Dart 3.11+ |
| **Framework** | Flutter (Material 3) |
| **State Management** | flutter_bloc 9.x |
| **Arsitektur** | Clean Architecture (Domain → Data → Presentation) |
| **DI** | get_it 9.x (Service Locator) |
| **Database Lokal** | sqflite 2.x (SQLite), sqflite_common_ffi_web (untuk Web) |
| **Database Cloud** | Supabase (PostgreSQL + Auth + Storage) |
| **Autentikasi** | supabase_flutter + google_sign_in |
| **Hash Password** | crypto (SHA-256) |
| **Functional Error** | dartz (Either) |
| **Value Equality** | equatable |
| **Gambar** | image_picker, cached_network_image |
| **Cetak (Under Development)** | flutter_pos_printer_platform_image_3, esc_pos_utils_plus |
| **Animasi** | smooth_transition |
| **Format Tanggal** | intl (locale `id_ID`) |
| **UUID** | uuid |

---

## Prerequisites

Sebelum mulai, pastikan sudah terinstall:

| Tool | Versi Minimum | Catatan |
|------|---------------|---------|
| **Flutter** | 3.27+ | `flutter --version` untuk cek |
| **Dart** | 3.11+ | Ikut Flutter SDK |
| **Git** | - | Untuk clone repo |
| **IDE** | - | VS Code / Android Studio / IntelliJ |
| **Akun Supabase** | - | Gratis di [supabase.com](https://supabase.com) |
| **Opsional: Docker** | - | Jika ingin jalankan PostgreSQL lokal |

---

## Getting Started

### 1. Clone Repository

```bash
git clone https://github.com/milanalfandiismail/BradPOS.git
cd BradPOS
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Environment Variables

Salin file `.env.example` (atau buat `.env` baru):

```bash
copy .env.example .env
# atau
cp .env.example .env
```

Isi dengan data Supabase kamu:

```env
# .env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIs...
GOOGLE_WEB_CLIENT_ID=123456789-xxxxx.apps.googleusercontent.com
```

| Variable | Wajib | Cara Dapat |
|----------|-------|------------|
| `SUPABASE_URL` | Ya | Dashboard Supabase → Settings → API → Project URL |
| `SUPABASE_ANON_KEY` | Ya | Dashboard Supabase → Settings → API → anon/public key |
| `GOOGLE_WEB_CLIENT_ID` | Web OAuth | Google Cloud Console → Credentials → OAuth 2.0 Client ID |

### 4. Setup Database Supabase (Cloud)

1. Buka [Supabase Dashboard](https://supabase.com/dashboard)
2. Buat proyek baru
3. Buka **SQL Editor**
4. Copy isi file [`supabase_schema.sql`](file:///c:/Milan/GIT/BradPOS/supabase_schema.sql) dan paste
5. Jalankan (Run) — ini akan membuat semua tabel, trigger, RLS policies, storage buckets, dan RPC functions

### 5. Setup Supabase Auth (Google OAuth)

Untuk Google Sign-In:

1. **Google Cloud Console** → Buat project → **OAuth consent screen** (External)
2. **Credentials** → Buat **OAuth 2.0 Client IDs**:
   - **Android**: Isi package name (`com.bradpos.app`) + **SHA-1 signing certificate fingerprint**
     - Untuk mendapatkan SHA-1:
       ```bash
       # Debug keystore (development):
       keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
       
       # Atau jika pakai PowerShell:
       keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
       ```
     - Output: cari baris `SHA1:` → `SHA1: 5E:8F:16:...` — copy paste ke Google Cloud Console
     - **Untuk production (rilis):**
       1. Buat keystore dulu (jika belum punya):
          ```bash
          # CMD
          keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
          
          # PowerShell
          keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
          ```
       2. Dapatkan SHA-1 dari keystore yang sudah dibuat:
          ```bash
          # CMD
          keytool -list -v -keystore android/app/upload-keystore.jks -alias upload -storepass <password> -keypass <password>
          
          # PowerShell
          keytool -list -v -keystore android/app/upload-keystore.jks -alias upload -storepass <password> -keypass <password>
          ```
       3. Ganti `<password>` dengan password yang kamu buat saat generate keystore
       4. Tambahkan SHA-1 hasilnya ke **Google Cloud Console** dan ke **Firebase Console** (jika pakai Firebase)
   - **iOS**: Bundle ID
   - **Web**: Authorized redirect URIs → `https://[project].supabase.co/auth/v1/callback`
3. **Supabase Dashboard** → Authentication → Providers → Google:
   - Aktifkan
   - Isi **Client ID** dan **Client Secret** dari Google Cloud
4. **Supabase Dashboard** → Authentication → Settings:
   - **Site URL**: URL app (untuk development: `http://localhost:3000` atau `http://localhost` untuk web)
   - **Redirect URLs**: Tambahkan redirect URI yang sesuai

### 6. Build & Run

```bash
# Debug (pilih platform)
flutter run

# Atau langsung ke platform tertentu:
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d android       # Android (emulator/hp)
```

> **Catatan untuk Web:** Database SQLite di Web menggunakan `sqflite_common_ffi_web` (bukan `sqflite` native). Pastikan tidak ada platform-specific error.

### 7. Login

Setelah app terbuka:

1. **Register** akun Owner baru (email + password)
2. Atau **Login** jika sudah punya akun
3. Atau **Lanjut sebagai Guest** untuk mencoba offline

---

## Architecture

### Clean Architecture (3-Layer)

```
lib/
├── config/               # Konfigurasi (placeholder)
├── core/                 # Design system, DB, sync, service, utility, shared widget
│   ├── database/         # DatabaseHelper, DbUtils, WebDatabaseAdapter
│   ├── sync/             # SyncService + 6 SyncManagers
│   ├── services/         # StockAlertService
│   ├── utils/            # AppNavigator
│   └── widgets/          # SplashPage, BradHeader, MainBottomNavBar, MainNavigationRail
├── data/                 # Models, data sources, repository impl
│   ├── data_sources/     # Local (SQFlite) + Remote (Supabase)
│   ├── models/           # DTO dengan serialisasi JSON/Map
│   └── repositories/     # Implementasi konkret dari interface domain
├── domain/               # Logika bisnis murni (tanpa Flutter)
│   ├── entities/         # Objek bisnis inti (menggunakan equatable)
│   └── repositories/     # Interface abstrak untuk repository
├── presentation/         # UI
│   ├── blocs/            # BLoC (Event → State)
│   ├── screens/          # Halaman per fitur
│   └── widgets/          # Widget reusable
├── injection_container.dart  # Registrasi GetIt
└── main.dart             # Entry point
```

### Alur Data (Data Flow)

```
┌──────────┐     ┌──────────┐     ┌────────────┐     ┌──────────────────┐
│   UI     │────▶│  BLoC    │────▶│ Repository  │────▶│   Data Source    │
│ (Screen) │◀────│ (State)  │◀────│  (Impl)    │◀────│ (Local/Remote)   │
└──────────┘     └──────────┘     └────────────┘     └────────┬─────────┘
                                        │                      │
                                        │              ┌───────▼────────┐
                                        │              │  SQLite Lokal   │
                                        │              │  (Source of     │
                                        │              │   Truth)        │
                                        │              └───────┬────────┘
                                        │                      │
                                        │              ┌───────▼────────┐
                                        └──────────────│  Supabase Cloud │
                                                       │  (Sync Target)  │
                                                       └────────────────┘
```

### Siklus Request (Contoh: Tambah Produk)

```
1. User tap "Simpan" → UI dispatch AddInventoryItemEvent
2. InventoryBloc menerima event
3. Panggil InventoryRepository.addInventoryItem()
4. InventoryRepositoryImpl:
   a. InventoryLocalDataSourceImpl.addInventoryItem() → INSERT ke SQLite (sync_status='created')
   b. Kembalikan InventoryItemModel
5. BLoC emit InventoryOperationSuccess
6. UI rebuild dengan state baru (instan, tanpa nunggu cloud)
7. Background: SyncService.syncAll() → push ke Supabase
```

### Sinkronisasi Offline-First

```
                        ┌─────────────┐
                        │  Aksi User  │
                        └──────┬──────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Simpan ke SQLite    │
                    │  sync_status=created │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Update UI (instan) │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  SyncService        │
                    │  (background)       │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Push ke Supabase   │
                    │  sync_status=synced  │
                    └─────────────────────┘
```

Urutan sync (`SyncService.syncAll()`):
1. Profile Sync
2. Karyawan Pull
3. **Push Phase:** Category → Product → Transaction
4. **Pull Phase:** Product → Transaction → Category

### Struktur Database Lokal (SQLite)

**5 tabel** dengan `sync_status` dan `updated_at` di setiap tabel:

```
produk        → id, owner_id, name, category, purchase_price, selling_price, stock, unit, barcode, image_url, ...
categories    → id, owner_id, name, description, ...
transactions  → id, owner_id, items (JSON), subtotal, total, payment_method, payment_amount, change_amount, ...
karyawan      → id, owner_id, full_name, password_hash, is_active, ...
profiles      → id, shop_id, shop_name, full_name, ...
```

### Database Remote (Supabase PostgreSQL)

Skema lengkap di [`supabase_schema.sql`](file:///c:/Milan/GIT/BradPOS/supabase_schema.sql):

- **5 Tabel:** profiles, categories, produk, karyawan, transactions
- **RLS (Row Level Security):** Aktif di semua tabel
- **Storage Buckets:** `produk_images` (gambar produk), `profile_images` (avatar)
- **RPC Functions:** `verify_karyawan_login_v2`, `create_karyawan_v2`
- **Auth Trigger:** `on_auth_user_created` — auto-create profile saat signup
- **Indeks:** trigram di `produk.name` untuk fuzzy search

### BLoC Architecture Map

| BLoC | File | Event Utama | State Utama |
|------|------|-------------|-------------|
| **AuthBloc** | [`auth_bloc.dart`](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/auth_bloc.dart) | SignIn, SignUp, GoogleSignIn, SignOut, CheckAuth, UpdateProfile | AuthInitial, AuthLoading, AuthAuthenticated, AuthUnauthenticated, AuthError |
| **DashboardBloc** | [`dashboard_bloc.dart`](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/dashboard_bloc.dart) | LoadDashboardStats | DashboardLoading, DashboardLoaded, DashboardError |
| **InventoryBloc** | [`inventory_bloc.dart`](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/inventory_bloc.dart) | LoadInventory, AddItem, UpdateItem, DeleteItem, SyncAll | InventoryLoading, InventoryLoaded, InventoryError, InventoryOperationSuccess |
| **CashierBloc** | [`cashier_bloc.dart`](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/cashier_bloc.dart) | AddToCart, UpdateQty, RemoveFromCart, ProcessPayment | CashierState (cart, subtotal, total, isProcessing, isSuccess) |
| **CategoryBloc** | [`category_bloc.dart`](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/category_bloc.dart) | LoadCategories, Add, Update, Delete | CategoryLoaded, CategoryError, CategoryOperationSuccess |
| **KaryawanBloc** | [`karyawan_bloc.dart`](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/karyawan_bloc.dart) | LoadKaryawanList, Create, Edit, Remove | KaryawanListLoaded, KaryawanError, KaryawanOperationSuccess |
| **HistoryBloc** | [`history_bloc.dart`](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/history/history_bloc.dart) | LoadHistory, LoadByRange, DeleteTransaction | HistoryLoaded, HistoryError |

### Alur Pembayaran

```
User pilih produk → AddToCart (CashierBloc)
  → Keranjang di CashierScreen
  → Tap "Bayar" → PaymentScreen
    → Metode Tunai: input nominal → hitung kembalian
    → Metode QRIS: auto-fill total
    → ProcessPayment
      → Simpan transaksi ke SQLite + potong stok
      → Generate nomor transaksi: BR-2026-6-8-A3F2
      → Emit sukses → SyncService push ke cloud
      → Tampilkan ReceiptDialog (cetak struk — on-screen)
```

---

## Environment Variables

Semua environment variable dimuat dari file `.env` menggunakan `flutter_dotenv`.

| Variable | Wajib | Default | Deskripsi |
|----------|-------|---------|-----------|
| `SUPABASE_URL` | ✅ Ya | - | URL proyek Supabase (https://xxx.supabase.co) |
| `SUPABASE_ANON_KEY` | ✅ Ya | - | Anon/public key dari Supabase Settings > API |
| `GOOGLE_WEB_CLIENT_ID` | 🟡 Web OAuth | - | Client ID dari Google Cloud Console |

### File `.env.example`

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
GOOGLE_WEB_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
```

### File `.env` (tidak di-commit)

File `.env` sudah masuk `.gitignore`. Buat manual dengan copy dari `.env.example`.

---

## Available Scripts

| Command | Deskripsi |
|---------|-----------|
| `flutter pub get` | Install dependencies |
| `flutter pub upgrade` | Upgrade dependencies ke versi terbaru |
| `flutter run` | Jalankan app di mode debug |
| `flutter run -d chrome` | Jalankan di Web |
| `flutter run -d windows` | Jalankan di Windows |
| `flutter run -d android` | Jalankan di Android |
| `flutter build apk` | Build Android APK |
| `flutter build appbundle` | Build Android App Bundle |
| `flutter build web` | Build untuk Web (produksi) |
| `flutter build windows` | Build untuk Windows |
| `flutter analyze` | Analisis kode statis (linter) |
| `flutter test` | Jalankan semua test |
| `dart format .` | Format kode sesuai standar Dart |

---

## Testing

Saat ini test coverage masih minimal. Hanya ada satu file test:

```bash
flutter test
```

Test file: [`test/widget_test.dart`](file:///c:/Milan/GIT/BradPOS/test/widget_test.dart) — smoke test dasar.

Untuk menambahkan test, ikuti struktur:

```
test/
├── data/
│   ├── data_sources/     # Test data source (mock Supabase)
│   ├── models/           # Test serialisasi model
│   └── repositories/     # Test repository dengan mock
├── domain/
│   └── entities/         # Test entity (copyWith, props)
├── presentation/
│   └── blocs/            # Test BLoC (bloc_test)
└── widget_test.dart
```

### Ingin berkontribusi test? Mulai dari sini:

1. Test entity: validasi `copyWith()` dan `props`
2. Test model: `fromMap()` dan `toMap()` roundtrip
3. Test BLoC: gunakan `bloc_test` dari `flutter_bloc`
4. Mock data sources untuk repository test

---

## Deployment

### Build untuk Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (untuk Play Store)
flutter build appbundle --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

### Docker (Manual)

Tidak ada Dockerfile bawaan. Untuk deployment container:

```dockerfile
# Contoh Dockerfile
FROM cirrusci/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter build web --release

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Hosting Web

Hasil build web ada di `build/web/`. Deploy ke static hosting:

- **Vercel / Netlify**: Deploy folder `build/web/`
- **Firebase Hosting**: `firebase deploy --only hosting`
- **Nginx / Apache**: Copy `build/web/*` ke document root

### Catatan Penting

- **Supabase URL & Anon Key** harus di-set sebagai environment variable di production
- **Google OAuth** untuk Web: Pastikan redirect URI sudah ditambahkan di Google Cloud Console dan Supabase Auth settings
- **CORS:** Untuk deployment Web, konfigurasi CORS di Supabase jika perlu

---

## Troubleshooting

### Flutter Build Error

**Error:** `flutter pub get` gagal

**Solusi:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Database SQLite Error

**Error:** `DatabaseException: no such table`

**Solusi:**
1. Hapus data aplikasi (cache DB)
2. Uninstall dan install ulang
3. Jika masih muncul, cek versi migrasi di [`database_helper.dart`](file:///c:/Milan/GIT/BradPOS/lib/core/database/database_helper.dart) (current: **v16**)

### Supabase Connection Error

**Error:** `AuthException: Invalid API key` atau `Failed to fetch`

**Solusi:**
1. Cek `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `.env`
2. Pastikan Supabase project aktif
3. Cek RLS policies di SQL Editor — jalankan ulang [`supabase_schema.sql`](file:///c:/Milan/GIT/BradPOS/supabase_schema.sql)

### Web Database Error

**Error:** `Unsupported operation: Platform._version` di Web

**Solusi:**
Ini normal. Web menggunakan `sqflite_common_ffi_web` sebagai fallback. Pastikan dependensi `sqflite_common_ffi_web` dan `sembast_web` ada di `pubspec.yaml`.

### Google Sign-In Error

**Error:** `PlatformException: sign_in_failed`

**Solusi (Android):**
1. Cek SHA-1 fingerprint di Google Cloud Console
2. Pastikan package name sesuai (`com.bradpos.app`)
3. Untuk debug: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`



### Migrasi Data Guest Hilang

**Masalah:** Data guest hilang setelah login

**Solusi:**
1. Pastikan login menggunakan akun yang sama dengan device
2. `migrateOfflineData()` otomatis jalan saat guest login — pindahkan data dari `owner_id='offline_guest'` ke UUID baru
3. Jika masih bermasalah, cek log di console: `SyncService` dan `InventoryLocalDataSource.migrateOfflineData`

---

## Struktur File Lengkap

```
lib/
├── main.dart                                    # Entry point aplikasi
├── injection_container.dart                     # Registrasi dependency (GetIt)
│
├── config/
│   └── .gitkeep
│
├── core/
│   ├── app_colors.dart                          # Palet warna (Deep Emerald)
│   ├── database/
│   │   ├── database_helper.dart                 # Singleton SQLite (migrasi v16)
│   │   ├── db_utils.dart                        # Helper platform-aware
│   │   └── web_database_adapter.dart            # Sqflite FFI untuk Web
│   ├── services/
│   │   └── stock_alert_service.dart             # Query stok menipis/habis
│   ├── sync/
│   │   ├── sync_service.dart                    # Orchestrator sync utama
│   │   ├── sync_utils.dart                      # UUID, hash, helpers
│   │   ├── product_sync_manager.dart            # Sync produk
│   │   ├── category_sync_manager.dart           # Sync kategori
│   │   ├── transaction_sync_manager.dart        # Sync transaksi
│   │   ├── karyawan_sync_manager.dart           # Sync karyawan (pull)
│   │   └── profile_sync_manager.dart            # Sync profil
│   ├── utils/
│   │   └── app_navigator.dart                   # Navigator dengan animasi
│   └── widgets/
│       ├── splash_page.dart                     # Splash screen
│       ├── brad_header.dart                     # App bar reusable
│       ├── main_bottom_nav_bar.dart             # Bottom nav (mobile)
│       └── main_navigation_rail.dart            # Side nav (tablet)
│
├── data/
│   ├── data_sources/
│   │   ├── inventory_local_data_source.dart     # CRUD produk lokal
│   │   ├── inventory_remote_data_source.dart    # CRUD produk remote
│   │   ├── inventory_image_uploader.dart        # Upload gambar ke Supabase Storage
│   │   ├── category_local_data_source.dart      # CRUD kategori lokal
│   │   ├── category_remote_data_source.dart     # CRUD kategori remote
│   │   ├── transaction_local_data_source.dart   # CRUD transaksi lokal
│   │   ├── transaction_remote_data_source.dart  # CRUD transaksi remote
│   │   ├── karyawan_local_data_source.dart      # CRUD karyawan lokal
│   │   ├── karyawan_remote_data_source.dart     # CRUD karyawan remote
│   │   ├── profile_local_data_source.dart       # CRUD profil lokal
│   │   └── profile_remote_data_source.dart      # CRUD profil remote
│   ├── models/
│   │   ├── inventory_item_model.dart            # Model produk
│   │   ├── category_model.dart                  # Model kategori
│   │   ├── transaction_model.dart               # Model transaksi
│   │   ├── karyawan_model.dart                  # Model karyawan
│   │   ├── dashboard_stats_model.dart           # Model statistik
│   │   └── profile_model.dart                   # Model profil
│   └── repositories/
│       ├── auth_repository_impl.dart            # Auth Owner (Supabase)
│       ├── auth_karyawan_repository_impl.dart   # Auth Karyawan (mixin)
│       ├── inventory_repository_impl.dart       # Repository produk
│       ├── category_repository_impl.dart        # Repository kategori
│       ├── transaction_repository_impl.dart     # Repository transaksi
│       ├── karyawan_repository_impl.dart        # Repository karyawan
│       └── dashboard_repository_impl.dart       # Repository dashboard
│
├── domain/
│   ├── entities/
│   │   ├── user_entity.dart                     # User (owner/karyawan/guest)
│   │   ├── inventory_item.dart                  # Produk
│   │   ├── category.dart                        # Kategori
│   │   ├── transaction.dart                     # Transaksi
│   │   ├── transaction_item.dart                # Item transaksi
│   │   ├── karyawan.dart                        # Karyawan
│   │   └── dashboard_stats.dart                 # Statistik dashboard
│   └── repositories/
│       ├── auth_repository.dart                 # Interface auth
│       ├── inventory_repository.dart            # Interface produk
│       ├── category_repository.dart             # Interface kategori
│       ├── transaction_repository.dart          # Interface transaksi
│       ├── karyawan_repository.dart             # Interface karyawan
│       └── dashboard_repository.dart            # Interface dashboard
│
└── presentation/
    ├── blocs/
    │   ├── auth_bloc.dart + auth_event.dart + auth_state.dart
    │   ├── dashboard_bloc.dart + dashboard_state.dart
    │   ├── inventory_bloc.dart + inventory_event.dart + inventory_state.dart
    │   ├── cashier_bloc.dart
    │   ├── category_bloc.dart + category_event.dart + category_state.dart
    │   ├── karyawan_bloc.dart + karyawan_event.dart + karyawan_state.dart
    │   ├── history/history_bloc.dart + history_event.dart + history_state.dart
    │   └── transaction_detail/...
    ├── screens/
    │   ├── login/login_screen.dart, login_owner_form.dart, login_karyawan_form.dart, register_screen.dart
    │   ├── dashboard/dashboard_screen.dart
    │   ├── cashier/cashier_screen.dart, payment_screen.dart, cart_summary_view.dart, ...
    │   ├── inventory/inventory_screen.dart, inventory_form_screen.dart, ...
    │   ├── category/category_screen.dart, category_form_screen.dart, ...
    │   ├── karyawan/karyawan_screen.dart, karyawan_form_screen.dart, ...
    │   ├── history/history_screen.dart, history_filter_section.dart, ...
    │   ├── profile/profile_screen.dart, personal_profile_screen.dart
    │   └── report/transaction_detail_screen.dart
    └── widgets/
        ├── stat_card.dart, quick_action_card.dart, quick_action_button.dart
        ├── numpad_widget.dart, currency_input_formatter.dart
        ├── receipt_dialog.dart, settings_modal.dart
        ├── low_stock_banner.dart, stock_alert_badge.dart, sync_status_indicator.dart
        ├── sales_chart_widget.dart
        ├── profile_text_field.dart, profile_image_picker.dart, avatar_picker_widget.dart
        ├── image_source_picker.dart, full_screen_image_viewer.dart
        └── category_picker_modal.dart (shared dengan inventory)
```

---

## Kontribusi

1. Fork repositori ini
2. Buat branch fitur: `git checkout -b fitur/namafitur`
3. Commit perubahan: `git commit -m 'feat: tambah fitur xxx'`
4. Push ke branch: `git push origin fitur/namafitur`
5. Buat Pull Request

### Aturan Kode

- Ikuti [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Gunakan **Clean Architecture** — jangan campur logika bisnis di UI
- Setiap entitas bisnis butuh: Entity → Model → LocalDataSource → RemoteDataSource → Repository → BLoC
- Fitur baru harus testable (usahakan pakai dependency injection)
- `sync_status` wajib di-set untuk setiap operasi write

---

## Lisensi

Dilisensikan di bawah **MIT License**. Lihat file [LICENSE](file:///c:/Milan/GIT/BradPOS/LICENSE) untuk detail.

---

*Dokumentasi codebase lengkap ada di [`docs/BRADPOS_CODEBASE_DOCUMENTATION.md`](file:///c:/Milan/GIT/BradPOS/docs/BRADPOS_CODEBASE_DOCUMENTATION.md).*
