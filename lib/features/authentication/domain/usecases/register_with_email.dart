import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterWithEmail implements UseCase<User, RegisterWithEmailParams> {
  final AuthRepository repository;

  RegisterWithEmail(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterWithEmailParams params) async {
    return await repository.registerWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class RegisterWithEmailParams {
  final String email;
  final String password;

  const RegisterWithEmailParams({
    required this.email,
    required this.password,
  });
}
