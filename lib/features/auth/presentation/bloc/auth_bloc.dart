import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';

// ---------------------------------------------------------------- events

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Checks the saved session on app start.
final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
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

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

// ---------------------------------------------------------------- states

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The session has not been checked yet.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthInProgress extends AuthState {
  const AuthInProgress();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated({this.error});

  /// Error message from the last sign-in / sign-up attempt.
  final String? error;

  @override
  List<Object?> get props => [error];
}

// ------------------------------------------------------------------ bloc

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetCurrentUser getCurrentUser,
    required SignIn signIn,
    required SignUp signUp,
    required SignOut signOut,
  })  : _getCurrentUser = getCurrentUser,
        _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final GetCurrentUser _getCurrentUser;
  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final result = await _getCurrentUser(const NoParams());
    result.match(
      (_) => emit(const Unauthenticated()),
      (user) => emit(
        user != null ? Authenticated(user) : const Unauthenticated(),
      ),
    );
  }

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    final result = await _signIn(
      SignInParams(email: event.email, password: event.password),
    );
    result.match(
      (failure) => emit(Unauthenticated(error: failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthInProgress());
    final result = await _signUp(
      SignUpParams(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );
    result.match(
      (failure) => emit(Unauthenticated(error: failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _signOut(const NoParams());
    emit(const Unauthenticated());
  }
}
