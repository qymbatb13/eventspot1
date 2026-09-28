/// Thrown by data sources when a remote call fails for a reason that
/// should surface as [ServerFailure] in the domain layer.
class ServerException implements Exception {
  ServerException(this.message);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

/// Thrown when the device has no usable network connection.
class NetworkException implements Exception {
  NetworkException([this.message = 'Нет подключения к интернету']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when location services / permissions prevent resolving a position.
class LocationException implements Exception {
  LocationException(this.message);

  final String message;

  @override
  String toString() => 'LocationException: $message';
}

/// Thrown by the auth data source for expected, user-facing problems
/// (duplicate email, wrong password).
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
