import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data Layer
import 'package:bradpos/data/data_sources/inventory_local_data_source.dart';
import 'package:bradpos/data/data_sources/inventory_remote_data_source.dart';
import 'package:bradpos/data/repositories/auth_repository_impl.dart';
import 'package:bradpos/data/repositories/dashboard_repository_impl.dart';
import 'package:bradpos/data/repositories/inventory_repository_impl.dart';
import 'package:bradpos/data/repositories/karyawan_repository_impl.dart';
import 'package:bradpos/data/repositories/transaction_repository_impl.dart';
import 'package:bradpos/data/data_sources/transaction_local_data_source.dart';
import 'package:bradpos/data/data_sources/transaction_remote_data_source.dart';

// Domain Layer
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/domain/repositories/dashboard_repository.dart';
import 'package:bradpos/domain/repositories/inventory_repository.dart';
import 'package:bradpos/domain/repositories/karyawan_repository.dart';
import 'package:bradpos/domain/repositories/transaction_repository.dart';

// Presentation Layer
import 'package:bradpos/presentation/blocs/auth_bloc.dart';
import 'package:bradpos/presentation/blocs/dashboard_bloc.dart';
import 'package:bradpos/presentation/blocs/inventory_bloc.dart';
import 'package:bradpos/presentation/blocs/karyawan_bloc.dart';
import 'package:bradpos/presentation/blocs/cashier_bloc.dart';
import 'package:bradpos/presentation/blocs/history/history_bloc.dart';
import 'package:bradpos/presentation/blocs/transaction_detail/transaction_detail_bloc.dart';

import 'package:bradpos/core/database/database_helper.dart';
import 'package:bradpos/core/sync/sync_service.dart';

/// Service Locator global menggunakan GetIt.
final sl = GetIt.instance;

/// Inisialisasi seluruh dependensi aplikasi (3-Layered Architecture).
Future<void> init() async {
  // Blocs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => DashboardBloc(repository: sl()));
  sl.registerFactory(() => KaryawanBloc(repository: sl()));
  sl.registerFactory(() => InventoryBloc(
        repository: sl(),
        syncService: sl(),
      ));
  sl.registerFactory(() => CashierBloc(repository: sl()));
  sl.registerFactory(() => HistoryBloc(repository: sl()));
  sl.registerFactory(() => TransactionDetailBloc(repository: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(supabase: sl(), prefs: sl()),
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

  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSourceImpl(supabase: sl()),
  );

  // Sync Service
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      supabase: sl(),
      localDataSource: sl(),
      remoteDataSource: sl(),
      transactionLocalDataSource: sl(),
      transactionRemoteDataSource: sl(),
      authRepository: sl(),
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
