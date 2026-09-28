import 'package:fpdart/fpdart.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.localDataSource});

  final AuthLocalDataSource localDataSource;

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _guard(
      () => localDataSource.signUp(name: name, email: email, password: password),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) {
    return _guard(() => localDataSource.signIn(email: email, password: password));
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() {
    return _guard(localDataSource.getCurrentUser);
  }

  @override
  Future<Either<Failure, Unit>> signOut() {
    return _guard(() async {
      await localDataSource.signOut();
      return unit;
    });
  }

  /// The only place where data-layer exceptions become Failures.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (_) {
      return const Left(CacheFailure());
    }
  }
}
