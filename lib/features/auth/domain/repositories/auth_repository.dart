import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// `Right(null)` means "no session" — that is not an error.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Future<Either<Failure, Unit>> signOut();
}
