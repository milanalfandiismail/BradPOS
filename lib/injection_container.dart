import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

import 'features/karyawan/data/repositories/karyawan_repository_impl.dart';
import 'features/karyawan/domain/repositories/karyawan_repository.dart';
import 'features/karyawan/domain/usecases/karyawan_usecases.dart';
import 'features/karyawan/presentation/bloc/karyawan_bloc.dart';

import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/inventory/data/repositories/inventory_repository_impl.dart';
import 'features/inventory/domain/repositories/inventory_repository.dart';
import 'features/inventory/domain/usecases/inventory_usecases.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';

import 'core/database/database_helper.dart';
import 'core/sync/sync_service.dart';
import 'features/inventory/data/data_sources/local/inventory_local_data_source.dart';
import 'features/inventory/data/data_sources/remote/inventory_remote_data_source.dart';

/// Service Locator global menggunakan GetIt.
/// Seluruh dependensi (Bloc, UseCase, Repository, External) didaftarkan di sini.
final sl = GetIt.instance;

/// Inisialisasi seluruh dependensi aplikasi.
/// Dipanggil sekali di main() sebelum runApp().
Future<void> init() async {
  // Features - Auth
  sl.registerFactory(
    () => AuthBloc(
      signInUseCase: sl(),
      signUpUseCase: sl(),
      authRepository: sl(),
    ),
  );
  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(supabase: sl(), prefs: sl()),
  );

  // Features - Dashboard
  sl.registerFactory(() => DashboardBloc(
        getDashboardStats: sl(),
      ));
  sl.registerLazySingleton(() => GetDashboardStats(sl()));
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(),
  );

  // Features - Karyawans
  sl.registerFactory(
    () => KaryawanBloc(
      getKaryawans: sl(),
      addKaryawan: sl(),
      updateKaryawan: sl(),
      deleteKaryawan: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetKaryawans(sl()));
  sl.registerLazySingleton(() => AddKaryawan(sl()));
  sl.registerLazySingleton(() => UpdateKaryawan(sl()));
  sl.registerLazySingleton(() => DeleteKaryawan(sl()));
  sl.registerLazySingleton<KaryawanRepository>(
    () => KaryawanRepositoryImpl(sl(), sl()),
  );

  // Features - Inventory
  sl.registerFactory(
    () => InventoryBloc(
      getInventory: sl(),
      getInventoryCount: sl(),
      addInventoryItem: sl(),
      updateInventoryItem: sl(),
      deleteInventoryItem: sl(),
      getCategories: sl(),
      syncService: sl(),
      syncOfflineData: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetInventory(sl()));
  sl.registerLazySingleton(() => GetInventoryCount(sl()));
  sl.registerLazySingleton(() => AddInventoryItem(sl()));
  sl.registerLazySingleton(() => UpdateInventoryItem(sl()));
  sl.registerLazySingleton(() => DeleteInventoryItem(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => SyncOfflineData(sl()));
  sl.registerLazySingleton(() => HasOfflineData(sl()));

  // Data Sources
  sl.registerLazySingleton<InventoryLocalDataSource>(
    () => InventoryLocalDataSourceImpl(dbHelper: sl()),
  );
  sl.registerLazySingleton<InventoryRemoteDataSource>(
    () => InventoryRemoteDataSourceImpl(supabase: sl()),
  );

  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(
      supabase: sl(),
      localDataSource: sl(),
      remoteDataSource: sl(),
      authRepository: sl(),
    ),
  );

  // Sync Service
  sl.registerLazySingleton<SyncService>(
    () => SyncService(
      supabase: sl(),
      localDataSource: sl(),
      remoteDataSource: sl(),
      authRepository: sl(),
    ),
  );

  // External
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  // Initialize Google Sign In v7.x (singleton pattern, bukan constructor)
  debugPrint("DI: Initializing GoogleSignIn v7...");
  await GoogleSignIn.instance.initialize(
    serverClientId: dotenv.get('GOOGLE_WEB_CLIENT_ID'),
  );
  debugPrint("DI: GoogleSignIn initialized successfully");

  sl.registerLazySingleton(() => Supabase.instance.client);

  // Database
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
