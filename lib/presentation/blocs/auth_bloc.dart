import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth;
import 'package:bradpos/domain/entities/user_entity.dart';
import 'package:bradpos/domain/repositories/auth_repository.dart';
import 'package:bradpos/core/sync/sync_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc utama untuk mengelola alur Autentikasi seluruh aplikasi.
/// Menangani login Owner, login Karyawan, login Google, registrasi, dan logout.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final SyncService syncService;
  StreamSubscription<supabase_auth.AuthState>? _authSubscription;

  AuthBloc({required this.authRepository, required this.syncService}) : super(AuthInitial()) {
    // Listen to Supabase Auth Changes globally (Owner only)
    _authSubscription = supabase_auth
        .Supabase
        .instance
        .client
        .auth
        .onAuthStateChange
        .listen((data) {
          final event = data.event;
          final session = data.session;
          final user = session?.user;

          if (user != null) {
            // Trigger check auth status to get the latest profile from repository
            add(CheckAuthStatus());
          } else if (event == supabase_auth.AuthChangeEvent.signedOut) {
            add(AuthStatusChanged(null));
          }
        });

    on<AuthStatusChanged>((event, emit) {
      if (event.user != null) {
        emit(AuthAuthenticated(event.user!));
      } else if (state is AuthAuthenticated &&
          (state as AuthAuthenticated).user.isOwner) {
        // Only log out if the current user was an Owner
        emit(AuthUnauthenticated());
      }
    });

    on<CheckAuthStatus>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.getCurrentUser();
      result.fold(
        (failure) {
          emit(AuthUnauthenticated());
        },
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
      final result = await authRepository.signIn(event.email, event.password);
      result.fold(
        (failure) => emit(AuthError(failure)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.signUp(
        event.email,
        event.password,
        event.fullName,
      );
      result.fold(
        (failure) => emit(AuthError(failure)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<GoogleSignInRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.signInWithGoogle();
      result.fold((failure) {
        if (!failure.contains('Membuka') && !failure.contains('halaman')) {
          emit(AuthError(failure));
        }
      }, (user) => emit(AuthAuthenticated(user)));
    });

    on<ContinueAsGuestRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.signInAsGuest();
      result.fold(
        (failure) => emit(AuthError(failure)),
        (user) => emit(AuthAuthenticated(user)),
      );
    });

    on<SignInAsKaryawanRequested>((event, emit) async {
      emit(AuthLoading());
      final result = await authRepository.signInAsKaryawan(
        event.shopId,
        event.name,
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

    on<UpdateProfileEvent>((event, emit) async {
      final current = state;
      if (current is AuthAuthenticated) {
        // Optimistic UI update
        final updatedUser = UserEntity(
          id: current.user.id,
          email: current.user.email,
          name: (event.fullName != null && event.fullName!.isNotEmpty)
              ? event.fullName
              : current.user.name,
          shopName: (event.shopName != null && event.shopName!.isNotEmpty)
              ? event.shopName
              : current.user.shopName,
          shopId: (event.shopId != null && event.shopId!.isNotEmpty)
              ? event.shopId
              : current.user.shopId,
          role: current.user.role,
          ownerId: current.user.ownerId,
          remoteImage: current.user.remoteImage, // Will be updated by repository result
          localImage: event.localImage ?? current.user.localImage,
          address: (event.address != null && event.address!.isNotEmpty)
              ? event.address
              : current.user.address,
          phone: (event.phone != null && event.phone!.isNotEmpty)
              ? event.phone
              : current.user.phone,
        );
        emit(AuthAuthenticated(updatedUser));

        final result = await authRepository.updateProfile(
          fullName: event.fullName,
          shopName: event.shopName,
          shopId: event.shopId,
          remoteImage: event.remoteImage,
          localImage: event.localImage,
          address: event.address,
          phone: event.phone,
        );
        result.fold(
          (failure) {
            // Keep optimistic update or show error
          },
          (finalUser) {
            emit(AuthAuthenticated(finalUser));
            syncService.syncAll(user: finalUser); // Instant Sync dengan data terbaru
          },
        );
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
