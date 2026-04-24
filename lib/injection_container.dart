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

final sl = GetIt.instance;

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
  sl.registerFactory(() => DashboardBloc(getDashboardStats: sl()));
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

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
