import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/dashboard/domain/usecases/get_dashboard_stats.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';

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
    () => AuthRepositoryImpl(supabase: sl()),
  );

  // Features - Dashboard
  sl.registerFactory(() => DashboardBloc(getDashboardStats: sl()));
  sl.registerLazySingleton(() => GetDashboardStats(sl()));
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(),
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
}
