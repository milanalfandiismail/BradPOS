import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  // Owner auth (Supabase Auth)
  Future<Either<String, UserEntity>> signIn(String email, String password);
  Future<Either<String, UserEntity>> signUp(String email, String password, String fullName);
  Future<Either<String, UserEntity>> signInWithGoogle();
  Future<Either<String, void>> signOut();
  Future<Either<String, UserEntity?>> getCurrentUser();

  // Karyawan auth (Custom database)
  Future<Either<String, UserEntity>> signInAsKaryawan(String email, String password);
  Future<Either<String, String>> createKaryawan(String fullName, String email, String password);
}
