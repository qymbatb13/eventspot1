import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/events/presentation/bloc/events_bloc.dart';
import '../../features/events/presentation/pages/events_map_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'eventsMap',
      builder: (context, state) => BlocProvider<EventsBloc>(
        create: (_) => getIt<EventsBloc>(),
        child: const EventsMapPage(),
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    // Roadmap: '/favorites' (offline cache) and '/event/:id' deep-link.
  ],
);
