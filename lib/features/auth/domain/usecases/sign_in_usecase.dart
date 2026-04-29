import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// Use Case untuk proses Login Owner.
/// Meneruskan permintaan login ke AuthRepository.
class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<Either<String, UserEntity>> call(String email, String password) async {
    return await repository.signIn(email, password);
  }
}
