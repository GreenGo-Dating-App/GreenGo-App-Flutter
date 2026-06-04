import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail implements UseCase<User, SignInWithEmailParams> {

  SignInWithEmail(this.repository);
  final AuthRepository repository;

  @override
  Future<Either<Failure, User>> call(SignInWithEmailParams params) async {
    return repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInWithEmailParams {

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });
  final String email;
  final String password;
}
