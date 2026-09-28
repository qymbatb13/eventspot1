import 'package:equatable/equatable.dart';

/// Base class for all recoverable errors that cross the domain boundary.
///
/// Data-layer exceptions are caught in repositories and mapped to a
/// [Failure] so that the presentation layer never has to know about Dio,
/// platform channels, or any other implementation detail.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет подключения к интернету']);
}

class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Не удалось прочитать локальные данные']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Что-то пошло не так']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
