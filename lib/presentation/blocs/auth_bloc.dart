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
            // Merge dengan state existing biar field profile (remoteImage dll) gak ilang
            final currentState = state;
            String? existingRemoteImage;
            String? existingLocalImage;
            String? existingAddress;
            String? existingPhone;
            if (currentState is AuthAuthenticated) {
              existingRemoteImage = currentState.user.remoteImage;
              existingLocalImage = currentState.user.localImage;
              existingAddress = currentState.user.address;
              existingPhone = currentState.user.phone;
            }

            add(
              AuthStatusChanged(
                UserEntity(
                  id: user.id,
                  email: user.email ?? '',
                  name:
                      user.userMetadata?['full_name'] ??
                      user.userMetadata?['name'],
                  shopName: user.userMetadata?['shop_name'],
                  role: 'owner',
                  remoteImage: existingRemoteImage,
                  localImage: existingLocalImage,
                  address: existingAddress,
                  phone: existingPhone,
                ),
              ),
            );
          } else if (event == supabase_auth.AuthChangeEvent.signedOut) {
            // Only trigger if it was an explicit sign out from Supabase (Owner)
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

    on<UpdateProfileEvent>((event, emit) async {
      final current = state;
      if (current is AuthAuthenticated) {
        // Optimistic UI update
        final updatedUser = UserEntity(
          id: current.user.id,
          email: current.user.email,
          name: current.user.name,
          shopName: event.shopName ?? current.user.shopName,
          role: current.user.role,
          ownerId: current.user.ownerId,
          remoteImage: event.remoteImage ?? current.user.remoteImage,
          localImage: event.localImage ?? current.user.localImage,
        );
        emit(AuthAuthenticated(updatedUser));

        final result = await authRepository.updateProfile(
          shopName: event.shopName,
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
            syncService.syncAll(); // Instant Sync
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
