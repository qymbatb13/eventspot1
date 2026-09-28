import 'package:eventspot/core/error/exceptions.dart';
import 'package:eventspot/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late AuthLocalDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = AuthLocalDataSourceImpl(prefs);
  });

  Future<void> register() => dataSource.signUp(
        name: 'Аня',
        email: 'Anya@Mail.com',
        password: 'secret123',
      );

  test('signUp creates a session and normalizes the email', () async {
    final user = await dataSource.signUp(
      name: 'Аня',
      email: ' Anya@Mail.com ',
      password: 'secret123',
    );

    expect(user.email, 'anya@mail.com');
    expect((await dataSource.getCurrentUser())?.id, user.id);
  });

  test('signUp rejects a duplicate email (case-insensitive)', () async {
    await register();

    expect(
      () => dataSource.signUp(
        name: 'Другая',
        email: 'anya@mail.com',
        password: 'another123',
      ),
      throwsA(isA<AuthException>()),
    );
  });

  test('signIn succeeds with the right password', () async {
    await register();
    await dataSource.signOut();

    final user = await dataSource.signIn(
      email: 'anya@mail.com',
      password: 'secret123',
    );

    expect(user.name, 'Аня');
  });

  test('signIn fails with a wrong password or unknown email', () async {
    await register();

    expect(
      () => dataSource.signIn(email: 'anya@mail.com', password: 'wrong'),
      throwsA(isA<AuthException>()),
    );
    expect(
      () => dataSource.signIn(email: 'nobody@mail.com', password: 'secret123'),
      throwsA(isA<AuthException>()),
    );
  });

  test('the session survives an app restart', () async {
    await register();

    final restarted = AuthLocalDataSourceImpl(prefs);

    expect((await restarted.getCurrentUser())?.email, 'anya@mail.com');
  });

  test('signOut clears the session', () async {
    await register();
    await dataSource.signOut();

    expect(await dataSource.getCurrentUser(), isNull);
  });

  test('the password is never stored in plain text', () async {
    await register();

    expect(prefs.getString('auth_users'), isNot(contains('secret123')));
  });
}
