import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth;
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final AuthRepository authRepository;
  StreamSubscription<supabase_auth.AuthState>? _authSubscription;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    // Listen to Supabase Auth Changes globally
    _authSubscription = supabase_auth.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;
      if (user != null) {
        add(AuthStatusChanged(UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
        )));
      } else {
        add(AuthStatusChanged(null));
      }
    });

    on<AuthStatusChanged>((event, emit) {
      if (event.user != null) {
        emit(AuthAuthenticated(event.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<CheckAuthStatus>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.getCurrentUser();
      result.fold(
        (failure) => emit(AuthUnauthenticated()),
        (user) {
          if (user != null) {
            emit(AuthAuthenticated(user));
          } else {
            emit(AuthUnauthenticated());
          }
        },
      );
    });

    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signInUseCase(event.email, event.password);
      result.fold(
        (failure) => emit(AuthError(failure)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await signUpUseCase(event.email, event.password, event.fullName);
      result.fold(
        (failure) => emit(AuthError(failure)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<GoogleSignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.signInWithGoogle();
      result.fold(
        (failure) {
          // Hanya pancarkan error jika bukan pesan loading/redirect
          if (!failure.contains('Membuka') && !failure.contains('halaman')) {
            emit(AuthError(failure));
          }
        },
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
