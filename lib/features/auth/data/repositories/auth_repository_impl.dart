import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabase;

  AuthRepositoryImpl({required this.supabase});

  @override
  Future<Either<String, UserEntity>> signIn(
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
          ),
        );
      }
      return const Left('Terjadi kesalahan yang tidak diketahui');
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      final user = response.user;
      if (user != null) {
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
          ),
        );
      }
      return const Left('Terjadi kesalahan saat registrasi');
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow (v7.x API)
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 2. Get authentication details (idToken)
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return const Left('Gagal mendapatkan ID Token dari Google');
      }

      // 3. Exchange ID Token with Supabase
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      final user = response.user;
      if (user != null) {
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
          ),
        );
      }

      return const Left('Gagal menyinkronkan akun dengan Supabase');
    } on AuthException catch (e) {
      return Left(e.message);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> signOut() async {
    try {
      await supabase.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        return Right(
          UserEntity(
            id: user.id,
            email: user.email ?? '',
            name: user.userMetadata?['full_name'],
          ),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
