# BradPOS — Dokumentasi Lengkap Codebase

> **Versi:** 1.0.0+1  
> **Arsitektur:** Clean Architecture (3-Layer)  
> **State Management:** Flutter BLoC  
> **Database:** SQLite (Lokal) + Supabase PostgreSQL (Remote)  
> **Dependency Injection:** GetIt  

---

## Daftar Isi

1. [Ringkasan Proyek](#1-ringkasan-proyek)
2. [Arsitektur & Layer](#2-arsitektur--layer)
3. [Domain Layer](#3-domain-layer)
4. [Data Layer](#4-data-layer)
5. [Core Layer](#5-core-layer)
6. [Presentation Layer](#6-presentation-layer)
7. [Sistem Autentikasi](#7-sistem-autentikasi)
8. [Sistem Sinkronisasi (Offline-First)](#8-sistem-sinkronisasi-offline-first)
9. [Skema Database](#9-skema-database)
10. [Alur Kasir & Pembayaran](#10-alur-kasir--pembayaran)
11. [Konfigurasi & Environment](#11-konfigurasi--environment)
12. [Testing](#12-testing)

---

## 1. Ringkasan Proyek

**BradPOS** adalah sistem **Point of Sale (POS)** berbasis **Flutter** yang didesain untuk operasi **offline-first**. Mendukung multi-toko, multi-role (Owner/Karyawan/Guest), sinkronasi real-time via Supabase, dan cetak struk thermal.

### Fitur Utama
- Offline-first dengan sinkronasi latar belakang ke Supabase
- Dual auth: Owner (Supabase Auth) + Karyawan (DB Kustom)
- Mode Guest untuk uji coba offline
- Kontrol akses berbasis role (Owner vs Karyawan)
- Pembayaran QRIS & Tunai
- Manajemen stok dengan notifikasi stok menipis
- Dukungan barcode
- Cetak struk (thermal/Bluetooth)
- Kompatibel Web (Sqflite FFI untuk browser)

### Ringkasan File

| Layer | Path | File |
|-------|------|------|
| Domain - Entitas | `lib/domain/entities/` | 7 |
| Domain - Interface Repository | `lib/domain/repositories/` | 6 |
| Data - Model | `lib/data/models/` | 6 |
| Data - Data Source | `lib/data/data_sources/` | 11 |
| Data - Implementasi Repository | `lib/data/repositories/` | 7 |
| Core - Database | `lib/core/database/` | 3 |
| Core - Sync | `lib/core/sync/` | 7 |
| Core - Service | `lib/core/services/` | 1 |
| Core - Utility | `lib/core/utils/` | 1 |
| Core - Widget | `lib/core/widgets/` | 4 |
| Presentation - Bloc | `lib/presentation/blocs/` | 15 (+ sub) |
| Presentation - Screen | `lib/presentation/screens/` | ~40 |
| Presentation - Widget | `lib/presentation/widgets/` | 16 |
| Config | `lib/` root | 3 |
| **Total** | | **~125 file** |

---

## 2. Arsitektur & Layer

```
lib/
├── config/           # Konfigurasi aplikasi (placeholder)
├── core/             # Design system, DB, sync, service, utility, shared widget
├── data/             # Model, data source, implementasi repository
│   ├── data_sources/ # Provider Lokal (SQFlite) & Remote (Supabase)
│   ├── models/       # DTO serializable JSON/Map (extends entity domain)
│   └── repositories/ # Implementasi konkret dari interface domain
├── domain/           # Logika bisnis murni (tanpa dependensi Flutter)
│   ├── entities/     # Objek bisnis inti
│   └── repositories/ # Definisi interface abstrak
├── presentation/     # Layer UI
│   ├── blocs/        # Business Logic Components (BLoC)
│   ├── screens/      # Halaman penuh per fitur
│   └── widgets/      # Komponen UI reusable
├── injection_container.dart  # Registrasi DI GetIt
└── main.dart         # Entry point aplikasi
```

### Alur Data

```
UI → BLoC (Event) → Repository (Interface) → RepositoryImpl → DataSource (Local/Remote) → DB/API
                                                      ↕
                                              SyncService (Background)
```

### Contoh Alur (Tambah Produk)

```
User tap "Tambah" → AddInventoryItemEvent → InventoryBloc
  → InventoryRepositoryImpl.addInventoryItem()
    → InventoryLocalDataSourceImpl.addInventoryItem() ← simpan ke SQLite
  → Emit InventoryOperationSuccess
  → SyncService.syncAll() → push ke Supabase di background
```

---

## 3. Domain Layer

> **Path:** `lib/domain/`  
> **Tujuan:** Logika bisnis murni. Tanpa dependensi Flutter/Supabase. Berisi entity dan kontrak interface repository.

### 3.1 Entitas (`lib/domain/entities/`)

Semua entitas pakai `equatable` untuk value equality, field immutable.

| Entitas | File | Field Utama |
|---------|------|-------------|
| [UserEntity](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/user_entity.dart) | [user_entity.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/user_entity.dart) | `id`, `email`, `name`, `shopName`, `shopId`, `role` (owner/karyawan/guest), `ownerId`, `remoteImage`, `localImage`, `address`, `phone` |
| [InventoryItem](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/inventory_item.dart) | [inventory_item.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/inventory_item.dart) | `id`, `ownerId`, `categoryId`, `name`, `category`, `purchasePrice`, `sellingPrice`, `stock` (-1 = unlimited), `unit`, `barcode`, `imageUrl`, `isActive` |
| [Category](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/category.dart) | [category.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/category.dart) | `id`, `ownerId`, `name`, `description`, `createdAt`, `updatedAt` |
| [Karyawan](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/karyawan.dart) | [karyawan.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/karyawan.dart) | `id`, `ownerId`, `name`, `password`, `isActive`, `createdAt`, `remoteImage`, `localImage` |
| [Transaction](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/transaction.dart) | [transaction.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/transaction.dart) | `id`, `ownerId`, `karyawanId`, `cashierName`, `transactionNumber`, `customerName`, `shopName`, `items` (List), `subtotal`, `discount`, `tax`, `total`, `paymentMethod`, `paymentAmount`, `changeAmount`, `status` |
| [TransactionItem](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/transaction_item.dart) | [transaction_item.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/transaction_item.dart) | `id`, `transactionId`, `produkId`, `productName`, `quantity`, `unitPrice`, `discount`, `subtotal` |
| [DashboardStats](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/dashboard_stats.dart) | [dashboard_stats.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/entities/dashboard_stats.dart) | `totalSales`, `salesGrowth`, `totalTransactions`, `transactionsGrowth`, `avgTicketSize`, `ticketSizeGrowth`, `dailySales` |

### 3.2 Interface Repository (`lib/domain/repositories/`)

Semua return `Either<String, T>` (via `dartz`) — `Left` = pesan error, `Right` = sukses.

| Interface | File | Method Utama |
|-----------|------|-------------|
| [AuthRepository](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/auth_repository.dart) | [auth_repository.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/auth_repository.dart) | `signIn()`, `signUp()`, `signInWithGoogle()`, `signOut()`, `getCurrentUser()`, `updateProfile()`, `signInAsGuest()`, `signInAsKaryawan()`, `createKaryawan()` |
| [InventoryRepository](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/inventory_repository.dart) | [inventory_repository.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/inventory_repository.dart) | `getInventory()`, `getInventoryCount()`, `addInventoryItem()`, `updateInventoryItem()`, `deleteInventoryItem()`, `isProductNameExists()`, `hasOfflineData()`, `syncOfflineData()` |
| [CategoryRepository](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/category_repository.dart) | [category_repository.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/category_repository.dart) | `getCategories()`, `addCategory()`, `updateCategory()`, `deleteCategory()` |
| [KaryawanRepository](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/karyawan_repository.dart) | [karyawan_repository.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/karyawan_repository.dart) | `getKaryawans()`, `addKaryawan()`, `updateKaryawan()`, `deleteKaryawan()` |
| [TransactionRepository](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/transaction_repository.dart) | [transaction_repository.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/transaction_repository.dart) | `createTransaction()`, `getTransactions()`, `getTransactionsByRange()`, `getTransactionById()`, `getTransactionItems()`, `deleteTransaction()` |
| [DashboardRepository](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/dashboard_repository.dart) | [dashboard_repository.dart](file:///c:/Milan/GIT/BradPOS/lib/domain/repositories/dashboard_repository.dart) | `getDashboardStats()` |

---

## 4. Data Layer

> **Path:** `lib/data/`  
> **Tujuan:** Model, data source, dan implementasi repository.

### 4.1 Model (`lib/data/models/`)

Model extends entity domain, nambahin serialisasi JSON/Map.

| Model | File | Extends | Factory |
|-------|------|---------|---------|
| [InventoryItemModel](file:///c:/Milan/GIT/BradPOS/lib/data/models/inventory_item_model.dart) | [inventory_item_model.dart](file:///c:/Milan/GIT/BradPOS/lib/data/models/inventory_item_model.dart) | `InventoryItem` | `fromJson()`, `fromMap()`, `fromEntity()` |
| [CategoryModel](file:///c:/Milan/GIT/BradPOS/lib/data/models/category_model.dart) | [category_model.dart](file:///c:/Milan/GIT/BradPOS/lib/data/models/category_model.dart) | `Category` | `fromMap()`, `fromEntity()` |
| [KaryawanModel](file:///c:/Milan/GIT/BradPOS/lib/data/models/karyawan_model.dart) | [karyawan_model.dart](file:///c:/Milan/GIT/BradPOS/lib/data/models/karyawan_model.dart) | `Karyawan` | `fromMap()`, `fromEntity()`, `toEntity()` |
| [TransactionModel](file:///c:/Milan/GIT/BradPOS/lib/data/models/transaction_model.dart) | [transaction_model.dart](file:///c:/Milan/GIT/BradPOS/lib/data/models/transaction_model.dart) | `Transaction` | `fromEntity()`, `fromMap()`, `toEntity()` |
| [DashboardStatsModel](file:///c:/Milan/GIT/BradPOS/lib/data/models/dashboard_stats_model.dart) | [dashboard_stats_model.dart](file:///c:/Milan/GIT/BradPOS/lib/data/models/dashboard_stats_model.dart) | `DashboardStats` | `fromJson()` |
| [ProfileModel](file:///c:/Milan/GIT/BradPOS/lib/data/models/profile_model.dart) | [profile_model.dart](file:///c:/Milan/GIT/BradPOS/lib/data/models/profile_model.dart) | *(standalone)* | `fromMap()` |

### 4.2 Data Source (`lib/data/data_sources/`)

Tiap entity punya **dua** data source: **Lokal** (SQFlite) dan **Remote** (Supabase). Ini kunci arsitektur offline-first.

#### Data Source Lokal

| Class | File | Operasi Utama |
|-------|------|---------------|
| [InventoryLocalDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/inventory_local_data_source.dart) | [inventory_local_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/inventory_local_data_source.dart) | CRUD tabel `produk`, `getUnsyncedItems()`, `saveInventoryItems()`, `updateSyncStatus()`, `migrateOfflineData()`, `fixInvalidId()`, `getLastSyncTime()` |
| [CategoryLocalDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/category_local_data_source.dart) | [category_local_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/category_local_data_source.dart) | CRUD tabel `categories`, `getUnsyncedCategories()`, `saveCategories()`, `fixInvalidCategoryId()` |
| [TransactionLocalDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/transaction_local_data_source.dart) | [transaction_local_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/transaction_local_data_source.dart) | `createTransaction()` (auto potong stok), `getTransactions()`, `getTransactionsByRange()`, `getTransactionItems()` |
| [KaryawanLocalDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/karyawan_local_data_source.dart) | [karyawan_local_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/karyawan_local_data_source.dart) | CRUD tabel `karyawan`, batch `saveKaryawans()` |
| [ProfileLocalDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/profile_local_data_source.dart) | [profile_local_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/profile_local_data_source.dart) | `getProfile()`, `saveProfile()` |

#### Data Source Remote

| Class | File | Operasi Utama |
|-------|------|---------------|
| [InventoryRemoteDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/inventory_remote_data_source.dart) | [inventory_remote_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/inventory_remote_data_source.dart) | Mixin `InventoryImageUploader`. `getInventory()`, `pushCreatedItem()`, `pushUpdatedItem()`, `pushDeletedItem()` |
| [CategoryRemoteDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/category_remote_data_source.dart) | [category_remote_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/category_remote_data_source.dart) | `getCategories()`, `pushCreatedCategory()`, `pushUpdatedCategory()`, `pushDeletedCategory()` |
| [TransactionRemoteDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/transaction_remote_data_source.dart) | [transaction_remote_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/transaction_remote_data_source.dart) | `createTransaction()`, `getTransactions()`, `pushUnsyncedTransaction()` |
| [KaryawanRemoteDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/karyawan_remote_data_source.dart) | [karyawan_remote_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/karyawan_remote_data_source.dart) | `getKaryawans()`, `createKaryawan()`, `updateKaryawan()`, `deleteKaryawan()`, `uploadImage()`, `deleteImage()` |
| [ProfileRemoteDataSourceImpl](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/profile_remote_data_source.dart) | [profile_remote_data_source.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/profile_remote_data_source.dart) | `getProfile()`, `upsertProfile()`, `uploadProfileImage()`, `deleteProfileImage()` |
| [InventoryImageUploader mixin](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/inventory_image_uploader.dart) | [inventory_image_uploader.dart](file:///c:/Milan/GIT/BradPOS/lib/data/data_sources/inventory_image_uploader.dart) | `uploadImage()`, `deleteOldImageByUrl()` — Upload gambar produk ke Supabase Storage bucket `produk_images` |

### 4.3 Implementasi Repository (`lib/data/repositories/`)

| Class | File | Implements | Logika Utama |
|-------|------|------------|--------------|
| [AuthRepositoryImpl](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/auth_repository_impl.dart) | [auth_repository_impl.dart](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/auth_repository_impl.dart) | `AuthRepository` | Supabase Auth utk Owner, `KaryawanAuthMixin` utk Karyawan, Guest via SharedPreferences. Persistensi session, sync profil, Google OAuth (web redirect + mobile plugin). |
| [AuthKaryawanRepositoryImpl](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/auth_karyawan_repository_impl.dart) | [auth_karyawan_repository_impl.dart](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/auth_karyawan_repository_impl.dart) | *(mixin)* | Login Karyawan via RPC `verify_karyawan_login_v2`, CRUD via Supabase. |
| [InventoryRepositoryImpl](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/inventory_repository_impl.dart) | [inventory_repository_impl.dart](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/inventory_repository_impl.dart) | `InventoryRepository` | Delegasi ke LocalDataSource, handle migrasi data offline, orchestasi sync. |
| [CategoryRepositoryImpl](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/category_repository_impl.dart) | [category_repository_impl.dart](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/category_repository_impl.dart) | `CategoryRepository` | CRUD kategori + update nama kategori di produk. |
| [TransactionRepositoryImpl](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/transaction_repository_impl.dart) | [transaction_repository_impl.dart](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/transaction_repository_impl.dart) | `TransactionRepository` | Buat transaksi lokal dulu, sync remote. Potong stok. |
| [KaryawanRepositoryImpl](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/karyawan_repository_impl.dart) | [karyawan_repository_impl.dart](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/karyawan_repository_impl.dart) | `KaryawanRepository` | CRUD lokal + remote. Hash password SHA-256. |
| [DashboardRepositoryImpl](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/dashboard_repository_impl.dart) | [dashboard_repository_impl.dart](file:///c:/Milan/GIT/BradPOS/lib/data/repositories/dashboard_repository_impl.dart) | `DashboardRepository` | Query transaksi lokal utk statistik. |

---

## 5. Core Layer

> **Path:** `lib/core/`

### 5.1 Database (`lib/core/database/`)

| File | Class | Deskripsi |
|------|-------|-----------|
| [database_helper.dart](file:///c:/Milan/GIT/BradPOS/lib/core/database/database_helper.dart) | `DatabaseHelper` | Singleton. Mengelola siklus hidup SQLite. Migrasi sampai v16. Tabel: `produk`, `categories`, `transactions`, `karyawan`, `profiles`. |
| [db_utils.dart](file:///c:/Milan/GIT/BradPOS/lib/core/database/db_utils.dart) | `DbUtils` | Helper platform-aware: `ConflictAlgorithm.replace`, `firstIntValue()`. |
| [web_database_adapter.dart](file:///c:/Milan/GIT/BradPOS/lib/core/database/web_database_adapter.dart) | `WebDatabaseAdapter` | Adaptor Sqflite FFI utk Web. Bungkus `databaseFactoryFfiWeb`. |

**Riwayat Migrasi (v1→v16):**

| Versi | Perubahan |
|-------|-----------|
| v2 | `produk` tambah `image_url` |
| v3 | Buat tabel `karyawan` |
| v4 | Buat tabel `profiles` |
| v5 | `transactions` tambah `cashier_name` |
| v6 | `produk` tambah `category_id` |
| v7 | `produk` tambah `purchase_price`, `selling_price`, `unit`, `is_active` |
| v8 | `produk` tambah `barcode` |
| v9 | `categories` tambah `description` |
| v10 | `transactions` tambah `shop_name` |
| v11 | `profiles` tambah `remote_image`, `local_image` |
| v12 | `profiles` tambah `full_name` |
| v14 | `profiles` tambah `shop_id` |
| v15 | `karyawan` tambah `remote_image`, `local_image` |
| v16 | `karyawan` hapus kolom `email` (rename + recreate table) |

### 5.2 Sinkronisasi (`lib/core/sync/`)

| File | Class | Deskripsi |
|------|-------|-----------|
| [sync_service.dart](file:///c:/Milan/GIT/BradPOS/lib/core/sync/sync_service.dart) | `SyncService` | Orkestrator. Cegah konkurensi via flag `_isSyncing`. Urutan: Profile → Karyawan → Push (Category → Product → Transaction) → Pull (Product → Transaction → Category). |
| [product_sync_manager.dart](file:///c:/Milan/GIT/BradPOS/lib/core/sync/product_sync_manager.dart) | `ProductSyncManager` | Push produk belum sync (created/updated), pull produk remote inkremental via `lastSync`. Handle fix UUID invalid dan reassign guest owner. |
| [category_sync_manager.dart](file:///c:/Milan/GIT/BradPOS/lib/core/sync/category_sync_manager.dart) | `CategorySyncManager` | Push/pull untuk kategori. |
| [transaction_sync_manager.dart](file:///c:/Milan/GIT/BradPOS/lib/core/sync/transaction_sync_manager.dart) | `TransactionSyncManager` | Push transaksi belum sync (dengan items JSON). Pull inkremental via `created_at`. |
| [karyawan_sync_manager.dart](file:///c:/Milan/GIT/BradPOS/lib/core/sync/karyawan_sync_manager.dart) | `KaryawanSyncManager` | Pull-only. Filter lewat `KaryawanModel` utk buang field legacy. |
| [profile_sync_manager.dart](file:///c:/Milan/GIT/BradPOS/lib/core/sync/profile_sync_manager.dart) | `ProfileSyncManager` | Sinkronasi data profil (nama toko, alamat, gambar) dari Supabase ke SQLite lokal + SharedPreferences. |
| [sync_utils.dart](file:///c:/Milan/GIT/BradPOS/lib/core/sync/sync_utils.dart) | `SyncUtils` | Helper: `isInvalidUuid()`, `fixUuid()`, `belongsToOtherUser()`, `isGuestOwner()`, `shouldPush()`, `hashPassword()` (SHA-256), `getUserId()`, `formatWebDate()`. |

**Flag `sync_status`:**
- `'synced'` — Tersinkronasi penuh
- `'created'` — Record baru, perlu push
- `'updated'` — Dimodifikasi, perlu push
- `'pending_update'` — Update kaskade tertunda
- `'deleted'` — Ditandai hapus, menunggu sync
- `'deleted_synced'` — Hapus dari lokal setelah konfirmasi

### 5.3 Service (`lib/core/services/`)

| File | Class | Deskripsi |
|------|-------|-----------|
| [stock_alert_service.dart](file:///c:/Milan/GIT/BradPOS/lib/core/services/stock_alert_service.dart) | `StockAlertService` | Query DB lokal utk stok menipis (≤10) dan habis (≤0). Cache `lastTotalAlert` utk badge navbar. |

### 5.4 Utility (`lib/core/utils/`)

| File | Class | Deskripsi |
|------|-------|-----------|
| [app_navigator.dart](file:///c:/Milan/GIT/BradPOS/lib/core/utils/app_navigator.dart) | `AppNavigator` | Bungkus Navigator dengan `smooth_transition` (fadeThrough, 400ms). Method: `push()`, `pushReplacement()`, `pushAndRemoveUntil()`, `pop()`. |

### 5.5 Core Widget (`lib/core/widgets/`)

| File | Widget | Deskripsi |
|------|--------|-----------|
| [splash_page.dart](file:///c:/Milan/GIT/BradPOS/lib/core/widgets/splash_page.dart) | `SplashPage` | Splash animasi dengan gradient. Cek auth state → sync → navigasi ke Dashboard atau Login. Support landscape/portrait. |
| [brad_header.dart](file:///c:/Milan/GIT/BradPOS/lib/core/widgets/brad_header.dart) | `BradHeader` | App bar reusable: title, subtitle, icon leading, tombol back, tombol sync, tombol settings. Landscape-aware. |
| [main_bottom_nav_bar.dart](file:///c:/Milan/GIT/BradPOS/lib/core/widgets/main_bottom_nav_bar.dart) | `MainBottomNavBar` | Navigasi bawah utk mobile: Dashboard, Cashier, Inventory (badge), History. |
| [main_navigation_rail.dart](file:///c:/Milan/GIT/BradPOS/lib/core/widgets/main_navigation_rail.dart) | `MainNavigationRail` | Navigasi samping utk tablet/landscape: item sama + settings + logout. |

---

## 6. Presentation Layer

> **Path:** `lib/presentation/`

### 6.1 Arsitektur BLoC

Setiap BLoC ikut pola standar: `Bloc<Event, State>`. Event dikirim dari UI. Perubahan state trigger rebuild UI.

| Bloc | File | Event | State |
|------|------|-------|-------|
| [AuthBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/auth_bloc.dart) | [auth_bloc.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/auth_bloc.dart) | `SignInRequested`, `SignUpRequested`, `GoogleSignInRequested`, `ContinueAsGuestRequested`, `SignInAsKaryawanRequested`, `SignOutRequested`, `CheckAuthStatus`, `UpdateProfileEvent` | `AuthInitial`, `AuthLoading`, `AuthAuthenticated(user)`, `AuthUnauthenticated`, `AuthError` |
| [DashboardBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/dashboard_bloc.dart) | [dashboard_bloc.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/dashboard_bloc.dart) | `LoadDashboardStats` | `DashboardInitial`, `DashboardLoading`, `DashboardLoaded(stats, lowStockCount, outOfStockCount)`, `DashboardError` |
| [InventoryBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/inventory_bloc.dart) | [inventory_bloc.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/inventory_bloc.dart) | `LoadInventory`, `LoadInventoryCategoriesEvent`, `AddInventoryItemEvent`, `UpdateInventoryItemEvent`, `DeleteInventoryItemEvent`, `SyncAllEvent` | `InventoryInitial`, `InventoryLoading`, `InventoryLoaded(items, categories, pagination)`, `InventoryError`, `InventoryOperationSuccess` |
| [CashierBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/cashier_bloc.dart) | [cashier_bloc.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/cashier_bloc.dart) | `AddToCart`, `UpdateCartQuantity`, `RemoveFromCart`, `ClearCart`, `ProcessPayment`, `UpdateCustomerName` | `CashierState(cartItems, subtotal, total, isProcessing, error, isSuccess)` |
| [CategoryBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/category_bloc.dart) | [category_bloc.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/category_bloc.dart) | `LoadCategoriesEvent`, `AddCategoryEvent`, `UpdateCategoryEvent`, `DeleteCategoryEvent` | `CategoryInitial`, `CategoryLoading`, `CategoryLoaded`, `CategoryError`, `CategoryOperationSuccess` |
| [KaryawanBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/karyawan_bloc.dart) | [karyawan_bloc.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/karyawan_bloc.dart) | `LoadKaryawanList`, `CreateKaryawan`, `EditKaryawan`, `RemoveKaryawan` | `KaryawanInitial`, `KaryawanLoading`, `KaryawanListLoaded`, `KaryawanError`, `KaryawanOperationSuccess` |
| [HistoryBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/history/history_bloc.dart) | [history_bloc.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/history/history_bloc.dart) | `LoadHistoryEvent`, `LoadHistoryByRangeEvent`, `DeleteTransactionEvent` | `HistoryInitial`, `HistoryLoading`, `HistoryLoaded(transactions, total)`, `HistoryError` |
| [TransactionDetailBloc](file:///c:/Milan/GIT/BradPOS/lib/presentation/blocs/transaction_detail/) | transaction_detail/ | (sub-direktori terpisah) | (state spesifik screen detail transaksi) |

### 6.2 Daftar Screen (`lib/presentation/screens/`)

| Screen | File | Deskripsi |
|--------|------|-----------|
| **Login** | `login/` | |
| [LoginScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/login_screen.dart) | [login_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/login_screen.dart) | Login tabbed (Owner / Karyawan). Google sign-in. Mode Guest. |
| [LoginOwnerForm](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/login_owner_form.dart) | [login_owner_form.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/login_owner_form.dart) | Form login email/password + Google OAuth. |
| [LoginKaryawanForm](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/login_karyawan_form.dart) | [login_karyawan_form.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/login_karyawan_form.dart) | Login via Shop ID + Nama + PIN. |
| [RegisterScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/register_screen.dart) | [register_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/login/register_screen.dart) | Form registrasi Owner. |
| **Dashboard** | `dashboard/` | |
| [DashboardScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/dashboard/dashboard_screen.dart) | [dashboard_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/dashboard/dashboard_screen.dart) | Kartu statistik, grafik, banner stok menipis, grid aksi cepat. |
| **Cashier** | `cashier/` | |
| [CashierScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/cashier/cashier_screen.dart) | [cashier_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/cashier/cashier_screen.dart) | Grid produk + panel keranjang. |
| [PaymentScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/cashier/payment_screen.dart) | [payment_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/cashier/payment_screen.dart) | Checkout: ringkasan pesanan, nama pelanggan, pilih metode bayar (Tunai/QRIS). |
| **Inventory** | `inventory/` | |
| [InventoryScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_screen.dart) | [inventory_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_screen.dart) | Daftar produk paginated dengan search, filter, sort. |
| [InventoryFormScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_form_screen.dart) | [inventory_form_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_form_screen.dart) | Form tambah/edit produk: gambar, barcode, harga. |
| [InventoryAddStockDialog](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_add_stock_dialog.dart) | [inventory_add_stock_dialog.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_add_stock_dialog.dart) | Dialog penyesuaian stok (tambah). |
| [InventoryReduceStockDialog](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_reduce_stock_dialog.dart) | [inventory_reduce_stock_dialog.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/inventory/inventory_reduce_stock_dialog.dart) | Dialog penyesuaian stok (kurang). |
| **Category** | `category/` | |
| [CategoryScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/category/category_screen.dart) | [category_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/category/category_screen.dart) | Manajemen daftar kategori. |
| [CategoryFormScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/category/category_form_screen.dart) | [category_form_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/category/category_form_screen.dart) | Tambah/edit kategori. |
| **Karyawan** | `karyawan/` | |
| [KaryawanScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/karyawan/karyawan_screen.dart) | [karyawan_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/karyawan/karyawan_screen.dart) | Daftar staf dengan filter aktif/nonaktif. |
| **History** | `history/` | |
| [HistoryScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/history/history_screen.dart) | [history_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/history/history_screen.dart) | Riwayat transaksi dengan filter tanggal, pagination, search. |
| **Profile** | `profile/` | |
| [ProfileScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/profile/profile_screen.dart) | [profile_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/profile/profile_screen.dart) | Manajemen profil toko (Owner). |
| [PersonalProfileScreen](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/profile/personal_profile_screen.dart) | [personal_profile_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/profile/personal_profile_screen.dart) | Manajemen profil pribadi (Karyawan). |
| **Report** | `report/` | (placeholder untuk laporan) |
| **Transaction Detail** | `history/transaction_detail_screen.dart` | [transaction_detail_screen.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/screens/report/transaction_detail_screen.dart) | Detail transaksi + opsi cetak struk. |

### 6.3 Widget Presentasi (`lib/presentation/widgets/`)

| Widget | File | Deskripsi |
|--------|------|-----------|
| [StatCard](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/stat_card.dart) | [stat_card.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/stat_card.dart) | Kartu metrik dashboard: icon, nilai, indikator pertumbuhan. |
| [QuickActionCard](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/quick_action_card.dart) | [quick_action_card.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/quick_action_card.dart) | Item grid aksi cepat di dashboard. |
| [QuickActionButton](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/quick_action_button.dart) | [quick_action_button.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/quick_action_button.dart) | Tombol aksi cepat individual. |
| [ReceiptDialog](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/receipt_dialog.dart) | [receipt_dialog.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/receipt_dialog.dart) | Tampilan struk transaksi layout thermal. |
| [NumpadWidget](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/numpad_widget.dart) | [numpad_widget.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/numpad_widget.dart) | Numpad kustom utk input bayar kasir. |
| [CurrencyInputFormatter](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/currency_input_formatter.dart) | [currency_input_formatter.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/currency_input_formatter.dart) | Formatter mata uang Rupiah. |
| [LowStockBanner](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/low_stock_banner.dart) | [low_stock_banner.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/low_stock_banner.dart) | Banner peringatan stok menipis di dashboard. |
| [StockAlertBadge](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/stock_alert_badge.dart) | [stock_alert_badge.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/stock_alert_badge.dart) | Badge notifikasi stok di navbar. |
| [SyncStatusIndicator](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/sync_status_indicator.dart) | [sync_status_indicator.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/sync_status_indicator.dart) | Overlay status online/offline/syncing. |
| [SettingsModal](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/settings_modal.dart) | [settings_modal.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/settings_modal.dart) | Bottom sheet opsi pengaturan. |
| [SalesChartWidget](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/sales_chart_widget.dart) | [sales_chart_widget.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/sales_chart_widget.dart) | Grafik batang penjualan harian. |
| [ProfileTextField](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/profile_text_field.dart) | [profile_text_field.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/profile_text_field.dart) | Text field bergaya utk form profil. |
| [ProfileImagePicker](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/profile_image_picker.dart) | [profile_image_picker.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/profile_image_picker.dart) | Pemilih avatar utk profil. |
| [AvatarPickerWidget](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/avatar_picker_widget.dart) | [avatar_picker_widget.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/avatar_picker_widget.dart) | Pemilih avatar reusable: kamera/galeri. |
| [ImageSourcePicker](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/image_source_picker.dart) | [image_source_picker.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/image_source_picker.dart) | Bottom sheet pilih sumber gambar. |
| [FullScreenImageViewer](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/full_screen_image_viewer.dart) | [full_screen_image_viewer.dart](file:///c:/Milan/GIT/BradPOS/lib/presentation/widgets/full_screen_image_viewer.dart) | Viewer gambar fullscreen dengan pinch-to-zoom. |

---

## 7. Sistem Autentikasi

BradPOS mendukung **tiga mode autentikasi**:

### 7.1 Owner (Supabase Auth)

- **Metode login:** Email/password, Google OAuth
- **Persistensi session:** SharedPreferences (`owner_session`) + SDK Supabase
- **Google OAuth:** Web pakai redirect Supabase OAuth; mobile pakai plugin `google_sign_in`
- **Profil:** Gabung dari tabel `profiles` Supabase (diutamakan di atas metadata OAuth)

### 7.2 Karyawan (Database Kustom)

- **Login:** Pakai `shop_id` (dari tabel `profiles`) + `full_name` + `password_hash` (SHA-256)
- **RPC:** `verify_karyawan_login_v2` — verifikasi kredensial via RPC Supabase (fungsi PostgreSQL)
- **Pembuatan:** RPC `create_karyawan_v2` — buat karyawan di bawah owner saat ini
- **Session:** SharedPreferences (`karyawan_session`)
- **Nama tampilan:** Dari kolom `full_name` tabel `karyawan`

### 7.3 Guest (Mode Offline)

- **ID:** `offline_guest` (tetap)
- **Penyimpanan:** Semua data disimpan lokal dengan `owner_id = 'offline_guest'`
- **Migrasi:** Saat login, `migrateOfflineData()` pindahkan semua record offline ke UUID user baru

---

## 8. Sistem Sinkronisasi (Offline-First)

### Arsitektur

```
┌─────────────────┐     ┌──────────────────┐
│   UI (BLoC)     │◄────│  SyncService      │
└────────┬────────┘     │  (Orkestrator)    │
         │              └───┬───┬───┬───┬───┘
         ▼                  │   │   │   │
┌─────────────────┐        ▼   ▼   ▼   ▼
│  SQLite Lokal    │    ┌──────────────────────┐
│  (Source of      │    │  Sync Managers       │
│   Truth)         │    │  Product/Category/   │
└────────┬────────┘    │  Transaction/Profile │
         │             │  /Karyawan           │
         ▼             └──────────┬───────────┘
┌─────────────────┐              │
│  Supabase       │◄─────────────┘
│  (Cloud)        │
└─────────────────┘
```

### Alur Sync (`SyncService.syncAll()`)

1. **Sync Profil** — `ProfileSyncManager.sync()` update profil lokal dari cloud
2. **Pull Karyawan** — `KaryawanSyncManager.pull()` ambil daftar staf
3. **Fase Push** — Upload perubahan lokal ke cloud:
   - `CategorySyncManager.push()` → kategori pending sync
   - `ProductSyncManager.push()` → produk pending sync (dengan upload gambar)
   - `TransactionSyncManager.push()` → transaksi pending sync
4. **Fase Pull** — Download perubahan remote (inkremental via `updated_at`):
   - `ProductSyncManager.pull()` → produk baru/berubah
   - `TransactionSyncManager.pull()` → transaksi baru
   - `CategorySyncManager.pull()` → kategori baru/berubah

### Pemicu Sync

- **Saat Aplikasi Dibuka:** SplashPage panggil `syncAll()` sebelum ke Dashboard
- **Saat Perubahan Inventory:** Setelah tambah/update/hapus produk
- **Saat Transaksi:** Setelah pembayaran sukses
- **Saat Update Profil:** Setelah perubahan profil
- **Sync Manual:** Tombol sync di BradHeader

---

## 9. Skema Database

### 9.1 Lokal SQLite

Semua tabel punya `sync_status TEXT DEFAULT 'synced'` dan `updated_at TEXT`.

**`produk`** — Produk/Inventaris
```
id TEXT PK | owner_id TEXT | category_id TEXT | name TEXT | category TEXT
| purchase_price REAL | selling_price REAL | stock INTEGER | unit TEXT
| barcode TEXT | image_url TEXT | is_active INTEGER | created_at TEXT
| sync_status TEXT | updated_at TEXT
```

**`categories`** — Kategori Produk
```
id TEXT PK | owner_id TEXT | name TEXT | description TEXT | created_at TEXT
| sync_status TEXT | updated_at TEXT
```

**`transactions`** — Header Transaksi (items disimpan sebagai JSON string)
```
id TEXT PK | owner_id TEXT | karyawan_id TEXT | cashier_name TEXT
| transaction_number TEXT | customer_name TEXT | customer_phone TEXT
| shop_name TEXT | subtotal REAL | discount REAL | tax REAL | total REAL
| payment_method TEXT | payment_amount REAL | change_amount REAL
| notes TEXT | status TEXT | items TEXT (JSON) | created_at TEXT
| sync_status TEXT | updated_at TEXT
```

**`karyawan`** — Staf
```
id TEXT PK | owner_id TEXT | full_name TEXT | password_hash TEXT
| is_active INTEGER | remote_image TEXT | local_image TEXT | created_at TEXT
| sync_status TEXT | updated_at TEXT
```

**`profiles`** — Profil Pengguna/Toko
```
id TEXT PK | shop_id TEXT | shop_name TEXT | full_name TEXT
| remote_image TEXT | local_image TEXT | updated_at TEXT
```

### 9.2 Remote Supabase (PostgreSQL)

[Skema lengkap](file:///c:/Milan/GIT/BradPOS/supabase_schema.sql) meliputi:

**Tabel:** `profiles`, `categories`, `produk`, `karyawan`, `transactions`

**Fitur utama:**
- UUID primary key dengan `gen_random_uuid()`
- Row Level Security (RLS) di semua tabel
- Storage bucket: `produk_images` dan `profile_images`
- Fungsi RPC: `verify_karyawan_login_v2`, `create_karyawan_v2`
- Trigger auth: `on_auth_user_created` auto-buat profil saat signup
- Index trigram di `produk.name` untuk pencarian fuzzy

---

## 10. Alur Kasir & Pembayaran

```
User pilih produk → AddToCart (CashierBloc)
  → Keranjang tampil di CashierScreen
  → User tap "Bayar" → PaymentScreen
    → Ringkasan pesanan, nama pelanggan, pilih metode bayar
    → Tunai: input nominal → hitung kembalian
    → QRIS: auto-fill nominal = total
    → ProcessPayment (CashierBloc)
      → TransactionRepository.createTransaction()
        → TransactionLocalDataSource.createTransaction() 
          → Simpan ke SQLite → Potong stok → Generate nomor transaksi
        → Emit isSuccess = true
        → SyncService.syncAll() (background push ke Supabase)
      → Tampilkan ReceiptDialog
```

### Format Nomor Transaksi
`${2-karakter prefix toko}-${tahun}-${bulan}-${hari}-${4-karakter random}`  
Contoh: `BR-2026-6-8-A3F2`

---

## 11. Konfigurasi & Environment

### 11.1 Dependency Injection ([injection_container.dart](file:///c:/Milan/GIT/BradPOS/lib/injection_container.dart))

Pakai **GetIt** (`sl` = Service Locator). Urutan registrasi:
1. Bloc (Factory)
2. Repository (LazySingleton)
3. Data Source (LazySingleton)
4. Service / Sync Manager (LazySingleton)
5. Eksternal: Supabase, DatabaseHelper, SharedPreferences

### 11.2 Environment Variables

Dimuat via `flutter_dotenv` dari file `.env`:

| Variable | Wajib | Deskripsi |
|----------|-------|-----------|
| `SUPABASE_URL` | Ya | URL proyek Supabase |
| `SUPABASE_ANON_KEY` | Ya | Anon key Supabase |
| `GOOGLE_WEB_CLIENT_ID` | Kondisional | Client ID Google OAuth |

### 11.3 Dependensi (Paket Utama)

| Paket | Fungsi |
|-------|--------|
| `flutter_bloc` | State management |
| `supabase_flutter` | Backend database & auth |
| `sqflite` | Database lokal (mobile/desktop) |
| `sqflite_common_ffi_web` | Database lokal (web) |
| `get_it` | Service locator DI |
| `dartz` | Functional error handling (Either) |
| `equatable` | Value equality |
| `shared_preferences` | Penyimpanan key-value sederhana |
| `google_sign_in` | Google OAuth (mobile) |
| `image_picker` | Pilih gambar dari kamera/galeri |
| `cached_network_image` | Cache gambar |
| `path_provider` | Path filesystem |
| `flutter_pos_printer_platform_image_3` | Dukungan printer thermal |
| `esc_pos_utils_plus` | Protokol ESC/POS utk cetak |
| `uuid` | UUID v4 generation |
| `crypto` | Hash password SHA-256 |
| `smooth_transition` | Animasi transisi halaman |
| `intl` | Format tanggal (locale Indonesia) |
| `sembast` / `sembast_web` | Database Web fallback |

### 11.4 Tema Aplikasi

- **Warna Primer:** `#065F46` (Deep Emerald)
- **Font:** Inter (Google Font)
- **Material 3:** Aktif
- **Transisi Halaman:** Zoom (Android), Cupertino (iOS)

---

## 12. Testing

| File | Deskripsi |
|------|-----------|
| [widget_test.dart](file:///c:/Milan/GIT/BradPOS/test/widget_test.dart) | Smoke test widget dasar |

> Catatan: Test yang lebih komprehensif diharapkan menyusul. Coverage test saat ini masih minim.

---

## Lampiran: Alur Status Sync

```
                        ┌─────────────┐
                        │  Aksi User  │
                        └──────┬──────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Simpan ke DB Lokal  │
                    │  sync_status='created'│
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Emit State UI Baru │
                    │  (respon instan)    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Trigger SyncService │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Push ke Supabase   │
                    │  Jika sukses:       │
                    │  sync_status='synced'│
                    └─────────────────────┘
```

---

*Dokumentasi dibuat pada 2026-06-08. Untuk pertanyaan, lihat file sumber terkait yang ditautkan di atas.*
