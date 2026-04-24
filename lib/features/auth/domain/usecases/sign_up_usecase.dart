import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<String, UserEntity>> call(String email, String password, String fullName) async {
    return await repository.signUp(email, password, fullName);
  }
}
