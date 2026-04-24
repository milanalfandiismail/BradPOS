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
    // Listen to Supabase Auth Changes globally (Owner only)
    _authSubscription = supabase_auth.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      final user = session?.user;

      if (user != null) {
        add(AuthStatusChanged(UserEntity(
          id: user.id,
          email: user.email ?? '',
          name: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
          role: 'owner',
        )));
      } else if (event == supabase_auth.AuthChangeEvent.signedOut) {
        // Only trigger if it was an explicit sign out from Supabase (Owner)
        add(AuthStatusChanged(null));
      }
    });

    on<AuthStatusChanged>((event, emit) {
      if (event.user != null) {
        emit(AuthAuthenticated(event.user!));
      } else if (state is AuthAuthenticated && (state as AuthAuthenticated).user.isOwner) {
        // Only log out if the current user was an Owner
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
          if (!failure.contains('Membuka') && !failure.contains('halaman')) {
            emit(AuthError(failure));
          }
        },
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<SignInAsKaryawanRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.signInAsKaryawan(
        event.email,
        event.password,
      );
      result.fold(
        (failure) => emit(AuthError(failure)),
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
