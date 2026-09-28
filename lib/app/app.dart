import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/di/service_locator.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class EventSpotApp extends StatelessWidget {
  const EventSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc lives above the router, so it is available on every screen.
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>()..add(const AuthStarted()),
      child: MaterialApp.router(
        title: 'EventSpot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: appRouter,
      ),
    );
  }
}
