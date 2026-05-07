import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data Layer
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_remote_data_source.dart';
import 'package:bradpos/data/data_sources/category_local_data_source.dart';
import 'package:bradpos/data/data_sources/category_remote_data_source.dart';
import 'package:bradpos/data/data_sources/profile_local_data_source.dart';
import 'package:bradpos/data/data_sources/profile_remote_data_source.dart';
import 'package:bradpos/data/repositories/auth_repository_impl.dart';
import 'package:bradpos/data/repositories/dashboard_repository_impl.dart';
import 'package:bradpos/data/repositories/inventory_repository_impl.dart';
import 'package:bradpos/data/repositories/category_repository_impl.dart';
import 'package:bradpos/data/repositories/karyawan_repository_impl.dart';
import 'package:bradpos/data/repositories/transaction_repository_impl.dart';
import 'package:bradpos/data/data_sources/transaction_local_data_source.dart';
import 'package:bradpos/data/data_sources/transaction_remote_data_source.dart';

// Domain Layer
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/domain/repositories/dashboard_repository.dart';
import 'package:bradpos/domain/repositories/inventory_repository.dart';
import 'package:bradpos/domain/repositories/category_repository.dart';
import 'package:bradpos/domain/repositories/karyawan_repository.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';

// Presentation Layer
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/dashboard_bloc.dart';
import 'package:bradpos/presentation/blocs/dashboard_state.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/category_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/blocs/history/history_bloc.dart';
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_bloc.dart';

import 'package:bradpos/core/database/database_helper.dart';
import 'package:bradpos/core/sync/sync_service.dart';
import 'package:bradpos/core/sync/category_sync_manager.dart';
import 'package:bradpos/core/sync/product_sync_manager.dart';
import 'package:bradpos/core/sync/transaction_sync_manager.dart';
import 'package:bradpos/core/sync/profile_sync_manager.dart';
import 'package:bradpos/core/services/stock_alert_service.dart';

/// Service Locator global menggunakan GetIt.
final sl = GetIt.instance;

/// Inisialisasi seluruh dependensi aplikasi (3-Layered Architecture).
Future<void> init() async {
  // Blocs
  sl.registerFactory(() => AuthBloc(authRepository: sl(), syncService: sl()));
  sl.registerFactory(() => DashboardBloc(
    repository: sl(),
    stockAlertService: sl(),
    authRepository: sl(),
  )..add(LoadDashboardStats()));
  sl.registerFactory(() => KaryawanBloc(repository: sl()));
  sl.registerFactory(() => InventoryBloc(
    repository: sl(),
    categoryRepository: sl(),
    syncService: sl(),
  ));
  sl.registerLazySingleton(() => CategoryBloc(repository: sl(), syncService: sl()));
  sl.registerFactory(() => CashierBloc(repository: sl(), syncService: sl()));
  sl.registerFactory(() => HistoryBloc(repository: sl(), syncService: sl()));
  sl.registerFactory(() => TransactionDetailBloc(repository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      supabase: sl(),
      prefs: sl(),
      profileLocalDataSource: sl(),
      profileRemoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(transactionRepository: sl()),
  );
  sl.registerLazySingleton<KaryawanRepository>(
    () => KaryawanRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      supabase: sl(),
      localDataSource: sl(),
      remoteDataSource: sl(),
      categoryLocalDataSource: sl(),
      authRepository: sl(),
      syncService: sl(),
    ),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      inventoryLocalDataSource: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      supabase: sl(),
      localDataSource: sl(),
      remoteDataSource: sl(),
      authRepository: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<InventoryLocalDataSource>(
    () => InventoryLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(supabase: sl()),
  );
  sl.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<CategoryRemoteDataSource>(
    () => CategoryRemoteDataSourceImpl(supabase: sl()),
  );
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(supabase: sl()),
  );

  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(supabase: sl()),
  );

  // Services
  sl.registerLazySingleton(() => StockAlertService(
    inventoryLocalDataSource: sl(),
  ));

  // Sync Managers
  sl.registerLazySingleton<CategorySyncManager>(
    () => CategorySyncManager(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<ProductSyncManager>(
    () => ProductSyncManager(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<TransactionSyncManager>(
    () => TransactionSyncManager(
      localDataSource: sl(),
      transactionRemoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<ProfileSyncManager>(
    () => ProfileSyncManager(
      localDataSource: sl(),
      remoteDataSource: sl(),
      prefs: sl(),
    ),
  );

  // Sync Service
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      authRepository: sl(),
      categorySync: sl(),
      productSync: sl(),
      transactionSync: sl(),
      profileSync: sl(),
    ),
  );

  // External
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  // Initialize Google Sign In v7.x
  await GoogleSignIn.instance.initialize(
    serverClientId: dotenv.get('GOOGLE_WEB_CLIENT_ID'),
  );

  sl.registerLazySingleton(() => Supabase.instance.client);
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
