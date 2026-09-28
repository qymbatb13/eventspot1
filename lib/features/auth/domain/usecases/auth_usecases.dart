import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../validators/auth_validators.dart';

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class SignUp implements UseCase<UserEntity, SignUpParams> {
  SignUp(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    final error = AuthValidators.name(params.name) ??
        AuthValidators.email(params.email) ??
        AuthValidators.password(params.password);
    if (error != null) return Left(AuthFailure(error));

    return _repository.signUp(
      name: params.name.trim(),
      email: params.email.trim(),
      password: params.password,
    );
  }
}

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignIn implements UseCase<UserEntity, SignInParams> {
  SignIn(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    final error = AuthValidators.email(params.email) ??
        (params.password.isEmpty ? 'Введите пароль' : null);
    if (error != null) return Left(AuthFailure(error));

    return _repository.signIn(
      email: params.email.trim(),
      password: params.password,
    );
  }
}

class SignOut implements UseCase<Unit, NoParams> {
  SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.signOut();
}

class GetCurrentUser implements UseCase<UserEntity?, NoParams> {
  GetCurrentUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) =>
      _repository.getCurrentUser();
}
