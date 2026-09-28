import 'package:eventspot/core/error/failures.dart';
import 'package:eventspot/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventspot/features/auth/domain/usecases/auth_usecases.dart';
import 'package:eventspot/features/auth/domain/validators/auth_validators.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthValidators', () {
    test('email', () {
      expect(AuthValidators.email(''), isNotNull);
      expect(AuthValidators.email('abc'), isNotNull);
      expect(AuthValidators.email('a@b'), isNotNull);
      expect(AuthValidators.email('anya@mail.com'), isNull);
      expect(AuthValidators.email('  anya@mail.com '), isNull);
    });

    test('password requires at least 6 characters', () {
      expect(AuthValidators.password('12345'), isNotNull);
      expect(AuthValidators.password('123456'), isNull);
    });

    test('confirmPassword must match', () {
      expect(AuthValidators.confirmPassword('abc', 'abd'), isNotNull);
      expect(AuthValidators.confirmPassword('abc', 'abc'), isNull);
    });
  });

  group('SignUp use case', () {
    test('rejects invalid input without touching the repository', () async {
      final repository = MockAuthRepository();

      final result = await SignUp(repository)(
        const SignUpParams(
          name: 'Аня',
          email: 'not-an-email',
          password: 'secret123',
        ),
      );

      result.match(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('expected Left'),
      );
      verifyZeroInteractions(repository);
    });
  });
}
