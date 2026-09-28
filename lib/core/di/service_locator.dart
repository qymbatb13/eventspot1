import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/events/data/datasources/events_remote_data_source.dart';
import '../../features/events/data/datasources/mock_events_remote_data_source.dart';
import '../../features/events/data/repositories/events_repository_impl.dart';
import '../../features/events/domain/repositories/events_repository.dart';
import '../../features/events/domain/usecases/get_events.dart';
import '../../features/events/presentation/bloc/events_bloc.dart';
import '../network/api_client.dart';

final GetIt getIt = GetIt.instance;

/// Wires up every dependency by hand (no codegen).
///
/// [useMockData] swaps the Ticketmaster data source for a generated one.
/// Auth is local-only for now: replacing [AuthLocalDataSource] with a
/// remote implementation (PocketBase / Supabase) touches only this file
/// and the data layer.
Future<void> configureDependencies({
  required String ticketmasterApiKey,
  required bool useMockData,
}) async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<ApiClient>(ApiClient.new)
    // --- events
    ..registerLazySingleton<EventsRemoteDataSource>(
      () => useMockData
          ? MockEventsRemoteDataSource()
          : EventsRemoteDataSourceImpl(
              dio: getIt<ApiClient>().dio,
              apiKey: ticketmasterApiKey,
            ),
    )
    ..registerLazySingleton<EventsRepository>(
      () => EventsRepositoryImpl(remoteDataSource: getIt()),
    )
    ..registerLazySingleton<GetEvents>(() => GetEvents(getIt()))
    ..registerFactory<EventsBloc>(() => EventsBloc(getEvents: getIt()))
    // --- auth
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(localDataSource: getIt()),
    )
    ..registerLazySingleton<GetCurrentUser>(() => GetCurrentUser(getIt()))
    ..registerLazySingleton<SignIn>(() => SignIn(getIt()))
    ..registerLazySingleton<SignUp>(() => SignUp(getIt()))
    ..registerLazySingleton<SignOut>(() => SignOut(getIt()))
    ..registerFactory<AuthBloc>(
      () => AuthBloc(
        getCurrentUser: getIt(),
        signIn: getIt(),
        signUp: getIt(),
        signOut: getIt(),
      ),
    );
}
