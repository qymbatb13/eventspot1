import 'package:bloc_test/bloc_test.dart';
import 'package:eventspot/core/error/failures.dart';
import 'package:eventspot/core/usecase/usecase.dart';
import 'package:eventspot/features/auth/domain/entities/user_entity.dart';
import 'package:eventspot/features/auth/domain/usecases/auth_usecases.dart';
import 'package:eventspot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}

class MockSignIn extends Mock implements SignIn {}

class MockSignUp extends Mock implements SignUp {}

class MockSignOut extends Mock implements SignOut {}

void main() {
  late MockGetCurrentUser getCurrentUser;
  late MockSignIn signIn;
  late MockSignUp signUp;
  late MockSignOut signOut;

  const tUser = UserEntity(id: '1', name: 'Аня', email: 'anya@mail.com');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const SignInParams(email: '', password: ''));
    registerFallbackValue(
      const SignUpParams(name: '', email: '', password: ''),
    );
  });

  setUp(() {
    getCurrentUser = MockGetCurrentUser();
    signIn = MockSignIn();
    signUp = MockSignUp();
    signOut = MockSignOut();
  });

  AuthBloc buildBloc() => AuthBloc(
        getCurrentUser: getCurrentUser,
        signIn: signIn,
        signUp: signUp,
        signOut: signOut,
      );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted restores a saved session',
    setUp: () {
      when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(tUser));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const Authenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthStarted without a session emits Unauthenticated',
    setUp: () {
      when(() => getCurrentUser(any())).thenAnswer((_) async => const Right(null));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const AuthStarted()),
    expect: () => [const Unauthenticated()],
  );

  blocTest<AuthBloc, AuthState>(
    'successful sign in emits [InProgress, Authenticated]',
    setUp: () {
      when(() => signIn(any())).thenAnswer((_) async => const Right(tUser));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const AuthSignInRequested(email: 'anya@mail.com', password: 'secret123'),
    ),
    expect: () => [const AuthInProgress(), const Authenticated(tUser)],
  );

  blocTest<AuthBloc, AuthState>(
    'failed sign in emits [InProgress, Unauthenticated(error)]',
    setUp: () {
      when(() => signIn(any())).thenAnswer(
        (_) async => const Left(AuthFailure('Неверный email или пароль')),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const AuthSignInRequested(email: 'anya@mail.com', password: 'wrong'),
    ),
    expect: () => [
      const AuthInProgress(),
      const Unauthenticated(error: 'Неверный email или пароль'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'sign out emits Unauthenticated',
    setUp: () {
      when(() => signOut(any())).thenAnswer((_) async => const Right(unit));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => [const Unauthenticated()],
  );
}
